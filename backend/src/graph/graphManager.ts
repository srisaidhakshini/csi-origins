import prisma from '../db/prisma';
import { CommonEvent, NodeConfidence } from '../ingestion/types';
import { detectAndPromoteRecurringPatterns } from './recurringDetector';

export interface CascadeStep {
  edgeId: string;
  depth: number;
  relation: string;
  weight: number;
  sourceId: string;
  sourceLabel: string;
  sourceType: string;
  sourceValue: number;
  sourceConfidence: string;
  targetId: string;
  targetLabel: string;
  targetType: string;
  targetValue: number;
  targetConfidence: string;
  targetMetadata?: any;
}

export interface CascadeEvaluationResult {
  rootNodeId: string;
  rootNodeLabel: string;
  rootNodeType: string;
  isDelayed: boolean;
  delayDays: number;
  bufferNode?: { id: string; label: string; currentBalance: number };
  cascadeSteps: CascadeStep[];
  affectedObligations: Array<{
    id: string;
    label: string;
    amount: number;
    dueDay?: number;
    shortfall: number;
  }>;
  totalRequired: number;
  availableBuffer: number;
  totalShortfall: number;
  hasDeficit: boolean;
  explanationFacts: {
    incomeLabel: string;
    expectedIncome: number;
    delayDays: number;
    bufferBalance: number;
    atRiskObligations: string[];
    projectedShortfall: number;
    criticalDueDateDescription: string;
  };
}

export class GraphManager {
  /**
   * Execute recursive CTE cascade query starting from a node in Postgres
   */
  public static async executeCascadeQuery(nodeId: string, depthLimit = 5): Promise<CascadeStep[]> {
    const rawSteps: any[] = await prisma.$queryRaw`
      WITH RECURSIVE cascade AS (
        SELECT id, source_id, target_id, relation, weight, 1 AS depth
        FROM edges WHERE source_id = ${nodeId}::uuid
        UNION ALL
        SELECT e.id, e.source_id, e.target_id, e.relation, e.weight, c.depth + 1
        FROM edges e JOIN cascade c ON e.source_id = c.target_id
        WHERE c.depth < ${depthLimit}
      )
      SELECT 
        c.id as edge_id,
        c.depth,
        c.relation,
        c.weight,
        n_src.id as source_id,
        n_src.label as source_label,
        n_src.type as source_type,
        n_src.value as source_value,
        n_src.confidence as source_confidence,
        n_tgt.id as target_id,
        n_tgt.label as target_label,
        n_tgt.type as target_type,
        n_tgt.value as target_value,
        n_tgt.confidence as target_confidence,
        n_tgt.metadata as target_metadata
      FROM cascade c
      JOIN nodes n_src ON c.source_id = n_src.id
      JOIN nodes n_tgt ON c.target_id = n_tgt.id
      ORDER BY c.depth ASC;
    `;

    return rawSteps.map(s => ({
      edgeId: s.edge_id,
      depth: Number(s.depth),
      relation: s.relation,
      weight: Number(s.weight),
      sourceId: s.source_id,
      sourceLabel: s.source_label,
      sourceType: s.source_type,
      sourceValue: Number(s.source_value) || 0,
      sourceConfidence: s.source_confidence,
      targetId: s.target_id,
      targetLabel: s.target_label,
      targetType: s.target_type,
      targetValue: Number(s.target_value) || 0,
      targetConfidence: s.target_confidence,
      targetMetadata: s.target_metadata,
    }));
  }

  /**
   * Deterministically evaluate cascade risks downstream from a delayed or modified node
   */
  public static async evaluateCascadeRisk(
    userId: string,
    nodeId: string,
    delayDays = 7
  ): Promise<CascadeEvaluationResult> {
    const rootNode = await prisma.node.findUnique({ where: { id: nodeId } });
    if (!rootNode) {
      throw new Error(`Node ${nodeId} not found`);
    }

    const cascadeSteps = await this.executeCascadeQuery(nodeId, 5);

    // Find the intermediate buffer node in the cascade path
    const bufferStep = cascadeSteps.find(s => s.targetType === 'buffer');
    let bufferBalance = 0;
    let bufferInfo: any = undefined;

    if (bufferStep) {
      const bufferNode = await prisma.node.findUnique({ where: { id: bufferStep.targetId } });
      if (bufferNode) {
        bufferBalance = Number(bufferNode.value) || 0;
        bufferInfo = {
          id: bufferNode.id,
          label: bufferNode.label,
          currentBalance: bufferBalance,
        };
      }
    } else {
      // Fallback to user's primary buffer
      const bufferNode = await prisma.node.findFirst({ where: { userId, type: 'buffer' } });
      if (bufferNode) {
        bufferBalance = Number(bufferNode.value) || 0;
        bufferInfo = {
          id: bufferNode.id,
          label: bufferNode.label,
          currentBalance: bufferBalance,
        };
      }
    }

    // Collect all downstream obligations funded by this path
    const affectedObligations: Array<{
      id: string;
      label: string;
      amount: number;
      dueDay?: number;
      shortfall: number;
    }> = [];

    let totalRequired = 0;
    let runningBalance = bufferBalance;

    for (const step of cascadeSteps) {
      if (step.targetType === 'obligation' && step.relation === 'funds') {
        const metadata = step.targetMetadata as any;
        const dueDay = metadata?.due_day || 5;
        const amount = step.targetValue;
        totalRequired += amount;

        const shortfall = Math.max(0, amount - runningBalance);
        runningBalance = Math.max(0, runningBalance - amount);

        affectedObligations.push({
          id: step.targetId,
          label: step.targetLabel,
          amount,
          dueDay,
          shortfall,
        });
      }
    }

    const totalShortfall = Math.max(0, totalRequired - bufferBalance);
    const hasDeficit = totalShortfall > 0;

    return {
      rootNodeId: rootNode.id,
      rootNodeLabel: rootNode.label,
      rootNodeType: rootNode.type,
      isDelayed: true,
      delayDays,
      bufferNode: bufferInfo,
      cascadeSteps,
      affectedObligations,
      totalRequired,
      availableBuffer: bufferBalance,
      totalShortfall,
      hasDeficit,
      explanationFacts: {
        incomeLabel: rootNode.label,
        expectedIncome: Number(rootNode.value) || 0,
        delayDays,
        bufferBalance,
        atRiskObligations: affectedObligations.filter(o => o.shortfall > 0).map(o => `${o.label} (₹${o.amount})`),
        projectedShortfall: totalShortfall,
        criticalDueDateDescription: affectedObligations.length > 0 ? `due on day ${affectedObligations[0].dueDay}` : 'due soon',
      },
    };
  }

  /**
   * Updates state nodes & edges upon confirmed transaction ingestion
   */
  public static async updateStateFromEvent(
    event: CommonEvent,
    confidence: NodeConfidence = 'confirmed'
  ): Promise<{ updatedNode?: any; recurringResults: any[] }> {
    let updatedNode: any = null;

    if (event.type === 'credit' && event.category === 'income') {
      // Find or create income node
      const existingIncome = await prisma.node.findFirst({
        where: {
          userId: event.userId,
          type: 'income_source',
          label: { contains: event.merchant, mode: 'insensitive' },
        },
      });

      if (existingIncome) {
        updatedNode = await prisma.node.update({
          where: { id: existingIncome.id },
          data: {
            value: event.amount,
            confidence,
            updatedAt: new Date(),
          },
        });
      } else {
        updatedNode = await prisma.node.create({
          data: {
            userId: event.userId,
            type: 'income_source',
            label: event.merchant,
            value: event.amount,
            confidence,
            metadata: {
              cadence: 'variable',
              payer: event.merchant,
            },
          },
        });

        // Wire edge to buffer
        const buffer = await prisma.node.findFirst({
          where: { userId: event.userId, type: 'buffer' },
        });
        if (buffer) {
          await prisma.edge.create({
            data: {
              sourceId: updatedNode.id,
              targetId: buffer.id,
              relation: 'funds',
              weight: 1.0,
            },
          });
        }
      }
    }

    // Run recurring pattern detector
    const recurringResults = await detectAndPromoteRecurringPatterns(event.userId);

    return { updatedNode, recurringResults };
  }
}

import { CommonEvent } from '../ingestion/types';
import { DedupService } from '../ingestion/dedupService';
import { GraphManager } from '../graph/graphManager';
import { AnomalyDetector } from '../intelligence/anomalyDetector';
import { InterventionGate } from '../gate/interventionGate';
import prisma from '../db/prisma';

export class PipelineCoordinator {
  /**
   * Process an incoming financial event through the entire pipeline:
   * Ingestion ➔ Deduplication ➔ Graph Update ➔ Anomaly Detection ➔ Intervention Gate ➔ Insight Logging
   */
  public static async processEvent(event: CommonEvent): Promise<{
    dedupResult: any;
    anomalyResult?: any;
    insightCreated?: any;
  }> {
    // 1. Ingestion & Deduplication
    const dedupResult = await DedupService.ingestAndDedup(event);

    let anomalyResult: any = undefined;
    let insightCreated: any = undefined;

    // 2. Anomaly Evaluation for Debit spends
    if (event.type === 'debit') {
      anomalyResult = await AnomalyDetector.scoreEvent(event);

      // Every notable spend gets scored by the Intervention Gate
      const severity = anomalyResult.anomalyScore;
      const confidence = dedupResult.finalConfidence === 'confirmed' ? 95.0 : 75.0;
      const urgency = anomalyResult.isAnomaly ? 45.0 : 20.0;

      insightCreated = await InterventionGate.evaluateAndLogCandidate({
        userId: event.userId,
        triggerType: 'anomaly',
        severity,
        confidence,
        urgency,
        graphPath: {
          merchant: event.merchant,
          amount: event.amount,
          category: event.category,
          baselineMean: anomalyResult.baselineMean,
          zScore: anomalyResult.zScore,
          deviationPercentage: anomalyResult.facts.deviationPercentage,
        },
        explanationFacts: {
          merchant: event.merchant,
          amount: event.amount,
          baselineMean: anomalyResult.baselineMean,
          zScore: anomalyResult.zScore,
          category: event.category,
          dayName: anomalyResult.dayName,
          deviationPercentage: anomalyResult.facts.deviationPercentage,
        },
      });
    }

    // 3. Update State Layer & Graph
    await GraphManager.updateStateFromEvent(event, dedupResult.finalConfidence);

    return { dedupResult, anomalyResult, insightCreated };
  }

  /**
   * Process a delayed income event and trigger cascade evaluation through the Intervention Gate
   */
  public static async processDelayedIncomeTrigger(
    userId: string,
    nodeId: string,
    delayDays = 7
  ): Promise<{ cascadeEval: any; insightCreated: any }> {
    const cascadeEval = await GraphManager.evaluateCascadeRisk(userId, nodeId, delayDays);

    // Compute severity based on shortfall deficit ratio
    let severity = 20.0;
    if (cascadeEval.hasDeficit) {
      severity = Math.min(100, Math.max(70, Math.round((cascadeEval.totalShortfall / cascadeEval.totalRequired) * 100)));
    }

    // Confidence is high for confirmed graph nodes
    const confidence = 92.0;

    // Urgency is high because rent/SIP obligations are due within days
    const urgency = 88.0;

    const insightCreated = await InterventionGate.evaluateAndLogCandidate({
      userId,
      triggerType: 'cascade',
      severity,
      confidence,
      urgency,
      graphPath: {
        rootNodeId: cascadeEval.rootNodeId,
        rootNodeLabel: cascadeEval.rootNodeLabel,
        delayDays: cascadeEval.delayDays,
        bufferBalance: cascadeEval.availableBuffer,
        totalShortfall: cascadeEval.totalShortfall,
        steps: cascadeEval.cascadeSteps.map(s => ({
          from: s.sourceLabel,
          to: s.targetLabel,
          relation: s.relation,
          weight: s.weight,
          depth: s.depth,
        })),
        affectedObligations: cascadeEval.affectedObligations,
      },
      explanationFacts: cascadeEval.explanationFacts,
    });

    return { cascadeEval, insightCreated };
  }
}

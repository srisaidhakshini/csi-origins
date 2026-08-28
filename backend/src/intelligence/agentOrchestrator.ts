import prisma from '../db/prisma';
import { CommonEvent } from '../ingestion/types';
import { AnomalyDetector } from './anomalyDetector';
import { IncomeForecaster } from './incomeForecaster';
import { prioritizeObjectives, FinancialObjective, ObjectivePrioritizationResult } from './goalPrioritizer';
import { planActions, ActionPlanningResult } from './actionPlanner';
import { detectOpportunities, OpportunityDetectionResult } from './opportunityDetector';

export interface AgentDecision {
  triggerType: 'cascade' | 'anomaly' | 'opportunity' | 'monitor';
  severity: number;
  confidence: number;
  urgency: number;
  forecast: Awaited<ReturnType<typeof IncomeForecaster.forecast>>;
  prioritization: ObjectivePrioritizationResult;
  actionPlan: ActionPlanningResult;
  opportunities: OpportunityDetectionResult;
  explanationFacts: Record<string, any>;
}

function dueInDays(dueDay: number | null, now: Date): number | undefined {
  if (!dueDay) return undefined;
  const dueDate = new Date(now.getFullYear(), now.getMonth(), dueDay);
  if (dueDate < now) dueDate.setMonth(dueDate.getMonth() + 1);
  return Math.max(0, Math.ceil((dueDate.getTime() - now.getTime()) / 86400000));
}

function objectiveKind(category: string, critical: boolean, type: string): FinancialObjective['kind'] {
  if (type === 'inflow') return 'savings_goal';
  if (category === 'investment') return 'investment';
  if (category === 'discretionary' || category === 'food_dining' || category === 'entertainment') return 'discretionary_spend';
  if (critical || category === 'housing' || category === 'utilities') return 'essential_obligation';
  return 'recurring_obligation';
}

export class AgentOrchestrator {
  public static async evaluate(event: CommonEvent, bufferBalance: number): Promise<AgentDecision> {
    const now = new Date(event.timestamp);
    const [user, forecast, anomaly, recentDebits] = await Promise.all([
      prisma.user.findUnique({ where: { id: event.userId }, include: { obligations: true } }),
      IncomeForecaster.forecast(event.userId, now),
      event.type === 'debit' ? AnomalyDetector.scoreEvent(event) : Promise.resolve(null),
      prisma.transaction.findMany({
        where: { userId: event.userId, type: 'debit', timestamp: { lte: now } },
        select: { amount: true, category: true },
        take: 100,
      }),
    ]);

    const obligations = user?.obligations || [];
    const objectives: FinancialObjective[] = obligations.map(obligation => ({
      id: obligation.id,
      label: obligation.label,
      kind: objectiveKind(obligation.category, obligation.critical, obligation.type),
      amount: Number(obligation.amount),
      dueInDays: dueInDays(obligation.dueDay, now),
      critical: obligation.critical,
    }));
    const totalEssentialFunds = objectives
      .filter(objective => objective.kind === 'essential_obligation' || objective.kind === 'recurring_obligation')
      .reduce((sum, objective) => sum + objective.amount, 0);
    const prioritization = prioritizeObjectives({
      objectives,
      availableFunds: bufferBalance,
      lowIncomeScenario: forecast.lowScenario,
      expectedIncomeScenario: forecast.expectedScenario,
      forecastConfidence: forecast.confidence,
      riskTolerance: (user?.riskTolerance || 'medium') as 'low' | 'medium' | 'high',
    });
    const discretionaryAmount = recentDebits
      .filter(transaction => ['discretionary', 'food_dining', 'entertainment'].includes(transaction.category))
      .reduce((sum, transaction) => sum + Number(transaction.amount), 0);
    const actionPlan = planActions({
      availableFunds: bufferBalance,
      forecast,
      prioritization,
      discretionaryAmount,
    });
    const opportunities = detectOpportunities({
      availableFunds: bufferBalance,
      upcomingEssentialFunds: totalEssentialFunds,
      emergencyBufferTarget: 15000,
      forecast,
      discretionarySpend: discretionaryAmount,
      goalLabel: prioritization.rankedObjectives.find(objective => objective.kind === 'savings_goal')?.label,
    });

    const shortfall = Math.max(0, totalEssentialFunds - bufferBalance);
    const hasAnomaly = Boolean(anomaly?.isAnomaly);
    const hasShortfall = shortfall > 0;
    const triggerType: AgentDecision['triggerType'] = hasShortfall
      ? 'cascade'
      : hasAnomaly
        ? 'anomaly'
        : opportunities.opportunities.length > 0
          ? 'opportunity'
          : 'monitor';
    const severity = hasShortfall
      ? Math.min(100, Math.round((shortfall / Math.max(1, totalEssentialFunds)) * 100))
      : anomaly?.anomalyScore || (opportunities.opportunities.length > 0 ? 35 : 0);
    const urgency = hasShortfall
      ? Math.min(100, Math.max(20, 100 - Math.min(80, (prioritization.rankedObjectives.find(objective => objective.fundingStatus === 'at_risk')?.dueInDays || 0) * 5)))
      : hasAnomaly ? 55 : 15;
    const confidence = hasShortfall
      ? forecast.confidence
      : hasAnomaly ? 85 : forecast.confidence;

    return {
      triggerType,
      severity,
      confidence,
      urgency,
      forecast,
      prioritization,
      actionPlan,
      opportunities,
      explanationFacts: {
        bufferBalance,
        totalRequired: totalEssentialFunds,
        projectedShortfall: shortfall,
        forecast,
        prioritization,
        opportunities,
        anomaly,
        merchant: event.merchant,
        amount: event.amount,
        category: event.category || 'general',
      },
    };
  }
}
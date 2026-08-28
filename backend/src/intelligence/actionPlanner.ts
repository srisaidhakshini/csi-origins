import { ObjectivePrioritizationResult } from './goalPrioritizer';
import { IncomeForecast } from './incomeForecaster';

export interface PlannedAction {
  id: string;
  action: string;
  expectedImpact: string;
  tradeoffs: string[];
  priority: 'high' | 'medium' | 'low';
  confidence: number;
  requiresUserApproval: true;
}

export interface ActionPlanningInput {
  availableFunds: number;
  forecast: IncomeForecast;
  prioritization: ObjectivePrioritizationResult;
  discretionaryAmount?: number;
}

export interface ActionPlanningResult {
  options: PlannedAction[];
  reasoning: string[];
}

export function planActions(input: ActionPlanningInput): ActionPlanningResult {
  const options: PlannedAction[] = [];
  const reasoning: string[] = [];
  const atRisk = input.prioritization.rankedObjectives.filter(objective => objective.fundingStatus === 'at_risk');
  const deferrable = input.prioritization.rankedObjectives.find(objective => objective.fundingStatus === 'deferred');
  const discretionaryAmount = Math.max(0, Number(input.discretionaryAmount) || 0);

  if (atRisk.length > 0 && discretionaryAmount > 0) {
    options.push({
      id: 'reduce-discretionary-spend',
      action: 'Reduce discretionary spending until the highest-priority obligation is covered.',
      expectedImpact: `Preserves up to ₹${Math.round(discretionaryAmount).toLocaleString('en-IN')} in liquid funds.`,
      tradeoffs: ['Reduces optional spending temporarily.', 'Does not create additional income.'],
      priority: 'high',
      confidence: input.forecast.confidence,
      requiresUserApproval: true,
    });
    reasoning.push('A discretionary reduction is recommended because a higher-priority objective remains at risk.');
  }

  if (deferrable) {
    options.push({
      id: `defer-${deferrable.id}`,
      action: `Review deferring ${deferrable.label} until essential obligations are funded.`,
      expectedImpact: `Could preserve up to ₹${Math.round(deferrable.amount).toLocaleString('en-IN')} for higher-priority needs.`,
      tradeoffs: ['May slow progress toward this objective.', 'Requires user confirmation and provider-specific review.'],
      priority: deferrable.kind === 'investment' ? 'medium' : 'low',
      confidence: Math.min(input.forecast.confidence, 85),
      requiresUserApproval: true,
    });
    reasoning.push(`${deferrable.label} is lower priority under the conservative allocation and may be reviewed for deferral.`);
  }

  if (options.length === 0) {
    options.push({
      id: 'monitor-cashflow',
      action: 'Monitor cash flow without taking action.',
      expectedImpact: 'Preserves current allocation while more financial data is collected.',
      tradeoffs: ['A future shortfall may require quicker action if conditions worsen.'],
      priority: 'low',
      confidence: input.forecast.confidence,
      requiresUserApproval: true,
    });
    reasoning.push('No material conflict was found, so monitoring is safer than an unnecessary intervention.');
  }

  if (input.forecast.confidence < 40) {
    reasoning.push('Forecast confidence is low; recommendations should remain advisory and conservative.');
  }

  return { options, reasoning };
}
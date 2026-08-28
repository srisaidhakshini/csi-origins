import { IncomeForecast } from './incomeForecaster';

export interface OpportunityDetectionInput {
  availableFunds: number;
  upcomingEssentialFunds: number;
  emergencyBufferTarget: number;
  forecast: IncomeForecast;
  discretionarySpend?: number;
  goalLabel?: string;
}

export interface FinancialOpportunity {
  id: string;
  opportunity: string;
  basis: string;
  suggestedNextStep: string;
  confidence: number;
}

export interface OpportunityDetectionResult {
  opportunities: FinancialOpportunity[];
  reasoning: string[];
}

export function detectOpportunities(input: OpportunityDetectionInput): OpportunityDetectionResult {
  const opportunities: FinancialOpportunity[] = [];
  const reasoning: string[] = [];
  const availableFunds = Math.max(0, Number(input.availableFunds) || 0);
  const obligations = Math.max(0, Number(input.upcomingEssentialFunds) || 0);
  const bufferTarget = Math.max(0, Number(input.emergencyBufferTarget) || 0);
  const conservativeSurplus = availableFunds + input.forecast.lowScenario - obligations - bufferTarget;

  if (conservativeSurplus > 0 && input.forecast.confidence >= 50) {
    opportunities.push({
      id: 'conservative-surplus',
      opportunity: 'Surplus funds are available after essential obligations and the emergency buffer target.',
      basis: `The conservative surplus is approximately ₹${Math.round(conservativeSurplus).toLocaleString('en-IN')}.`,
      suggestedNextStep: input.goalLabel
        ? `Review directing part of the surplus toward ${input.goalLabel}.`
        : 'Review a user-selected savings goal for the surplus.',
      confidence: input.forecast.confidence,
    });
    reasoning.push('A surplus opportunity is based on the low income scenario, not the optimistic scenario.');
  }

  if (input.forecast.highScenario > input.forecast.expectedScenario && input.forecast.confidence >= 60) {
    opportunities.push({
      id: 'improving-income-capacity',
      opportunity: 'Recent income history includes capacity above the expected scenario.',
      basis: `The high scenario is ₹${Math.round(input.forecast.highScenario).toLocaleString('en-IN')} versus an expected ₹${Math.round(input.forecast.expectedScenario).toLocaleString('en-IN')}.`,
      suggestedNextStep: 'Review progress toward an existing goal after essential allocations are secured.',
      confidence: input.forecast.confidence,
    });
    reasoning.push('Higher observed income is surfaced as capacity, not guaranteed future income.');
  }

  if ((input.discretionarySpend || 0) > 0 && input.goalLabel && conservativeSurplus <= 0) {
    opportunities.push({
      id: 'goal-aligned-spending-review',
      opportunity: 'Recurring discretionary spending is competing with an existing goal.',
      basis: `Recorded discretionary spending is approximately ₹${Math.round(input.discretionarySpend || 0).toLocaleString('en-IN')} in the evaluated period.`,
      suggestedNextStep: `Review whether part of that spending can be redirected toward ${input.goalLabel}.`,
      confidence: Math.min(85, input.forecast.confidence),
    });
    reasoning.push('The spending opportunity is tied to a named goal and an actual conservative funding gap.');
  }

  if (opportunities.length === 0) {
    reasoning.push('No state-backed opportunity met the confidence and liquidity thresholds.');
  }

  return { opportunities, reasoning };
}
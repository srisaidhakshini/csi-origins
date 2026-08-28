export type ObjectiveKind =
  | 'essential_obligation'
  | 'recurring_obligation'
  | 'emergency_buffer'
  | 'savings_goal'
  | 'discretionary_spend'
  | 'investment';

export interface FinancialObjective {
  id: string;
  label: string;
  kind: ObjectiveKind;
  amount: number;
  dueInDays?: number;
  critical?: boolean;
  targetAmount?: number;
}

export interface ObjectivePrioritizationInput {
  objectives: FinancialObjective[];
  availableFunds: number;
  lowIncomeScenario: number;
  expectedIncomeScenario: number;
  forecastConfidence: number;
  riskTolerance: 'low' | 'medium' | 'high';
}

export interface RankedObjective extends FinancialObjective {
  rank: number;
  priorityScore: number;
  fundingStatus: 'covered' | 'at_risk' | 'deferred';
  reasoning: string[];
}

export interface ObjectivePrioritizationResult {
  rankedObjectives: RankedObjective[];
  conflicts: string[];
  reasoning: string[];
}

const KIND_WEIGHT: Record<ObjectiveKind, number> = {
  essential_obligation: 100,
  recurring_obligation: 82,
  emergency_buffer: 76,
  savings_goal: 52,
  investment: 42,
  discretionary_spend: 15,
};

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}

export function prioritizeObjectives(input: ObjectivePrioritizationInput): ObjectivePrioritizationResult {
  const availableFunds = Math.max(0, Number(input.availableFunds) || 0);
  const riskAdjustment = input.riskTolerance === 'low' ? 8 : input.riskTolerance === 'high' ? -8 : 0;
  const uncertaintyAdjustment = input.forecastConfidence < 50 ? 10 : input.forecastConfidence < 75 ? 5 : 0;
  const projectedFunds = availableFunds + Math.max(0, Number(input.lowIncomeScenario) || 0);
  let remainingFunds = projectedFunds;
  const conflicts: string[] = [];
  const reasoning: string[] = [
    `Priorities use the low income scenario of ₹${Math.round(input.lowIncomeScenario).toLocaleString('en-IN')} to preserve liquidity under uncertainty.`,
    `Risk tolerance is ${input.riskTolerance}; available funds start at ₹${Math.round(availableFunds).toLocaleString('en-IN')}.`,
  ];

  const ranked = input.objectives
    .filter(objective => Number.isFinite(objective.amount) && objective.amount >= 0)
    .map(objective => {
      const urgency = objective.dueInDays === undefined
        ? 0
        : clamp(30 - Math.max(0, objective.dueInDays), 0, 30) / 3;
      const criticality = objective.critical ? 8 : 0;
      const priorityScore = clamp(KIND_WEIGHT[objective.kind] + urgency + criticality + riskAdjustment + uncertaintyAdjustment, 0, 120);
      return { objective, priorityScore };
    })
    .sort((left, right) => right.priorityScore - left.priorityScore || left.objective.amount - right.objective.amount);

  const rankedObjectives = ranked.map(({ objective, priorityScore }, index) => {
    const canFund = remainingFunds >= objective.amount;
    const fundingStatus: RankedObjective['fundingStatus'] = canFund
      ? 'covered'
      : objective.kind === 'discretionary_spend' || objective.kind === 'investment' || objective.kind === 'savings_goal'
        ? 'deferred'
        : 'at_risk';

    if (canFund) {
      remainingFunds -= objective.amount;
    } else {
      conflicts.push(`${objective.label} competes for ₹${Math.round(objective.amount).toLocaleString('en-IN')} after higher-priority objectives.`);
    }

    const objectiveReasoning = [
      `Ranked from ${objective.kind.replaceAll('_', ' ')} priority.`,
      objective.dueInDays === undefined ? 'No due date was provided.' : `Due in ${Math.max(0, objective.dueInDays)} days.`,
      fundingStatus === 'covered' ? 'Covered in the conservative allocation.' : 'Not fully covered in the conservative allocation.',
    ];

    return {
      ...objective,
      rank: index + 1,
      priorityScore: Math.round(priorityScore * 100) / 100,
      fundingStatus,
      reasoning: objectiveReasoning,
    };
  });

  if (input.expectedIncomeScenario > input.lowIncomeScenario && input.forecastConfidence < 60) {
    reasoning.push('Expected income exceeds the conservative scenario, but confidence is too low to allocate the difference in advance.');
  }
  if (conflicts.length === 0) {
    reasoning.push('All provided objectives fit within the conservative projected funds.');
  }

  return { rankedObjectives, conflicts, reasoning };
}
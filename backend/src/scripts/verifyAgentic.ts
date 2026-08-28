import assert from 'assert';
import { forecastIncome } from '../intelligence/incomeForecaster';
import { prioritizeObjectives } from '../intelligence/goalPrioritizer';
import { planActions } from '../intelligence/actionPlanner';
import { detectOpportunities } from '../intelligence/opportunityDetector';

function run(): void {
  const uncertainForecast = forecastIncome([
    { amount: 10000, timestamp: new Date('2026-06-01') },
    { amount: 45000, timestamp: new Date('2026-07-01') },
  ]);
  assert.equal(uncertainForecast.sampleCount, 2);
  assert(uncertainForecast.confidence < 50);
  assert(uncertainForecast.lowScenario <= uncertainForecast.expectedScenario);
  assert(uncertainForecast.expectedScenario <= uncertainForecast.highScenario);

  const conflict = prioritizeObjectives({
    objectives: [
      { id: 'rent', label: 'Rent', kind: 'essential_obligation', amount: 28000, dueInDays: 3, critical: true },
      { id: 'sip', label: 'Investment SIP', kind: 'investment', amount: 5000, dueInDays: 8 },
    ],
    availableFunds: 12000,
    lowIncomeScenario: 0,
    expectedIncomeScenario: 35000,
    forecastConfidence: 30,
    riskTolerance: 'low',
  });
  assert.equal(conflict.rankedObjectives[0].label, 'Rent');
  assert.equal(conflict.rankedObjectives[0].fundingStatus, 'at_risk');
  assert(conflict.conflicts.length > 0);

  const competingGoals = prioritizeObjectives({
    objectives: [
      { id: 'rent', label: 'Rent', kind: 'essential_obligation', amount: 20000, critical: true },
      { id: 'buffer', label: 'Emergency Buffer', kind: 'emergency_buffer', amount: 10000 },
      { id: 'macbook', label: 'Laptop Goal', kind: 'savings_goal', amount: 15000 },
    ],
    availableFunds: 25000,
    lowIncomeScenario: 0,
    expectedIncomeScenario: 25000,
    forecastConfidence: 80,
    riskTolerance: 'medium',
  });
  assert.equal(competingGoals.rankedObjectives[0].label, 'Rent');
  assert(competingGoals.rankedObjectives.some(objective => objective.fundingStatus === 'deferred'));

  const planned = planActions({
    availableFunds: 12000,
    forecast: uncertainForecast,
    prioritization: conflict,
    discretionaryAmount: 3200,
  });
  assert(planned.options.some(option => option.id === 'reduce-discretionary-spend'));
  assert(planned.options.every(option => option.requiresUserApproval));

  const lowConfidenceOpportunity = detectOpportunities({
    availableFunds: 50000,
    upcomingEssentialFunds: 20000,
    emergencyBufferTarget: 15000,
    forecast: uncertainForecast,
    goalLabel: 'Emergency Buffer',
  });
  assert.equal(lowConfidenceOpportunity.opportunities.length, 0);

  const surplusOpportunity = detectOpportunities({
    availableFunds: 50000,
    upcomingEssentialFunds: 20000,
    emergencyBufferTarget: 15000,
    forecast: forecastIncome([
      { amount: 30000, timestamp: new Date('2026-06-01') },
      { amount: 32000, timestamp: new Date('2026-07-01') },
      { amount: 34000, timestamp: new Date('2026-08-01') },
      { amount: 31000, timestamp: new Date('2026-03-01') },
      { amount: 33000, timestamp: new Date('2026-04-01') },
      { amount: 35000, timestamp: new Date('2026-05-01') },
    ]),
    goalLabel: 'Emergency Buffer',
  });
  assert(surplusOpportunity.opportunities.length > 0);

  const missingData = forecastIncome([]);
  assert.equal(missingData.confidence, 0);
  assert.equal(missingData.expectedScenario, 0);

  console.log('Agentic decision scenarios passed.');
}

run();
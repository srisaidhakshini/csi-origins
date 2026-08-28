import { AnomalyDetector } from '../intelligence/anomalyDetector';
import { ReasoningAgent } from '../intelligence/reasoningAgent';
import { GraphManager } from '../graph/graphManager';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

async function verifyPhase5() {
  console.log('🧪 ===============================================');
  console.log('🧪 VERIFYING PHASE 5: INTELLIGENCE LAYER');
  console.log('🧪 ===============================================\n');

  const demoUser = await prisma.user.findUnique({ where: { id: DEMO_USER_ID } });
  const riskTolerance = demoUser?.riskTolerance || 'medium';

  // 1. Test Statistical Anomaly Baseline Scoring
  console.log('1️⃣ Evaluating Anomaly Baseline on Spend Events:');

  // Test Case A: Typical Dining Spend (Swiggy ₹320 on Wednesday)
  const typicalEvent = {
    userId: DEMO_USER_ID,
    source: 'sms' as const,
    amount: 320,
    merchant: 'Swiggy',
    type: 'debit' as const,
    category: 'food_dining',
    timestamp: new Date('2026-08-26T19:30:00Z'), // Wednesday
    rawPayload: {}
  };

  const typicalScore = await AnomalyDetector.scoreEvent(typicalEvent);
  console.log(`   🍽️ [Typical Spend] Swiggy ₹${typicalEvent.amount} (${typicalScore.dayName})`);
  console.log(`       - Baseline Mean: ₹${typicalScore.baselineMean}`);
  console.log(`       - Z-Score:       ${typicalScore.zScore}`);
  console.log(`       - Anomaly Score: ${typicalScore.anomalyScore} / 100`);
  console.log(`       - Is Anomaly:    ${typicalScore.isAnomaly ? '🚨 YES' : '✅ NO (Normal Spend)'}`);

  // Test Case B: Spike Dining Spend (Swiggy ₹2,850 on Wednesday)
  const spikeEvent = {
    userId: DEMO_USER_ID,
    source: 'sms' as const,
    amount: 2850,
    merchant: 'Swiggy',
    type: 'debit' as const,
    category: 'food_dining',
    timestamp: new Date('2026-08-26T21:00:00Z'), // Wednesday
    rawPayload: {}
  };

  const spikeScore = await AnomalyDetector.scoreEvent(spikeEvent);
  console.log(`\n   🚨 [Spike Spend] Swiggy ₹${spikeEvent.amount} (${spikeScore.dayName})`);
  console.log(`       - Baseline Mean: ₹${spikeScore.baselineMean}`);
  console.log(`       - Z-Score:       ${spikeScore.zScore}`);
  console.log(`       - Anomaly Score: ${spikeScore.anomalyScore} / 100`);
  console.log(`       - Deviation:     +${spikeScore.facts.deviationPercentage}%`);
  console.log(`       - Is Anomaly:    ${spikeScore.isAnomaly ? '🚨 YES (Triggered)' : '✅ NO'}`);

  // 2. Test Cascade-Triggered Narrative Generation
  console.log('\n2️⃣ Testing LLM Reasoning Agent on Computed Cascade Path:');
  const incomeNode = await prisma.node.findFirst({
    where: { userId: DEMO_USER_ID, label: { contains: 'TechCorp', mode: 'insensitive' } }
  });

  if (!incomeNode) throw new Error('Income node not found');
  const cascadeEval = await GraphManager.evaluateCascadeRisk(DEMO_USER_ID, incomeNode.id, 7);

  const cascadeExplanation = await ReasoningAgent.explainCascadeRisk({
    incomeLabel: cascadeEval.explanationFacts.incomeLabel,
    expectedIncome: cascadeEval.explanationFacts.expectedIncome,
    delayDays: cascadeEval.explanationFacts.delayDays,
    bufferBalance: cascadeEval.explanationFacts.bufferBalance,
    atRiskObligations: cascadeEval.explanationFacts.atRiskObligations,
    projectedShortfall: cascadeEval.explanationFacts.projectedShortfall,
    criticalDueDateDescription: cascadeEval.explanationFacts.criticalDueDateDescription,
    riskTolerance
  });

  console.log(`   📢 [Cascade Explanation Grounded in CTE Facts]:`);
  console.log(`   "${cascadeExplanation}"`);

  // 3. Test Anomaly-Triggered Narrative Generation
  console.log('\n3️⃣ Testing LLM Reasoning Agent on Computed Anomaly Spike:');
  const anomalyExplanation = await ReasoningAgent.explainAnomaly({
    merchant: spikeScore.facts.merchant,
    amount: spikeScore.facts.amount,
    baselineMean: spikeScore.facts.baselineMean,
    zScore: spikeScore.facts.zScore,
    category: spikeScore.facts.category,
    dayName: spikeScore.dayName,
    deviationPercentage: spikeScore.facts.deviationPercentage,
    riskTolerance
  });

  console.log(`   📢 [Anomaly Explanation Grounded in Statistical Baseline]:`);
  console.log(`   "${anomalyExplanation}"`);

  console.log('\n✨ Phase 5 Intelligence Layer Verification Complete!');
}

verifyPhase5()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

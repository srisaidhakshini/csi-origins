import { GraphManager } from '../graph/graphManager';
import { detectAndPromoteRecurringPatterns } from '../graph/recurringDetector';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

async function verifyPhase4() {
  console.log('🧪 ===============================================');
  console.log('🧪 VERIFYING PHASE 4: STATE LAYER & CAUSAL GRAPH');
  console.log('🧪 ===============================================\n');

  // 1. Test Recurring Pattern Detection
  console.log('1️⃣ Testing Recurring Pattern Detection on Raw Event History...');
  const recurringPromotions = await detectAndPromoteRecurringPatterns(DEMO_USER_ID);
  console.log(`   📊 Recurring promotions checked: ${recurringPromotions.length} new promotions (seeded obligations already exist)`);

  // 2. Find the Income Retainer Node
  const incomeNode = await prisma.node.findFirst({
    where: {
      userId: DEMO_USER_ID,
      label: { contains: 'TechCorp', mode: 'insensitive' }
    }
  });

  if (!incomeNode) {
    throw new Error('Income node not found for demo user');
  }

  console.log(`\n2️⃣ Executing Recursive CTE Cascade Query from Root Node:`);
  console.log(`   - Root: [${incomeNode.type.toUpperCase()}] "${incomeNode.label}" (₹${incomeNode.value}, Conf: ${incomeNode.confidence})`);

  const cascadeSteps = await GraphManager.executeCascadeQuery(incomeNode.id, 5);
  console.log(`   - Recursive CTE returned ${cascadeSteps.length} downstream edge transitions:\n`);

  for (const step of cascadeSteps) {
    console.log(`   [Depth ${step.depth}] ${step.sourceLabel.padEnd(26)} --(${step.relation.padEnd(15)}, w=${step.weight})--> ${step.targetLabel.padEnd(30)} [${step.targetType}] (₹${step.targetValue})`);
  }

  // 3. Evaluate Cascade Shortfall Simulation
  console.log('\n3️⃣ Evaluating Cascade Risk for Delayed Payout Event:');
  console.log(`   - Scenario: TechCorp Retainer (₹35,000) delayed by 7 days.`);

  const evalResult = await GraphManager.evaluateCascadeRisk(DEMO_USER_ID, incomeNode.id, 7);

  console.log(`\n   📈 Deterministic Cascade Computation Summary:`);
  console.log(`       - Available Buffer:          ₹${evalResult.availableBuffer.toLocaleString()}`);
  console.log(`       - Total Downstream Demands:  ₹${evalResult.totalRequired.toLocaleString()}`);
  console.log(`       - Total Projected Shortfall: ₹${evalResult.totalShortfall.toLocaleString()}`);
  console.log(`       - Deficit State:             ${evalResult.hasDeficit ? '⚠️ CRITICAL SHORTFALL DETECTED' : '✅ HEALTHY'}`);

  console.log(`\n   🎯 Downstream Affected Obligations:`);
  for (const ob of evalResult.affectedObligations) {
    const statusTag = ob.shortfall > 0 ? `❌ DEFICIT: -₹${ob.shortfall.toLocaleString()}` : `✅ COVERED`;
    console.log(`       - ${ob.label.padEnd(30)} Due Day: ${ob.dueDay?.toString().padStart(2)} | Required: ₹${ob.amount.toString().padStart(6)} | Status: ${statusTag}`);
  }

  console.log(`\n   📋 Computed Facts Passed to Intelligence Layer:`);
  console.log(`       - Income Source:       ${evalResult.explanationFacts.incomeLabel}`);
  console.log(`       - Delay Period:        ${evalResult.explanationFacts.delayDays} days`);
  console.log(`       - Buffer Balance:      ₹${evalResult.explanationFacts.bufferBalance}`);
  console.log(`       - At-Risk Obligations: ${evalResult.explanationFacts.atRiskObligations.join(', ')}`);
  console.log(`       - Projected Deficit:   ₹${evalResult.explanationFacts.projectedShortfall}`);

  console.log('\n✨ Phase 4 State Layer & Recursive CTE Cascade Verification Complete!');
}

verifyPhase4()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

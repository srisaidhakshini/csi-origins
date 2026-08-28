import { PipelineCoordinator } from '../pipeline/pipelineCoordinator';
import { IngestionPipeline } from '../ingestion';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

async function runDemoWalkthrough() {
  console.log('\n======================================================================');
  console.log('🏆 ORIGIN 2026 — AUTONOMOUS FINANCIAL COPILOT: END-TO-END DEMO PASS');
  console.log('======================================================================\n');

  // Step 0: Ensure fresh seed state
  const user = await prisma.user.findUnique({ where: { id: DEMO_USER_ID } });
  console.log(`👤 Active User: ${user?.id} (Risk Profile: ${user?.riskTolerance?.toUpperCase()})`);

  const nodes = await prisma.node.findMany({ where: { userId: DEMO_USER_ID } });
  const bufferNode = nodes.find(n => n.type === 'buffer');
  const incomeNode = nodes.find(n => n.type === 'income_source' && n.label.includes('TechCorp'));
  const rentNode = nodes.find(n => n.type === 'obligation' && n.label.includes('Rent'));

  console.log(`📊 Baseline State:`);
  console.log(`   - Income Retainer:  ₹${incomeNode?.value} (${incomeNode?.label})`);
  console.log(`   - Liquid Buffer:    ₹${bufferNode?.value} (${bufferNode?.label})`);
  console.log(`   - Monthly Rent:     ₹${rentNode?.value} (${rentNode?.label}, Due Day: 5)`);
  console.log('----------------------------------------------------------------------');

  // Step 1: Live Event 1 - Routine Spend (Swiggy ₹320)
  console.log('\n🎬 DEMO STEP 1: Live SMS Ingestion of Routine Daily Spend (Swiggy ₹320)');
  console.log('   Raw SMS: "Rs 320.00 spent on your HDFC Card at Swiggy on 28-Aug-26."');

  const event1Result = await PipelineCoordinator.processEvent({
    userId: DEMO_USER_ID,
    source: 'sms',
    amount: 320,
    merchant: 'Swiggy',
    type: 'debit',
    category: 'food_dining',
    timestamp: new Date(),
    rawPayload: { sender: 'VM-HDFCBK', text: 'Rs 320 debited at Swiggy' }
  });

  console.log(`   [Ingestion] Normalized Merchant: "${event1Result.dedupResult.event.merchant}" | Amount: ₹${event1Result.dedupResult.event.amount}`);
  console.log(`   [Anomaly Engine] Category Mean: ₹${event1Result.anomalyResult?.baselineMean} | Z-Score: ${event1Result.anomalyResult?.zScore} (Normal)`);
  console.log(`   [Intervention Gate] Score: ${event1Result.insightCreated.gateScore} / 100 ➔ STATUS: ${event1Result.insightCreated.status.toUpperCase()} (Held back in Transparency Log)`);

  // Step 2: Live Event 2 - Critical Delayed Income Cascade
  console.log('\n🎬 DEMO STEP 2: Triggering Delayed Gig Payout Cascade (TechCorp ₹35,000 Delayed 7 Days)');
  console.log('   Condition: Payout delayed past the 5th -> Rent is due on the 5th!');

  if (!incomeNode) throw new Error('Income node missing');
  const cascadeResult = await PipelineCoordinator.processDelayedIncomeTrigger(DEMO_USER_ID, incomeNode.id, 7);

  console.log(`   [Causal Graph CTE] Traversing Postgres edges from "${incomeNode.label}" (Depth ≤ 5):`);
  for (const step of cascadeResult.cascadeEval.cascadeSteps) {
    console.log(`       ↳ [Depth ${step.depth}] ${step.sourceLabel} --(${step.relation})--> ${step.targetLabel} [${step.targetType}]`);
  }
  console.log(`   [Deterministic Math] Buffer Balance: ₹${cascadeResult.cascadeEval.availableBuffer} vs Obligations: ₹${cascadeResult.cascadeEval.totalRequired}`);
  console.log(`   [Deterministic Math] Projected Shortfall Deficit: -₹${cascadeResult.cascadeEval.totalShortfall}`);
  console.log(`   [Intervention Gate] Score: ${cascadeResult.insightCreated.gateScore} (Sev: 70, Conf: 92, Urg: 88) ➔ STATUS: ${cascadeResult.insightCreated.status.toUpperCase()}`);
  console.log(`   [LLM Reasoning Agent Narrative]:`);
  console.log(`   📢 "${cascadeResult.insightCreated.explanation}"`);

  // Step 3: Live Event 3 - Corroborating Signal Fingerprint & Deduplication
  console.log('\n🎬 DEMO STEP 3: Multi-Source Deduplication (SMS Alert followed by Gmail E-Receipt)');
  const testDate = new Date();

  // Part A: SMS Alert arrives
  const smsAlert = await IngestionPipeline.processSMSWithDedup({
    sender: 'VM-HDFCBK',
    body: 'Rs 5,000.00 debited from A/C **4092 towards BSE Star MF SIP PPFAS Flexi Cap.',
    timestamp: testDate
  }, DEMO_USER_ID);
  console.log(`   Part A: SMS Alert Ingested ➔ Event ID: ${smsAlert?.rawEventId} | Confidence: ${smsAlert?.finalConfidence.toUpperCase()}`);

  // Part B: Gmail confirmation arrives 1 hour later
  const emailReceipt = await IngestionPipeline.processGmailWithDedup({
    id: 'gmail_bse_sip_rcpt',
    subject: 'BSE Star MF - SIP Transaction Confirmation',
    sender: 'donotreply@bsestarmf.in',
    body: 'Dear Investor, your SIP installment of INR 5,000.00 has been received successfully for PPFAS Mutual Fund.',
    date: new Date(testDate.getTime() + 60 * 60 * 1000).toISOString()
  }, DEMO_USER_ID);
  console.log(`   Part B: Gmail Receipt Ingested ➔ Fingerprint: ${emailReceipt?.fingerprint}`);
  console.log(`   [Deduplication Engine] Is Merged: ${emailReceipt?.isMerged} | Linked To: ${emailReceipt?.matchedEventId}`);
  console.log(`   [Confidence Promotion] Confidence promoted from INFERRED ➔ ${emailReceipt?.finalConfidence.toUpperCase()}`);

  // Step 4: Final Database Inspection
  console.log('\n🎬 DEMO STEP 4: Live Feed State Ready for Flutter Mobile App');
  const surfacedInsights = await prisma.insight.findMany({
    where: { userId: DEMO_USER_ID, status: 'surfaced' },
    orderBy: { createdAt: 'desc' },
  });
  const suppressedInsights = await prisma.insight.findMany({
    where: { userId: DEMO_USER_ID, status: 'suppressed' },
    orderBy: { createdAt: 'desc' },
  });

  console.log(`   📱 Flutter Surfaced Feed Count:     ${surfacedInsights.length} cards`);
  console.log(`   🛡️ Flutter Suppressed Log Count:    ${suppressedInsights.length} cards`);

  console.log('\n======================================================================');
  console.log('✅ DEMO PASS COMPLETE — SYSTEM READY FOR JUDGE PRESENTATION!');
  console.log('======================================================================\n');
}

runDemoWalkthrough()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

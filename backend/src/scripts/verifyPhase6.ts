import { PipelineCoordinator } from '../pipeline/pipelineCoordinator';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

async function verifyPhase6() {
  console.log('🧪 ===============================================');
  console.log('🧪 VERIFYING PHASE 6: INTERVENTION GATE & INSIGHTS');
  console.log('🧪 ===============================================\n');

  // Clear insights table for clean test output
  await prisma.insight.deleteMany({ where: { userId: DEMO_USER_ID } });

  console.log('1️⃣ Running End-to-End Candidates through the Intervention Gate...\n');

  // Candidate 1: Delayed Gig Income (Cascade Risk Trigger)
  const incomeNode = await prisma.node.findFirst({
    where: { userId: DEMO_USER_ID, label: { contains: 'TechCorp', mode: 'insensitive' } },
  });
  if (!incomeNode) throw new Error('Income node not found');

  console.log('🔹 Processing Candidate 1: Delayed Gig Retainer (TechCorp ₹35,000 delayed by 7 days)...');
  await PipelineCoordinator.processDelayedIncomeTrigger(DEMO_USER_ID, incomeNode.id, 7);

  // Candidate 2: Normal Routine Spend (Swiggy ₹320)
  console.log('\n🔹 Processing Candidate 2: Routine Meal (Swiggy ₹320)...');
  await PipelineCoordinator.processEvent({
    userId: DEMO_USER_ID,
    source: 'sms',
    amount: 320,
    merchant: 'Swiggy',
    type: 'debit',
    category: 'food_dining',
    timestamp: new Date(),
    rawPayload: { sender: 'VM-HDFCBK', text: 'Rs 320 debited' },
  });

  // Candidate 3: Heavy Weekend Party Spend (Swiggy ₹3,400)
  console.log('\n🔹 Processing Candidate 3: Spike Dining Spend (Swiggy ₹3,400)...');
  await PipelineCoordinator.processEvent({
    userId: DEMO_USER_ID,
    source: 'sms',
    amount: 3400,
    merchant: 'Swiggy',
    type: 'debit',
    category: 'food_dining',
    timestamp: new Date(),
    rawPayload: { sender: 'VM-HDFCBK', text: 'Rs 3400 debited' },
  });

  // Candidate 4: Mild Coffee / Snack (Third Wave Coffee ₹420)
  console.log('\n🔹 Processing Candidate 4: Mild Snack (Third Wave Coffee ₹420)...');
  await PipelineCoordinator.processEvent({
    userId: DEMO_USER_ID,
    source: 'sms',
    amount: 420,
    merchant: 'Third Wave Coffee',
    type: 'debit',
    category: 'food_dining',
    timestamp: new Date(),
    rawPayload: { sender: 'VM-HDFCBK', text: 'Rs 420 debited' },
  });

  // 2. Query Postgres Insights Table
  console.log('\n2️⃣ Querying Postgres `insights` Table to Verify Full Gate Logging:\n');
  const insights = await prisma.insight.findMany({
    where: { userId: DEMO_USER_ID },
    orderBy: { createdAt: 'asc' },
  });

  console.log(`📊 Total Insight Candidates Evaluated & Logged: ${insights.length}`);
  console.log('--------------------------------------------------------------------------------');

  for (const ins of insights) {
    const statusBadge = ins.status === 'surfaced' ? '🟢 [SURFACED ]' : '⚪ [SUPPRESSED]';
    console.log(`${statusBadge} Trigger: ${ins.triggerType.toUpperCase().padEnd(8)} | Gate Score: ${ins.gateScore?.toString().padStart(5)} / 100`);
    console.log(`   Weights: Sev: 0.40 (${ins.severity}), Conf: 0.35 (${ins.confidence}), Urg: 0.25 (${ins.urgency})`);
    console.log(`   Narrative: "${ins.explanation}"`);
    console.log('--------------------------------------------------------------------------------');
  }

  const surfacedCount = insights.filter(i => i.status === 'surfaced').length;
  const suppressedCount = insights.filter(i => i.status === 'suppressed').length;

  console.log(`\n✅ Summary: ${surfacedCount} Surfaced Insights, ${suppressedCount} Suppressed Insights.`);
  console.log('✨ Phase 6 Intervention Gate Verification Complete!');
}

verifyPhase6()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

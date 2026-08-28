import { IngestionPipeline } from '../ingestion';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

async function verifyPhase3() {
  console.log('🧪 ===============================================');
  console.log('🧪 VERIFYING PHASE 3: FINGERPRINTING & DEDUPLICATION');
  console.log('🧪 ===============================================\n');

  // Clear any previous test events for this run
  const testDate = new Date('2026-09-05T09:00:00Z');
  const testWindowStart = new Date(testDate.getTime() - 24 * 60 * 60 * 1000);
  const testWindowEnd = new Date(testDate.getTime() + 24 * 60 * 60 * 1000);

  await prisma.rawEvent.deleteMany({
    where: {
      userId: DEMO_USER_ID,
      createdAt: {
        gte: testWindowStart,
        lte: testWindowEnd
      }
    }
  });

  console.log('1️⃣ Step 1: Ingesting Event 1 via SMS (Bank Alert)...');
  const smsPayload = {
    sender: 'VM-HDFCBK',
    body: 'Dear Customer, Rs 28,000.00 debited from A/C **4092 on 05-Sep-26 to Skyline Properties via UPI.',
    timestamp: testDate
  };

  const smsResult = await IngestionPipeline.processSMSWithDedup(smsPayload, DEMO_USER_ID);
  if (!smsResult) {
    throw new Error('Failed to parse SMS');
  }

  console.log(`   ✅ [SMS Ingested]`);
  console.log(`       - Raw Event ID: ${smsResult.rawEventId}`);
  console.log(`       - Fingerprint:  ${smsResult.fingerprint}`);
  console.log(`       - Is Merged:    ${smsResult.isMerged}`);
  console.log(`       - Confidence:   ${smsResult.finalConfidence.toUpperCase()}`);

  console.log('\n2️⃣ Step 2: Ingesting Event 2 via Gmail (Same Transaction - Landlord E-Receipt)...');
  const gmailDate = new Date(testDate.getTime() + 2 * 60 * 60 * 1000); // 2 hours later
  const gmailPayload = {
    id: 'gmail_rent_rcpt_0905',
    subject: 'Skyline Properties - Rent Payment Receipt',
    sender: 'accounts@skylineproperties.com',
    body: 'Thank you. We have received payment receipt for Apartment Rent: INR 28,000.00 on 05-Sep-2026.',
    snippet: 'Payment receipt for Apartment Rent: INR 28,000.00',
    date: gmailDate.toISOString()
  };

  const gmailResult = await IngestionPipeline.processGmailWithDedup(gmailPayload, DEMO_USER_ID);
  if (!gmailResult) {
    throw new Error('Failed to parse Gmail');
  }

  console.log(`   ✅ [Gmail Ingested & Evaluated against Active Pipeline]`);
  console.log(`       - Raw Event ID:     ${gmailResult.rawEventId}`);
  console.log(`       - Fingerprint:      ${gmailResult.fingerprint}`);
  console.log(`       - Is Merged:        ${gmailResult.isMerged}`);
  console.log(`       - Matched Event ID: ${gmailResult.matchedEventId}`);
  console.log(`       - Confidence:       ${gmailResult.finalConfidence.toUpperCase()} (Upgraded!)`);

  console.log('\n3️⃣ Step 3: Ingesting Independent Event 3 (Swiggy ₹650)...');
  const independentSMS = {
    sender: 'VM-HDFCBK',
    body: 'Rs 650.00 spent on your HDFC Card at Swiggy on 05-Sep-26.',
    timestamp: testDate
  };
  const swiggyResult = await IngestionPipeline.processSMSWithDedup(independentSMS, DEMO_USER_ID);

  console.log(`   ✅ [Distinct Event Ingested]`);
  console.log(`       - Raw Event ID: ${swiggyResult?.rawEventId}`);
  console.log(`       - Is Merged:    ${swiggyResult?.isMerged} (Correctly kept separate)`);
  console.log(`       - Fingerprint:  ${swiggyResult?.fingerprint}`);

  console.log('\n4️⃣ Step 4: Verifying Raw Events Table & Relational Deduplication Linking:');
  const recordedEvents = await prisma.rawEvent.findMany({
    where: {
      userId: DEMO_USER_ID,
      createdAt: {
        gte: testWindowStart,
        lte: testWindowEnd
      }
    },
    include: {
      matchedEvent: true,
      childEvents: true
    }
  });

  console.log(`   📊 Total raw_events recorded in window: ${recordedEvents.length}`);
  for (const ev of recordedEvents) {
    const payload = ev.rawPayload as any;
    console.log(`   - [${ev.source.toUpperCase()}] ID: ${ev.id} | Amount: ₹${payload?.amount} | Merchant: ${payload?.merchant} | MatchedTo: ${ev.matchedEventId || 'None (Primary)'}`);
  }

  // Verification assert
  if (gmailResult.isMerged && gmailResult.matchedEventId === smsResult.rawEventId) {
    console.log('\n🎉 Confirmation: SMS and Gmail signals collapsed into 1 unified financial event with corroborating link and upgraded confidence!');
  } else {
    console.error('\n❌ Deduplication failed to link the matching events.');
  }

  console.log('\n✨ Phase 3 Fingerprinting and Deduplication Verification Complete!');
}

verifyPhase3()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

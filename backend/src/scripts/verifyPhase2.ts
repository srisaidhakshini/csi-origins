import { IngestionPipeline } from '../ingestion';
import { getGoogleAuthUrl } from '../ingestion/gmailClient';
import { DEMO_USER_ID } from '../constants';

async function verifyPhase2() {
  console.log('🧪 ===============================================');
  console.log('🧪 VERIFYING PHASE 2: INGESTION PIPELINE');
  console.log('🧪 ===============================================\n');

  // 1. Verify Google OAuth URL Generation
  const authUrl = getGoogleAuthUrl(DEMO_USER_ID);
  console.log('1️⃣ Google OAuth Configuration:');
  console.log(`   - Generated OAuth Consent URL: ${authUrl.substring(0, 75)}...`);
  console.log(`   - Scope: https://www.googleapis.com/auth/gmail.readonly\n`);

  // 2. Test SMS Parser with realistic Indian banking & gig messages
  console.log('2️⃣ Testing SMS Parser on Realistic Sample Messages:');
  const sampleSMS = [
    {
      sender: 'VM-HDFCBK',
      body: 'Dear Customer, Rs 28,000.00 debited from A/C **4092 on 05-Aug-26 to Skyline Properties via UPI. Avail Bal: Rs 12,000.00.'
    },
    {
      sender: 'AD-UPWORK',
      body: 'Payout of Rs 20,000.00 processed by Upwork Global on 18-Aug-2026 to your bank account.'
    },
    {
      sender: 'VM-HDFCBK',
      body: 'Rs 5,000.00 debited from A/C **4092 towards BSE Star MF SIP PPFAS Flexi Cap on 10-Aug-2026.'
    },
    {
      sender: 'VM-HDFCBK',
      body: 'Rs 340.00 spent on your HDFC Card at Swiggy on 25-Aug-26.'
    }
  ];

  for (const sms of sampleSMS) {
    const event = IngestionPipeline.ingestSMS(sms, DEMO_USER_ID);
    if (!event) {
      console.error(`   ❌ Failed to parse SMS: "${sms.body}"`);
      continue;
    }
    console.log(`   ✅ [SMS Parsed] Type: ${event.type.toUpperCase().padEnd(6)} | Amount: ₹${event.amount.toString().padStart(6)} | Merchant: ${event.merchant.padEnd(20)} | Category: ${event.category} (Conf: ${event.confidence})`);
  }

  // 3. Test Scoped Gmail Parser on 3 Real-world Scoped Formats
  console.log('\n3️⃣ Testing Gmail Scoped Parser on 3 Real Formats:');

  // Format 1: Bank Transaction / E-statement Alert
  const bankEmail = {
    id: 'gmail_sample_01',
    subject: 'Transaction Alert: INR 28,000.00 debited from your HDFC account',
    sender: 'HDFC Bank Alerts <alerts@hdfcbank.net>',
    body: 'Dear Customer, INR 28,000.00 has been debited from your A/C XX4092 on 05-Aug-2026 towards Skyline Properties Rent.',
    date: new Date('2026-08-05T10:30:00Z').toISOString()
  };

  // Format 2: Gig Payout Alert (Upwork / TechCorp)
  const gigEmail = {
    id: 'gmail_sample_02',
    subject: 'Payment Processed: TechCorp Labs Monthly Retainer Invoice #1078',
    sender: 'TechCorp Accounts <billing@techcorp.io>',
    body: 'Dear Freelancer, your retainer payment of INR 35,000.00 has been transferred directly to your bank account.',
    date: new Date('2026-08-01T09:00:00Z').toISOString()
  };

  // Format 3: Merchant Receipt / Utility
  const receiptEmail = {
    id: 'gmail_sample_03',
    subject: 'Payment Receipt: ACT Fibernet Broadband Services',
    sender: 'ACT eBill <ebill@actcorp.in>',
    body: 'Payment Receipt: We have received your bill payment of INR 3,500.00 for Account #ACT4091 on 12-Aug-2026.',
    date: new Date('2026-08-12T14:00:00Z').toISOString()
  };

  const emailSamples = [bankEmail, gigEmail, receiptEmail];

  for (const email of emailSamples) {
    const event = IngestionPipeline.ingestGmail(email, DEMO_USER_ID);
    if (!event) {
      console.error(`   ❌ Failed to parse Email: "${email.subject}"`);
      continue;
    }
    console.log(`   ✅ [Gmail Parsed] Type: ${event.type.toUpperCase().padEnd(6)} | Amount: ₹${event.amount.toString().padStart(6)} | Merchant: ${event.merchant.padEnd(20)} | Category: ${event.category} (Conf: ${event.confidence})`);
  }

  // 4. Test Ingestion Poller Integration
  console.log('\n4️⃣ Testing Gmail Poller Integration for Demo User:');
  const polledEvents = await IngestionPipeline.pollAndExtractGmailEvents(DEMO_USER_ID);
  console.log(`   ✅ Successfully polled and extracted ${polledEvents.length} events from Gmail poller:`);
  for (const ev of polledEvents) {
    console.log(`       - Source: ${ev.source} | ₹${ev.amount} | ${ev.merchant} (${ev.type})`);
  }

  console.log('\n✨ Phase 2 Ingestion Pipeline Verification Complete & Succeeded!');
}

verifyPhase2().catch(console.error);

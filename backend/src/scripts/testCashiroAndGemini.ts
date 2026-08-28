import { CashiroParserFactory } from '../ingestion/cashiro/cashiroParsers';
import { IngestionPipeline } from '../ingestion';
import { ReasoningAgent } from '../intelligence/reasoningAgent';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

async function testCashiroAndGemini() {
  console.log('🧪 =========================================================');
  console.log('🧪 TESTING REAL CASHIRO KOTLIN-PORTED SMS PARSER & GEMINI LLM');
  console.log('🧪 =========================================================\n');

  // 1. Test Cashiro Parsers across multiple real Indian bank SMS formats
  console.log('1️⃣ Testing Cashiro Bank Parsers across 5 Bank Formats:\n');

  const testMessages = [
    {
      bank: 'HDFC Bank',
      sender: 'VM-HDFCBK',
      body: 'Dear Customer, Rs 28,000.00 debited from A/C **4092 on 05-Aug-26 to Skyline Properties via UPI. Avail Bal: Rs 12,000.00 Ref 4239871234.'
    },
    {
      bank: 'ICICI Bank',
      sender: 'VK-ICICIB',
      body: 'Acct XX8012 debited for INR 5,000.00 on 10-Aug-26 towards BSE Star MF. UPI Ref 9988776655. Avbl Bal: INR 45,200.50.'
    },
    {
      bank: 'State Bank of India',
      sender: 'SBIINB',
      body: 'Your A/C 9876 debited by INR 3,500.00 on 12Aug26 transfer to ACT Fibernet UPI ref 11223344. Bal: Rs 8,400.00.'
    },
    {
      bank: 'Axis Bank',
      sender: 'AXISBK',
      body: 'INR 340.00 debited from A/c no. XX3091 on 25-Aug-26 towards Swiggy. Ref #AX90812.'
    },
    {
      bank: 'Upwork Gig Payout',
      sender: 'AD-UPWORK',
      body: 'Payout of Rs 35,000.00 processed by TechCorp Labs on 01-Aug-26 to your bank account XX4092.'
    }
  ];

  for (const sample of testMessages) {
    const parsed = CashiroParserFactory.parse(sample.sender, sample.body);
    if (!parsed) {
      console.error(`   ❌ Failed to parse: ${sample.bank}`);
      continue;
    }
    console.log(`   🏦 [${parsed.bankName.padEnd(22)}] Type: ${parsed.type.toUpperCase().padEnd(6)} | Amount: ₹${parsed.amount.toString().padStart(6)} | Merchant: ${parsed.merchant.padEnd(20)} | Acc: ${parsed.accountNumber || 'N/A'} | Ref: ${parsed.referenceNumber || 'N/A'} | Bal: ₹${parsed.balance ?? 'N/A'}`);
  }

  // 2. Test Ingestion Pipeline using Cashiro Parsers
  console.log('\n2️⃣ Testing IngestionPipeline with Cashiro Parser:');
  const commonEvent = IngestionPipeline.ingestSMS({
    sender: 'VM-HDFCBK',
    body: 'Dear Customer, Rs 28,000.00 debited from A/C **4092 to Skyline Properties. Avail Bal: Rs 12,000.00'
  }, DEMO_USER_ID);

  console.log(`   ✅ Normalized Common Event:`, {
    source: commonEvent?.source,
    merchant: commonEvent?.merchant,
    amount: commonEvent?.amount,
    type: commonEvent?.type,
    category: commonEvent?.category,
    accountNumber: commonEvent?.rawPayload.accountNumber,
    balance: commonEvent?.rawPayload.balance,
  });

  // 3. Test Reasoning Agent (Gemini API Integration)
  console.log('\n3️⃣ Testing Reasoning Agent Narrative Generation:');
  const narrative = await ReasoningAgent.explainCascadeRisk({
    incomeLabel: 'TechCorp Design Retainer',
    expectedIncome: 35000,
    delayDays: 7,
    bufferBalance: 12000,
    atRiskObligations: ['Apartment Rent (₹28,000)', 'SIP (₹5,000)'],
    projectedShortfall: 24500,
    criticalDueDateDescription: 'due on day 5',
    riskTolerance: 'medium',
  });

  console.log(`   📢 [Reasoning Agent Output]:`);
  console.log(`   "${narrative}"`);

  console.log('\n✨ Cashiro Kotlin-Ported Parser & Gemini Integration Test Complete!');
}

testCashiroAndGemini()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

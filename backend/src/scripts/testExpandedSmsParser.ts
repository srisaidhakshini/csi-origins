import { CashiroParserFactory, CashiroExtractors } from '../ingestion/cashiro/cashiroParsers';
import { IngestionPipeline } from '../ingestion';
import { DEMO_USER_ID } from '../constants';

async function runTests() {
  console.log('🧪 =================================================================');
  console.log('🧪 VERIFYING EXPANDED CASHIRO BANK PARSERS, MULTI-CURRENCY & OTP PRE-FILTER');
  console.log('🧪 =================================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, testName: string, detail?: any) {
    if (condition) {
      console.log(`  ✅ [PASS] ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${testName}`, detail || '');
      failed++;
    }
  }

  // --- 1. Test OTP / Promo / Spam Filter ---
  console.log('\n1️⃣ Testing Dedicated OTP & Spam Pre-Filter:');
  const otpSamples = [
    '582910 is your OTP for login at HDFC Netbanking. Do not share with anyone.',
    'Dear Customer, your one time password (OTP) for transaction of Rs 1,500.00 is 948123. Never share your OTP.',
    'Your verification code for Zerodha is 881203. Valid for 5 minutes.',
    'Congratulations! You are pre-approved for an instant loan of Rs 5,00,000. Apply now: https://bank.co/loan',
    'Your Avail Bal for A/C XX4092 is Rs 18,200.00.',
  ];

  for (const otp of otpSamples) {
    const isFiltered = CashiroExtractors.isNonFinancialOrOtp(otp);
    const parsed = CashiroParserFactory.parse('VM-BANK', otp);
    assert(isFiltered && parsed === null, `Correctly blocked non-transactional / OTP message: "${otp.slice(0, 45)}..."`);
  }

  // --- 2. Test Multi-Bank Parsers across 11 Indian & Global Banks ---
  console.log('\n2️⃣ Testing Bank-Specific SMS Formats:');

  const bankTestCases = [
    {
      name: 'HDFC Bank Debit',
      sender: 'VM-HDFCBK',
      body: 'Dear Customer, Rs 28,000.00 debited from A/C **4092 on 05-Aug-26 to Skyline Properties via UPI. Avail Bal: Rs 12,000.00 Ref 4239871234.',
      expectedBank: 'HDFC Bank',
      expectedAmount: 28000,
      expectedType: 'debit',
      expectedMerchant: 'Skyline Properties',
      expectedCategory: 'housing'
    },
    {
      name: 'ICICI Bank Debit (SIP)',
      sender: 'VK-ICICIB',
      body: 'Acct XX8012 debited for INR 5,000.00 on 10-Aug-26 towards BSE Star MF. UPI Ref 9988776655. Avbl Bal: INR 45,200.50.',
      expectedBank: 'ICICI Bank',
      expectedAmount: 5000,
      expectedType: 'debit',
      expectedMerchant: 'BSE Star MF',
      expectedCategory: 'investment'
    },
    {
      name: 'State Bank of India Debit',
      sender: 'SBIINB',
      body: 'Your A/C 9876 debited by INR 3,500.00 on 12Aug26 transfer to ACT Fibernet UPI ref 11223344. Bal: Rs 8,400.00.',
      expectedBank: 'State Bank of India',
      expectedAmount: 3500,
      expectedType: 'debit',
      expectedMerchant: 'ACT Fibernet',
      expectedCategory: 'utilities'
    },
    {
      name: 'Axis Bank Debit (Quick Commerce)',
      sender: 'AXISBK',
      body: 'INR 480.00 debited from A/c no. XX3091 on 25-Aug-26 towards Blinkit. Ref #AX90812.',
      expectedBank: 'Axis Bank',
      expectedAmount: 480,
      expectedType: 'debit',
      expectedMerchant: 'Blinkit',
      expectedCategory: 'groceries'
    },
    {
      name: 'Kotak Mahindra Bank Debit',
      sender: 'KOTAKB',
      body: 'Sent Rs.1,250.00 from Kotak Bank AC *9012 to Zepto on 26-Aug-26. Bal Rs.24,500.00 Ref 6712345.',
      expectedBank: 'Kotak Mahindra Bank',
      expectedAmount: 1250,
      expectedType: 'debit',
      expectedMerchant: 'Zepto',
      expectedCategory: 'groceries'
    },
    {
      name: 'Punjab National Bank Debit',
      sender: 'PNBSMS',
      body: 'A/C 4512 debited by Rs 1,499.00 on 20-Aug-26 towards Netflix. Bal: Rs 32,100.00.',
      expectedBank: 'Punjab National Bank',
      expectedAmount: 1499,
      expectedType: 'debit',
      expectedMerchant: 'Netflix',
      expectedCategory: 'entertainment'
    },
    {
      name: 'Canara Bank Debit',
      sender: 'CANBNK',
      body: 'Rs 850.00 debited from A/C *7721 towards Starbucks on 18-Aug-26. Avail Bal: Rs 15,200.',
      expectedBank: 'Canara Bank',
      expectedAmount: 850,
      expectedType: 'debit',
      expectedMerchant: 'Starbucks',
      expectedCategory: 'food_dining'
    },
    {
      name: 'IndusInd Bank Debit',
      sender: 'INDUSB',
      body: 'Your IndusInd Card ending 3310 was charged INR 2,100.00 at Uber India on 22-Aug-26.',
      expectedBank: 'IndusInd Bank',
      expectedAmount: 2100,
      expectedType: 'debit',
      expectedMerchant: 'Uber India',
      expectedCategory: 'transportation'
    },
    {
      name: 'Union Bank of India Credit',
      sender: 'UNIONB',
      body: 'A/C *1902 credited by Rs 42,000.00 on 01-Aug-26 by TechCorp Labs salary payout. Bal Rs 55,000.',
      expectedBank: 'Union Bank of India',
      expectedAmount: 4200,
      expectedType: 'credit',
      expectedCategory: 'income'
    },
    {
      name: 'Standard Chartered Debit',
      sender: 'SCISMS',
      body: 'Transaction of INR 3,999.00 on your StanChart Card ending 4401 at Amazon on 15-Aug-26. Ref SC98123.',
      expectedBank: 'Standard Chartered',
      expectedAmount: 3999,
      expectedType: 'debit',
      expectedMerchant: 'Amazon',
      expectedCategory: 'shopping'
    },
    {
      name: 'Citibank Credit',
      sender: 'CITIBK',
      body: 'Your Citi Account ending 6123 was credited with INR 25,000.00 from Upwork Global on 28-Aug-26.',
      expectedBank: 'Citibank',
      expectedAmount: 25000,
      expectedType: 'credit',
      expectedMerchant: 'Upwork Global',
      expectedCategory: 'income'
    }
  ];

  for (const tc of bankTestCases) {
    const parsed = CashiroParserFactory.parse(tc.sender, tc.body);
    const ok = parsed !== null &&
      parsed.bankName === tc.expectedBank &&
      parsed.type === tc.expectedType &&
      (tc.expectedMerchant ? parsed.merchant === tc.expectedMerchant : true) &&
      (tc.expectedCategory ? parsed.category === tc.expectedCategory : true);

    assert(ok, `Bank Parser [${tc.expectedBank}]: ${tc.name}`, parsed);
  }

  // --- 3. Test Multi-Currency Parsing (USD, EUR, GBP, AED, SGD) ---
  console.log('\n3️⃣ Testing Multi-Currency Parsing:');
  const currencyTestCases = [
    { sender: 'STRIPE', body: 'Payout of USD 1,250.00 credited to account XX1102 from Fiverr.', expCur: 'USD', expAmt: 1250, expType: 'credit' },
    { sender: 'REVOLUT', body: 'Payment of €45.50 to Spotify debited from card XX9981.', expCur: 'EUR', expAmt: 45.50, expType: 'debit' },
    { sender: 'WISE', body: '£120.00 received from Toptal LLC into your GBP balance.', expCur: 'GBP', expAmt: 120, expType: 'credit' },
    { sender: 'EMIRATES-NBD', body: 'AED 350.00 debited from A/C *5501 at Apple Store on 14-Aug-26.', expCur: 'AED', expAmt: 350, expType: 'debit' },
    { sender: 'DBS', body: 'SGD 85.00 paid to Grab Singapore from Card *4491.', expCur: 'SGD', expAmt: 85, expType: 'debit' },
  ];

  for (const tc of currencyTestCases) {
    const parsed = CashiroParserFactory.parse(tc.sender, tc.body);
    const ok = parsed !== null && parsed.currency === tc.expCur && parsed.amount === tc.expAmt && parsed.type === tc.expType;
    assert(ok, `Multi-Currency [${tc.expCur}]: ${tc.expAmt} ${tc.expType}`, parsed);
  }

  // --- 4. Ingestion Pipeline & Normalization ---
  console.log('\n4️⃣ Testing IngestionPipeline Integration:');
  const event = IngestionPipeline.ingestSMS({
    sender: 'VM-KOTAKB',
    body: 'Sent Rs.2,400.00 from Kotak Bank AC *9012 to Blinkit on 28-Aug-26. Bal Rs.18,500.00 Ref 6712345.'
  }, DEMO_USER_ID);

  assert(event !== null && event.merchant === 'Blinkit' && event.category === 'groceries' && event.amount === 2400, 'IngestionPipeline produces clean normalized CommonEvent', event);

  console.log('\n=================================================================');
  console.log(`🏁 TEST SUITE FINISHED: ${passed} PASSED / ${failed} FAILED`);
  console.log('=================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error('Test execution error:', err);
  process.exit(1);
});

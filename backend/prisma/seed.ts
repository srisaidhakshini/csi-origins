import { PrismaClient } from '@prisma/client';
import { DEMO_USER_ID } from '../src/constants';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Clean existing data
  await prisma.insight.deleteMany({});
  await prisma.rawEvent.deleteMany({});
  await prisma.edge.deleteMany({});
  await prisma.node.deleteMany({});
  await prisma.user.deleteMany({});

  // 1. Create Demo User
  const demoUser = await prisma.user.create({
    data: {
      id: DEMO_USER_ID,
      riskTolerance: 'medium',
      gmailRefreshToken: 'mock_gmail_refresh_token_for_demo',
    },
  });
  console.log(`👤 Created demo user: ${demoUser.id} (Risk tolerance: ${demoUser.riskTolerance})`);

  // 2. Create Nodes
  // Income 1: Primary Gig Retainer
  const nodeIncomeRetainer = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'income_source',
      label: 'TechCorp Design Retainer',
      value: 35000.00,
      confidence: 'confirmed',
      metadata: {
        cadence: 'monthly',
        expected_day: 1,
        payer: 'TechCorp Labs',
        category: 'income',
        status: 'active'
      }
    }
  });

  // Income 2: Variable Freelance UX Projects
  const nodeIncomeFreelance = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'income_source',
      label: 'Freelance UX Projects',
      value: 20000.00,
      confidence: 'inferred',
      metadata: {
        cadence: 'variable',
        payer: 'Upwork Global',
        category: 'income',
        avg_monthly: 22000
      }
    }
  });

  // Buffer: Checking Account / Primary Liquidity
  const nodeBufferChecking = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'buffer',
      label: 'HDFC Checking Balance',
      value: 12000.00,
      confidence: 'confirmed',
      metadata: {
        account_last4: '4092',
        target_buffer: 15000.00,
        currency: 'INR'
      }
    }
  });

  // Obligation 1: Monthly Rent
  const nodeRent = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'obligation',
      label: 'Apartment Rent',
      value: 28000.00,
      confidence: 'confirmed',
      metadata: {
        due_day: 5,
        category: 'housing',
        landlord: 'Skyline Properties',
        grace_period_days: 2
      }
    }
  });

  // Obligation 2: Recurring Mutual Fund SIP
  const nodeSIP = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'obligation',
      label: 'Parag Parikh Flexi Cap SIP',
      value: 5000.00,
      confidence: 'confirmed',
      metadata: {
        due_day: 10,
        category: 'investment',
        auto_debit: true
      }
    }
  });

  // Obligation 3: Utilities & Broadband
  const nodeUtilities = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'obligation',
      label: 'Broadband & Electricity Bills',
      value: 3500.00,
      confidence: 'inferred',
      metadata: {
        due_day: 12,
        category: 'utilities'
      }
    }
  });

  // Goal 1: Emergency Reserve Goal
  const nodeEmergencyGoal = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'goal',
      label: '6-Month Emergency Cushion',
      value: 100000.00,
      confidence: 'confirmed',
      metadata: {
        current_saved: 45000.00,
        target_date: '2026-12-31'
      }
    }
  });

  // Goal 2: MacBook Upgrade Goal
  const nodeMacBookGoal = await prisma.node.create({
    data: {
      userId: demoUser.id,
      type: 'goal',
      label: 'MacBook M3 Pro Upgrade',
      value: 160000.00,
      confidence: 'inferred',
      metadata: {
        current_saved: 60000.00,
        target_date: '2026-10-31'
      }
    }
  });

  console.log('📦 Created 8 nodes across income_source, buffer, obligation, and goal.');

  // 3. Create Edges (Causal Graph)
  // Income 1 funds Buffer
  await prisma.edge.create({
    data: {
      sourceId: nodeIncomeRetainer.id,
      targetId: nodeBufferChecking.id,
      relation: 'funds',
      weight: 1.0
    }
  });

  // Income 2 funds Buffer
  await prisma.edge.create({
    data: {
      sourceId: nodeIncomeFreelance.id,
      targetId: nodeBufferChecking.id,
      relation: 'funds',
      weight: 1.0
    }
  });

  // Buffer funds Rent
  await prisma.edge.create({
    data: {
      sourceId: nodeBufferChecking.id,
      targetId: nodeRent.id,
      relation: 'funds',
      weight: 1.0
    }
  });

  // Buffer funds SIP
  await prisma.edge.create({
    data: {
      sourceId: nodeBufferChecking.id,
      targetId: nodeSIP.id,
      relation: 'funds',
      weight: 1.0
    }
  });

  // Buffer funds Utilities
  await prisma.edge.create({
    data: {
      sourceId: nodeBufferChecking.id,
      targetId: nodeUtilities.id,
      relation: 'funds',
      weight: 1.0
    }
  });

  // Buffer buffers against Rent
  await prisma.edge.create({
    data: {
      sourceId: nodeBufferChecking.id,
      targetId: nodeRent.id,
      relation: 'buffers_against',
      weight: 1.0
    }
  });

  // Rent competes with MacBook Goal for surplus cash
  await prisma.edge.create({
    data: {
      sourceId: nodeRent.id,
      targetId: nodeMacBookGoal.id,
      relation: 'competes_with',
      weight: 0.8
    }
  });

  // Buffer funds Emergency Goal (overflow)
  await prisma.edge.create({
    data: {
      sourceId: nodeBufferChecking.id,
      targetId: nodeEmergencyGoal.id,
      relation: 'funds',
      weight: 0.5
    }
  });

  console.log('🔗 Created causal graph edges (funds, buffers_against, competes_with).');

  // 4. Seed Synthetic Raw Events (2-3 months of realistic history)
  const now = new Date();
  const rawEventsData = [];

  // Month -2 events (60 days ago)
  const dateM2 = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);
  rawEventsData.push(
    {
      userId: demoUser.id,
      source: 'gmail',
      fingerprint: 'fp_techcorp_35000_m2',
      rawPayload: {
        merchant: 'TechCorp Labs',
        amount: 35000,
        type: 'credit',
        category: 'income',
        description: 'Invoice #1042 payout credited',
        date: new Date(dateM2.getFullYear(), dateM2.getMonth(), 1).toISOString()
      },
      createdAt: new Date(dateM2.getFullYear(), dateM2.getMonth(), 1)
    },
    {
      userId: demoUser.id,
      source: 'sms',
      fingerprint: 'fp_rent_28000_m2',
      rawPayload: {
        sender: 'VM-HDFCBK',
        amount: 28000,
        type: 'debit',
        merchant: 'Skyline Properties',
        description: 'Rs 28,000.00 debited from HDFC Bank A/C XX4092 on 05-Jun to Skyline Properties',
        date: new Date(dateM2.getFullYear(), dateM2.getMonth(), 5).toISOString()
      },
      createdAt: new Date(dateM2.getFullYear(), dateM2.getMonth(), 5)
    },
    {
      userId: demoUser.id,
      source: 'sms',
      fingerprint: 'fp_sip_5000_m2',
      rawPayload: {
        sender: 'VM-HDFCBK',
        amount: 5000,
        type: 'debit',
        merchant: 'BSE Star MF',
        description: 'Rs 5,000.00 debited for SIP PPFAS Mutual Fund',
        date: new Date(dateM2.getFullYear(), dateM2.getMonth(), 10).toISOString()
      },
      createdAt: new Date(dateM2.getFullYear(), dateM2.getMonth(), 10)
    },
    {
      userId: demoUser.id,
      source: 'sms',
      fingerprint: 'fp_upwork_18500_m2',
      rawPayload: {
        sender: 'AD-UPWORK',
        amount: 18500,
        type: 'credit',
        merchant: 'Upwork Global Inc',
        description: 'Payout of Rs 18,500.00 processed to your bank account',
        date: new Date(dateM2.getFullYear(), dateM2.getMonth(), 18).toISOString()
      },
      createdAt: new Date(dateM2.getFullYear(), dateM2.getMonth(), 18)
    }
  );

  // Month -1 events (30 days ago)
  const dateM1 = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  rawEventsData.push(
    {
      userId: demoUser.id,
      source: 'gmail',
      fingerprint: 'fp_techcorp_35000_m1',
      rawPayload: {
        merchant: 'TechCorp Labs',
        amount: 35000,
        type: 'credit',
        category: 'income',
        description: 'Invoice #1078 payout credited',
        date: new Date(dateM1.getFullYear(), dateM1.getMonth(), 1).toISOString()
      },
      createdAt: new Date(dateM1.getFullYear(), dateM1.getMonth(), 1)
    },
    {
      userId: demoUser.id,
      source: 'sms',
      fingerprint: 'fp_rent_28000_m1',
      rawPayload: {
        sender: 'VM-HDFCBK',
        amount: 28000,
        type: 'debit',
        merchant: 'Skyline Properties',
        description: 'Rs 28,000.00 debited from HDFC Bank A/C XX4092 on 05-Jul to Skyline Properties',
        date: new Date(dateM1.getFullYear(), dateM1.getMonth(), 5).toISOString()
      },
      createdAt: new Date(dateM1.getFullYear(), dateM1.getMonth(), 5)
    },
    {
      userId: demoUser.id,
      source: 'sms',
      fingerprint: 'fp_sip_5000_m1',
      rawPayload: {
        sender: 'VM-HDFCBK',
        amount: 5000,
        type: 'debit',
        merchant: 'BSE Star MF',
        description: 'Rs 5,000.00 debited for SIP PPFAS Mutual Fund',
        date: new Date(dateM1.getFullYear(), dateM1.getMonth(), 10).toISOString()
      },
      createdAt: new Date(dateM1.getFullYear(), dateM1.getMonth(), 10)
    },
    {
      userId: demoUser.id,
      source: 'gmail',
      fingerprint: 'fp_upwork_22000_m1',
      rawPayload: {
        merchant: 'Upwork Global Inc',
        amount: 22000,
        type: 'credit',
        category: 'income',
        description: 'Your payment of $265.00 (INR 22,000) is on its way',
        date: new Date(dateM1.getFullYear(), dateM1.getMonth(), 21).toISOString()
      },
      createdAt: new Date(dateM1.getFullYear(), dateM1.getMonth(), 21)
    }
  );

  // Spend baseline events for anomaly calculations (Swiggy, Zomato, Groceries, Dining)
  for (let i = 45; i >= 1; i -= 2) {
    const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
    const dayOfWeek = d.getDay();
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
    const foodSpend = isWeekend ? (450 + (i % 5) * 60) : (220 + (i % 4) * 40);
    rawEventsData.push({
      userId: demoUser.id,
      source: 'sms',
      fingerprint: `fp_swiggy_${foodSpend}_${i}`,
      rawPayload: {
        sender: 'VM-HDFCBK',
        amount: foodSpend,
        type: 'debit',
        merchant: 'Swiggy / Bundl Technologies',
        category: 'food_dining',
        date: d.toISOString()
      },
      createdAt: d
    });
  }

  for (const event of rawEventsData) {
    await prisma.rawEvent.create({ data: event });
  }
  console.log(`🧾 Inserted ${rawEventsData.length} raw synthetic events for historical baseline.`);

  // 5. Seed Initial Sample Insights (Surfaced Cascade and Suppressed Anomaly)
  await prisma.insight.create({
    data: {
      userId: demoUser.id,
      triggerType: 'cascade',
      severity: 85.0,
      confidence: 90.0,
      urgency: 80.0,
      gateScore: 85.5,
      status: 'surfaced',
      explanation: 'Your ₹35,000 retainer from TechCorp Labs is overdue by 3 days. With your current buffer at ₹12,000, this creates an upcoming ₹16,000 deficit for your ₹28,000 rent payment due in 2 days.',
      graphPath: {
        rootNodeId: nodeIncomeRetainer.id,
        rootNodeLabel: nodeIncomeRetainer.label,
        delayDays: 3,
        bufferBalance: 12000,
        totalShortfall: 16000,
        steps: [
          { from: 'TechCorp Design Retainer', to: 'HDFC Checking Balance', relation: 'funds', weight: 1.0, depth: 1 },
          { from: 'HDFC Checking Balance', to: 'Apartment Rent', relation: 'funds', weight: 1.0, depth: 2 },
          { from: 'HDFC Checking Balance', to: 'Parag Parikh Flexi Cap SIP', relation: 'funds', weight: 1.0, depth: 2 },
          { from: 'HDFC Checking Balance', to: 'Broadband & Electricity Bills', relation: 'funds', weight: 1.0, depth: 2 },
        ],
        affectedObligations: [
          { id: nodeRent.id, label: 'Apartment Rent', amount: 28000, dueDay: 5, shortfall: 16000 },
          { id: nodeSIP.id, label: 'Parag Parikh Flexi Cap SIP', amount: 5000, dueDay: 10, shortfall: 5000 },
        ],
      },
      councilDebate: {
        deliberatedAt: new Date().toISOString(),
        consensusStatus: 'surfaced',
        statements: [
          {
            agentName: 'Liquidity Auditor',
            agentRole: 'Buffer Reserve & Insolvency Defense',
            avatarIcon: 'shield_rounded',
            verdict: 'urgent',
            statement: 'Insolvency risk confirmed. With only ₹12,000 in checking, delaying the ₹35,000 TechCorp Retainer by 3 days causes a deterministic ₹16,000 deficit on Apartment Rent (due on day 5).',
            evidence: { bufferBalance: 12000, totalShortfall: 16000, dueDay: 5 },
          },
          {
            agentName: 'Gig Forecaster',
            agentRole: 'Cash Flow Volatility & Inflow Timing',
            avatarIcon: 'trending_up_rounded',
            verdict: 'warning',
            statement: 'Secondary Upwork payout (~₹20,000) projected around Day 18-21 based on past cadence, but arrives 13 days too late for Rent. TechCorp retainer is the single point of failure.',
            evidence: { primaryPayer: 'TechCorp Labs', secondaryInflow: 'Upwork UX Projects (~₹20,000)' },
          },
          {
            agentName: 'Behavioral Gatekeeper',
            agentRole: 'Discretionary Budget & Anomaly Control',
            avatarIcon: 'savings_outlined',
            verdict: 'opportunity',
            statement: 'Halting non-essential dining/delivery for the next 7 days will preserve approx ₹3,200 in cash liquidity to soften the deficit.',
            evidence: { preservableLiquidity: 3200, category: 'Food & Dining' },
          },
        ],
      },
      actions: [
        {
          id: 'act_demo_seed_1',
          title: 'Send Polite Client Payment Reminder',
          description: 'Auto-drafted professional payment reminder email to TechCorp Accounts.',
          actionType: 'invoice_nudge',
          status: 'pending',
          impactAmount: 35000,
          payload: {
            recipient: 'billing@techcorp.io',
            subject: 'Payment Follow-up: Invoice #1078 (TechCorp Design Retainer)',
            bodyText: 'Hi TechCorp Billing Team,\n\nI hope you are having a great week. I am checking in regarding the payout for Invoice #1078 (₹35,000) due on the 1st. Could you please confirm if this has been disbursed to my primary account?\n\nThank you,\nFreelancer',
          },
        },
        {
          id: 'act_demo_seed_2',
          title: 'Pause Mutual Fund SIP to Avoid Bounce Fee',
          description: 'Temporarily pause upcoming ₹5,000 Parag Parikh Flexi Cap SIP to preserve buffer for rent.',
          actionType: 'sip_pause',
          status: 'pending',
          impactAmount: 5000,
          payload: {
            adjustmentCategory: 'investment',
            savingsEstimate: 5000,
          },
        },
        {
          id: 'act_demo_seed_3',
          title: 'Activate 7-Day Discretionary Freeze',
          description: 'Reallocate ₹3,500 everyday dining allowance to checking buffer until retainer settles.',
          actionType: 'budget_shift',
          status: 'pending',
          impactAmount: 3500,
          payload: {
            adjustmentCategory: 'food_dining',
            savingsEstimate: 3500,
          },
        },
      ],
    },
  });

  await prisma.insight.create({
    data: {
      userId: demoUser.id,
      triggerType: 'anomaly',
      severity: 35.0,
      confidence: 60.0,
      urgency: 25.0,
      gateScore: 38.0,
      status: 'suppressed',
      explanation: 'Slightly elevated dining spend detected on Friday (₹850 vs typical ₹480 baseline). Suppressed by intervention gate as liquidity risk is nominal.',
      graphPath: {
        merchant: 'Swiggy',
        amount: 850,
        baselineMean: 480,
        zScore: 1.62,
        deviationPercentage: 77,
      },
      councilDebate: {
        deliberatedAt: new Date().toISOString(),
        consensusStatus: 'suppressed',
        statements: [
          {
            agentName: 'Liquidity Auditor',
            agentRole: 'Buffer Reserve & Insolvency Defense',
            avatarIcon: 'shield_rounded',
            verdict: 'stable',
            statement: 'Checking balance remains above safety floor. No cascade threat.',
            evidence: { bufferBalance: 12000 },
          },
          {
            agentName: 'Behavioral Gatekeeper',
            agentRole: 'Discretionary Budget & Anomaly Control',
            avatarIcon: 'savings_outlined',
            verdict: 'stable',
            statement: 'Z-score of 1.62 is within standard weekend variance limit. Suppressed to eliminate notification fatigue.',
            evidence: { zScore: 1.62, deviationPercentage: 77 },
          },
        ],
      },
      actions: [],
    },
  });

  console.log('💡 Seeded initial demonstration insights (1 surfaced cascade, 1 suppressed anomaly).');
  console.log('✅ Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

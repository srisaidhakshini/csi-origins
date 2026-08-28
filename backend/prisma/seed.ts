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
        nodes: [
          { id: nodeIncomeRetainer.id, label: nodeIncomeRetainer.label, type: 'income_source', value: 35000, status: 'delayed' },
          { id: nodeBufferChecking.id, label: nodeBufferChecking.label, type: 'buffer', value: 12000, status: 'depleting' },
          { id: nodeRent.id, label: nodeRent.label, type: 'obligation', value: 28000, due_in_days: 2, shortfall: 16000 }
        ],
        edges: [
          { source: nodeIncomeRetainer.label, target: nodeBufferChecking.label, relation: 'funds' },
          { source: nodeBufferChecking.label, target: nodeRent.label, relation: 'funds' }
        ]
      }
    }
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
        baseline_mean: 480,
        z_score: 1.62
      }
    }
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

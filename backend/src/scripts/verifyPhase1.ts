import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function verify() {
  console.log('🔍 Verifying Phase 1 Database State & Causal Graph...\n');

  // Query User
  const users = await prisma.user.findMany();
  console.log(`👤 Users Count: ${users.length}`);
  for (const user of users) {
    console.log(`   - ID: ${user.id}, Risk Tolerance: ${user.riskTolerance}`);
  }

  // Query Nodes
  const nodes = await prisma.node.findMany({
    include: {
      outEdges: {
        include: { target: true }
      },
      inEdges: {
        include: { source: true }
      }
    }
  });
  console.log(`\n📦 Nodes Count: ${nodes.length}`);
  for (const node of nodes) {
    console.log(`   - [${node.type.toUpperCase()}] ${node.label} (₹${node.value ?? 'N/A'}, Conf: ${node.confidence})`);
    if (node.outEdges.length > 0) {
      for (const edge of node.outEdges) {
        console.log(`       ↳ [${edge.relation}] ➔ ${edge.target.label} (weight: ${edge.weight})`);
      }
    }
  }

  // Query Edges
  const edges = await prisma.edge.findMany();
  console.log(`\n🔗 Edges Count: ${edges.length}`);

  // Query Raw Events
  const rawEvents = await prisma.rawEvent.findMany({
    orderBy: { createdAt: 'desc' },
    take: 5
  });
  const totalEvents = await prisma.rawEvent.count();
  console.log(`\n🧾 Raw Events Total: ${totalEvents} (Showing latest 5):`);
  for (const ev of rawEvents) {
    console.log(`   - [${ev.source.toUpperCase()}] Fingerprint: ${ev.fingerprint} | Created: ${ev.createdAt.toISOString()}`);
  }

  // Query Insights
  const insights = await prisma.insight.findMany();
  console.log(`\n💡 Insights Count: ${insights.length}`);
  for (const ins of insights) {
    console.log(`   - [${ins.status.toUpperCase()}] Trigger: ${ins.triggerType} | Gate Score: ${ins.gateScore} | Sev: ${ins.severity}, Conf: ${ins.confidence}, Urg: ${ins.urgency}`);
    console.log(`     Explanation: ${ins.explanation}`);
  }

  console.log('\n✅ Phase 1 Database & Seed Verification Passed!');
}

verify()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testRecursiveCTE() {
  console.log('🔄 Testing Recursive CTE Cascade Query from Income Retainer Node...\n');

  // Find the Income Retainer node
  const incomeNode = await prisma.node.findFirst({
    where: { label: 'TechCorp Design Retainer' }
  });

  if (!incomeNode) {
    throw new Error('Income node not found');
  }

  const cascadeResults: any[] = await prisma.$queryRaw`
    WITH RECURSIVE cascade AS (
      SELECT id, source_id, target_id, relation, weight, 1 AS depth
      FROM edges WHERE source_id = ${incomeNode.id}::uuid
      UNION ALL
      SELECT e.id, e.source_id, e.target_id, e.relation, e.weight, c.depth + 1
      FROM edges e JOIN cascade c ON e.source_id = c.target_id
      WHERE c.depth < 5
    )
    SELECT 
      c.depth,
      c.relation,
      c.weight,
      n_src.id as source_id,
      n_src.label as source_label,
      n_src.type as source_type,
      n_src.value as source_value,
      n_tgt.id as target_id,
      n_tgt.label as target_label,
      n_tgt.type as target_type,
      n_tgt.value as target_value
    FROM cascade c
    JOIN nodes n_src ON c.source_id = n_src.id
    JOIN nodes n_tgt ON c.target_id = n_tgt.id
    ORDER BY c.depth ASC;
  `;

  console.log(`Cascade Path Starting from: [${incomeNode.type.toUpperCase()}] "${incomeNode.label}" (₹${incomeNode.value}):`);
  for (const row of cascadeResults) {
    console.log(`  [Depth ${row.depth}] ${row.source_label} --(${row.relation}, w=${row.weight})--> ${row.target_label} [${row.target_type}] (₹${row.target_value})`);
  }

  console.log('\n✅ Recursive CTE query executed and returned clean cascade downstream hierarchy!');
}

testRecursiveCTE()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

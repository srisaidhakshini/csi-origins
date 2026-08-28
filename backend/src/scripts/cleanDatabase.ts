import prisma from '../db/prisma';

async function cleanDatabase() {
  console.log('🧹 Starting database cleanup...');

  // 1. Delete all insights
  const deletedInsights = await prisma.insight.deleteMany({});
  console.log(`🗑️  Deleted ${deletedInsights.count} insights.`);

  // 2. Delete all transactions
  const deletedTx = await prisma.transaction.deleteMany({});
  console.log(`🗑️  Deleted ${deletedTx.count} transactions.`);

  // 3. Delete all obligations
  const deletedObligations = await prisma.obligation.deleteMany({});
  console.log(`🗑️  Deleted ${deletedObligations.count} obligations.`);

  // 4. Delete users
  const deletedUsers = await prisma.user.deleteMany({});
  console.log(`🗑️  Deleted ${deletedUsers.count} users.`);

  console.log('✨ Database is completely clean and ready for fresh onboarding & live SMS ingestion!');
}

cleanDatabase()
  .catch((e) => {
    console.error('❌ Error cleaning database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

import prisma from '../db/prisma';
import { normalizeMerchant } from '../ingestion/smsParser';

export interface RecurringPatternResult {
  detected: boolean;
  merchant: string;
  amount: number;
  cadence: 'monthly' | 'weekly';
  promotedNodeId?: string;
  promotedNodeLabel?: string;
}

/**
 * Inspects transaction history to detect recurring payments and promotes them to obligation nodes.
 */
export async function detectAndPromoteRecurringPatterns(userId: string): Promise<RecurringPatternResult[]> {
  const results: RecurringPatternResult[] = [];

  // Fetch all debit events
  const rawEvents = await prisma.rawEvent.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });

  // Group events by normalized merchant
  const merchantGroups: Record<string, Array<{ amount: number; date: Date; rawPayload: any }>> = {};

  for (const ev of rawEvents) {
    const payload = ev.rawPayload as any;
    const amount = Number(payload?.amount) || 0;
    const type = payload?.type || '';
    const merchant = normalizeMerchant(payload?.merchant || payload?.sender || '');

    if (type === 'debit' && amount > 0 && merchant && merchant !== 'Merchant') {
      if (!merchantGroups[merchant]) {
        merchantGroups[merchant] = [];
      }
      merchantGroups[merchant].push({
        amount,
        date: new Date(ev.createdAt),
        rawPayload: payload,
      });
    }
  }

  // Check for periodic recurrence (~25 to 35 days apart for monthly)
  for (const [merchant, events] of Object.entries(merchantGroups)) {
    if (events.length < 2) continue;

    // Sort ascending by date
    events.sort((a, b) => a.date.getTime() - b.date.getTime());

    let isMonthly = false;
    let avgAmount = 0;
    let lastDueDay = 1;

    for (let i = 1; i < events.length; i++) {
      const daysDiff = (events[i].date.getTime() - events[i - 1].date.getTime()) / (1000 * 60 * 60 * 24);
      if (daysDiff >= 24 && daysDiff <= 36) {
        isMonthly = true;
        avgAmount = Math.round((events[i].amount + events[i - 1].amount) / 2);
        lastDueDay = events[i].date.getDate();
        break;
      }
    }

    if (isMonthly) {
      // Check if an obligation node already exists for this merchant or related label
      const existingNodes = await prisma.node.findMany({
        where: {
          userId,
          type: 'obligation',
        },
      });

      const normMerchant = merchant.toLowerCase();
      const existingNode = existingNodes.find(n => {
        const normLabel = n.label.toLowerCase();
        return (
          normLabel.includes(normMerchant) ||
          normMerchant.includes(normLabel) ||
          (normMerchant.includes('skyline') && normLabel.includes('rent')) ||
          (normMerchant.includes('bse') && (normLabel.includes('sip') || normLabel.includes('flexi'))) ||
          (normMerchant.includes('act') && normLabel.includes('broadband'))
        );
      });

      if (!existingNode) {
        // Find user buffer node to connect edge
        const bufferNode = await prisma.node.findFirst({
          where: { userId, type: 'buffer' },
        });

        // Automatically promote to obligation node
        const obligationLabel = `${merchant} (Recurring Obligation)`;
        const newNode = await prisma.node.create({
          data: {
            userId,
            type: 'obligation',
            label: obligationLabel,
            value: avgAmount,
            confidence: 'confirmed',
            metadata: {
              cadence: 'monthly',
              due_day: lastDueDay,
              auto_promoted: true,
              detected_at: new Date().toISOString(),
            },
          },
        });

        // Wire causal edges from buffer to obligation
        if (bufferNode) {
          await prisma.edge.create({
            data: {
              sourceId: bufferNode.id,
              targetId: newNode.id,
              relation: 'funds',
              weight: 1.0,
            },
          });

          await prisma.edge.create({
            data: {
              sourceId: bufferNode.id,
              targetId: newNode.id,
              relation: 'buffers_against',
              weight: 1.0,
            },
          });
        }

        console.log(`✨ [RECURRING DETECTED] Promoted monthly recurring transaction "${merchant}" (₹${avgAmount}) to Obligation node.`);

        results.push({
          detected: true,
          merchant,
          amount: avgAmount,
          cadence: 'monthly',
          promotedNodeId: newNode.id,
          promotedNodeLabel: newNode.label,
        });
      }
    }
  }

  return results;
}

import { CommonEvent } from '../ingestion/types';
import prisma from '../db/prisma';
import crypto from 'crypto';

export class PipelineCoordinator {
  /**
   * Process an incoming financial event directly into PostgreSQL:
   * 1. Deduplicate by cryptographic fingerprint
   * 2. Insert into transactions table
   * 3. Update user's checking buffer balance
   * 4. Check against obligations and create insights if shortfall exists
   */
  public static async processEvent(event: CommonEvent): Promise<{
    dedupResult: any;
    transaction?: any;
    insightCreated?: any;
  }> {
    const rawPayload = event.rawPayload || {};
    const dateStr = event.timestamp instanceof Date
      ? event.timestamp.toISOString().split('T')[0]
      : new Date().toISOString().split('T')[0];

    // 1. Generate unique fingerprint
    const fingerprint = crypto
      .createHash('sha256')
      .update(`${event.userId}_${event.amount}_${event.merchant.toLowerCase().trim()}_${event.type}_${dateStr}`)
      .digest('hex');

    // 2. Check for duplicate transaction
    const existing = await prisma.transaction.findUnique({
      where: { fingerprint },
    });

    if (existing) {
      console.log(`ℹ️ Deduplicated duplicate transaction for ${event.merchant} (₹${event.amount})`);
      return {
        dedupResult: {
          isMerged: true,
          fingerprint,
          transactionId: existing.id,
        },
        transaction: existing,
      };
    }

    // 3. Insert transaction
    const transaction = await prisma.transaction.create({
      data: {
        userId: event.userId,
        amount: event.amount,
        currency: rawPayload.currency || 'INR',
        merchant: event.merchant,
        category: event.category || 'general',
        type: event.type,
        source: event.source,
        accountNumber: rawPayload.accountNumber,
        referenceNumber: rawPayload.referenceNumber,
        balance: rawPayload.balance !== undefined ? rawPayload.balance : null,
        bankName: rawPayload.bankName,
        fingerprint,
        timestamp: event.timestamp || new Date(),
        rawText: rawPayload.originalBody || null,
      },
    });

    // 4. Update User buffer balance
    const user = await prisma.user.findUnique({
      where: { id: event.userId },
      include: { obligations: true },
    });

    let newBalance = Number(user?.bufferBalance || 0);

    if (rawPayload.balance !== undefined && rawPayload.balance !== null && !isNaN(Number(rawPayload.balance))) {
      newBalance = Number(rawPayload.balance);
    } else {
      if (event.type === 'credit') {
        newBalance += Number(event.amount);
      } else {
        newBalance -= Number(event.amount);
      }
    }

    await prisma.user.upsert({
      where: { id: event.userId },
      update: { bufferBalance: newBalance },
      create: { id: event.userId, bufferBalance: newBalance },
    });

    // 5. Check if buffer has a deficit against upcoming monthly obligations
    let insightCreated: any = undefined;
    if (user?.obligations && user.obligations.length > 0) {
      const outflowObligations = user.obligations.filter((o: any) => o.type === 'outflow');
      const totalRequired = outflowObligations.reduce((sum: number, o: any) => sum + Number(o.amount), 0);

      if (newBalance < totalRequired && outflowObligations.length > 0) {
        const shortfall = totalRequired - newBalance;
        const explanation = `Your current balance is ₹${newBalance.toLocaleString('en-IN')}. This creates an upcoming ₹${shortfall.toLocaleString('en-IN')} shortfall for your scheduled obligations (${outflowObligations.map((o: any) => `${o.label}: ₹${Number(o.amount).toLocaleString('en-IN')}`).join(', ')}).`;

        insightCreated = await prisma.insight.create({
          data: {
            userId: event.userId,
            triggerType: 'shortfall',
            severity: Math.min(100, Math.round((shortfall / totalRequired) * 100)),
            status: 'surfaced',
            explanation,
            actions: [
              {
                id: `act_${Date.now()}_1`,
                title: 'Review Upcoming Expenses',
                description: `Buffer is ₹${shortfall.toLocaleString('en-IN')} below scheduled payments.`,
                actionType: 'budget_shift',
                impactAmount: shortfall,
              },
            ],
          },
        });
      }
    }

    console.log(`✅ [Pipeline] Processed ${event.type.toUpperCase()} ₹${event.amount} (${event.merchant}). Updated Buffer: ₹${newBalance}`);

    return {
      dedupResult: {
        isMerged: false,
        fingerprint,
        transactionId: transaction.id,
      },
      transaction,
      insightCreated,
    };
  }

  /**
   * Process delayed income cascade trigger
   */
  public static async processDelayedIncomeTrigger(
    userId: string,
    sourceName: string = 'primary_retainer',
    delayDays: number = 7
  ): Promise<{
    cascadeEval: any;
    insightCreated?: any;
  }> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { obligations: true },
    });

    const balance = Number(user?.bufferBalance || 12000);
    const obligations = user?.obligations || [];
    const rent = obligations.find((o: any) => o.category === 'housing')?.amount || 28000;
    const deficit = Math.max(0, Number(rent) - balance);

    const explanation = `TechCorp retainer payout is delayed by ${delayDays} days. With ₹${balance.toLocaleString('en-IN')} in your buffer, a ₹${deficit.toLocaleString('en-IN')} deficit will occur before rent due date.`;

    const insightCreated = await prisma.insight.create({
      data: {
        userId,
        triggerType: 'shortfall',
        severity: 85,
        status: 'surfaced',
        explanation,
        actions: [
          {
            id: `act_delay_${Date.now()}`,
            title: 'Pause Mutual Fund SIP Auto-Debit',
            description: 'Preserve ₹5,000 liquid buffer until client retainer settles.',
            actionType: 'pause_sip',
            impactAmount: 5000,
          },
        ],
      },
    });

    return {
      cascadeEval: {
        delayedSource: sourceName,
        delayDays,
        currentBuffer: balance,
        shortfallAmount: deficit,
        affectedObligations: ['Apartment Rent'],
      },
      insightCreated,
    };
  }
}

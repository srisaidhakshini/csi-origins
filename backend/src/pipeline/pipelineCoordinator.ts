import { CommonEvent } from '../ingestion/types';
import prisma from '../db/prisma';
import crypto from 'crypto';
import { AgentDecision, AgentOrchestrator } from '../intelligence/agentOrchestrator';
import { InterventionGate } from '../gate/interventionGate';

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
    decision?: AgentDecision;
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

    // 5. Forecast, prioritize, plan, and decide using the updated state.
    const decision = await AgentOrchestrator.evaluate(event, newBalance);
    let insightCreated: any = undefined;

    if (decision.triggerType === 'cascade' || decision.triggerType === 'anomaly') {
      insightCreated = await InterventionGate.evaluateAndLogCandidate({
        userId: event.userId,
        triggerType: decision.triggerType,
        severity: decision.severity,
        confidence: decision.confidence,
        urgency: decision.urgency,
        graphPath: decision.explanationFacts,
        explanationFacts: {
          ...decision.explanationFacts,
          baselineMean: decision.explanationFacts.anomaly?.baselineMean,
          zScore: decision.explanationFacts.anomaly?.zScore,
          dayName: decision.explanationFacts.anomaly?.dayName,
          deviationPercentage: decision.explanationFacts.anomaly?.facts?.deviationPercentage,
        },
        recommendationActions: decision.actionPlan.options,
      });
    } else if (decision.triggerType === 'opportunity') {
      const gateScore = InterventionGate.computeScore(decision.severity, decision.confidence, decision.urgency);
      const riskTolerance = user?.riskTolerance || 'medium';
      const threshold = InterventionGate.getThresholdForRiskTolerance(riskTolerance);
      insightCreated = await prisma.insight.create({
        data: {
          userId: event.userId,
          triggerType: 'opportunity',
          severity: decision.severity,
          confidence: decision.confidence,
          urgency: decision.urgency,
          gateScore,
          status: gateScore >= threshold ? 'surfaced' : 'suppressed',
          explanation: decision.opportunities.opportunities[0].opportunity,
          actions: decision.actionPlan.options as any,
          graphPath: decision.explanationFacts as any,
        },
      });
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
      decision,
    };
  }
}

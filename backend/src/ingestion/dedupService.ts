import prisma from '../db/prisma';
import { CommonEvent, NodeConfidence } from './types';
import { generateFingerprint } from './fingerprint';

export interface IngestionDedupResult {
  isMerged: boolean;
  transactionId?: string;
  fingerprint: string;
  finalConfidence: NodeConfidence;
  event: CommonEvent;
}

export class DedupService {
  /**
   * Evaluates deduplication for incoming event and inserts/merges into transactions table
   */
  public static async ingestAndDedup(event: CommonEvent): Promise<IngestionDedupResult> {
    const fingerprint = generateFingerprint(event.amount, event.merchant, event.timestamp);

    // Look for existing transaction with exact fingerprint
    const existing = await prisma.transaction.findUnique({
      where: { fingerprint },
    });

    if (existing) {
      console.log(`🔗 [DEDUP] Duplicate transaction found for ${event.merchant} (₹${event.amount}). Skipping double-insertion.`);
      return {
        isMerged: true,
        transactionId: existing.id,
        fingerprint,
        finalConfidence: 'confirmed',
        event,
      };
    }

    // Insert new clean transaction
    const newTx = await prisma.transaction.create({
      data: {
        userId: event.userId,
        amount: event.amount,
        currency: event.rawPayload?.currency || 'INR',
        merchant: event.merchant,
        category: event.category || 'general',
        type: event.type,
        source: event.source,
        accountNumber: event.rawPayload?.accountNumber,
        referenceNumber: event.rawPayload?.referenceNumber,
        balance: event.rawPayload?.balance !== undefined ? event.rawPayload.balance : null,
        bankName: event.rawPayload?.bankName,
        fingerprint,
        timestamp: event.timestamp || new Date(),
        rawText: event.rawPayload?.originalBody || null,
      },
    });

    return {
      isMerged: false,
      transactionId: newTx.id,
      fingerprint,
      finalConfidence: 'confirmed',
      event,
    };
  }
}

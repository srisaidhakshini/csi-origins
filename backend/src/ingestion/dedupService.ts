import prisma from '../db/prisma';
import { CommonEvent, NodeConfidence } from './types';
import { generateFingerprint, isFuzzyFingerprintMatch } from './fingerprint';

export interface IngestionDedupResult {
  isMerged: boolean;
  rawEventId: string;
  matchedEventId?: string;
  fingerprint: string;
  finalConfidence: NodeConfidence;
  event: CommonEvent;
}

export class DedupService {
  /**
   * Ingests a common event, evaluates fingerprinting, and merges or inserts into raw_events
   */
  public static async ingestAndDedup(event: CommonEvent): Promise<IngestionDedupResult> {
    const fingerprint = generateFingerprint(event.amount, event.merchant, event.timestamp);

    // Look back and forward ±48 hours
    const windowStart = new Date(event.timestamp.getTime() - 48 * 60 * 60 * 1000);
    const windowEnd = new Date(event.timestamp.getTime() + 48 * 60 * 60 * 1000);

    // Find candidate events in the same time window
    const candidates = await prisma.rawEvent.findMany({
      where: {
        userId: event.userId,
        createdAt: {
          gte: windowStart,
          lte: windowEnd,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    let matchedCandidate: any = null;

    // 1. Direct Fingerprint Match
    matchedCandidate = candidates.find(c => c.fingerprint === fingerprint);

    // 2. Fuzzy match across boundary window
    if (!matchedCandidate) {
      for (const candidate of candidates) {
        if (candidate.matchedEventId) continue; // Skip already merged secondary events

        const candidatePayload = (typeof candidate.rawPayload === 'string'
          ? JSON.parse(candidate.rawPayload)
          : candidate.rawPayload) as any;

        const candidateAmount = Number(candidatePayload?.amount) || 0;
        const candidateMerchant = String(candidatePayload?.merchant || candidatePayload?.originalSender || '');
        const candidateTime = new Date(candidate.createdAt);

        if (
          isFuzzyFingerprintMatch(
            { amount: event.amount, merchant: event.merchant, timestamp: event.timestamp },
            { amount: candidateAmount, merchant: candidateMerchant, timestamp: candidateTime }
          )
        ) {
          matchedCandidate = candidate;
          break;
        }
      }
    }

    if (matchedCandidate) {
      // MATCH FOUND: Merge and link
      const newRawEvent = await prisma.rawEvent.create({
        data: {
          userId: event.userId,
          source: event.source,
          fingerprint,
          matchedEventId: matchedCandidate.id,
          rawPayload: {
            ...event.rawPayload,
            amount: event.amount,
            merchant: event.merchant,
            type: event.type,
            category: event.category,
            mergedWith: matchedCandidate.id,
            mergedSource: matchedCandidate.source,
          },
          createdAt: event.timestamp,
        },
      });

      console.log(`🔗 [DEDUP MERGE] Event from ${event.source.toUpperCase()} merged with existing event (${matchedCandidate.source.toUpperCase()} - ${matchedCandidate.id}). Confidence upgraded to CONFIRMED.`);

      return {
        isMerged: true,
        rawEventId: newRawEvent.id,
        matchedEventId: matchedCandidate.id,
        fingerprint,
        finalConfidence: 'confirmed', // Corroborating sources upgrade confidence
        event,
      };
    }

    // NO MATCH: Insert new raw event
    const newRawEvent = await prisma.rawEvent.create({
      data: {
        userId: event.userId,
        source: event.source,
        fingerprint,
        rawPayload: {
          ...event.rawPayload,
          amount: event.amount,
          merchant: event.merchant,
          type: event.type,
          category: event.category,
        },
        createdAt: event.timestamp,
      },
    });

    const confidence: NodeConfidence = event.source === 'gmail' || event.source === 'manual' ? 'confirmed' : 'inferred';

    return {
      isMerged: false,
      rawEventId: newRawEvent.id,
      fingerprint,
      finalConfidence: confidence,
      event,
    };
  }
}

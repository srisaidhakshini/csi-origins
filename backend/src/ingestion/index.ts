import { CommonEvent, RawEmailPayload, RawSMSPayload } from './types';
import { parseSMS } from './smsParser';
import { parseGmailMessage } from './gmailParser';
import { pollGmailForUser } from './gmailClient';
import { DedupService, IngestionDedupResult } from './dedupService';
import { generateFingerprint, isFuzzyFingerprintMatch } from './fingerprint';

export class IngestionPipeline {
  /**
   * Process a single incoming SMS message
   */
  public static ingestSMS(payload: RawSMSPayload, userId: string): CommonEvent | null {
    return parseSMS(payload, userId);
  }

  /**
   * Process a single incoming Gmail message
   */
  public static ingestGmail(payload: RawEmailPayload, userId: string): CommonEvent | null {
    return parseGmailMessage(payload, userId);
  }

  /**
   * Ingest and deduplicate any CommonEvent against Postgres raw_events
   */
  public static async ingestAndDedup(event: CommonEvent): Promise<IngestionDedupResult> {
    return DedupService.ingestAndDedup(event);
  }

  /**
   * Ingest raw SMS with deduplication
   */
  public static async processSMSWithDedup(payload: RawSMSPayload, userId: string): Promise<IngestionDedupResult | null> {
    const parsed = parseSMS(payload, userId);
    if (!parsed) return null;
    return DedupService.ingestAndDedup(parsed);
  }

  /**
   * Ingest raw Gmail message with deduplication
   */
  public static async processGmailWithDedup(payload: RawEmailPayload, userId: string): Promise<IngestionDedupResult | null> {
    const parsed = parseGmailMessage(payload, userId);
    if (!parsed) return null;
    return DedupService.ingestAndDedup(parsed);
  }

  /**
   * Process manual entry as a common event
   */
  public static ingestManual(data: {
    userId: string;
    amount: number;
    merchant: string;
    type: 'credit' | 'debit';
    category?: string;
    timestamp?: Date;
    note?: string;
  }): CommonEvent {
    return {
      userId: data.userId,
      source: 'manual',
      amount: data.amount,
      merchant: data.merchant,
      type: data.type,
      timestamp: data.timestamp || new Date(),
      category: data.category || 'general',
      confidence: 'confirmed',
      rawPayload: {
        note: data.note || 'Manual user transaction entry',
        enteredAt: new Date().toISOString()
      }
    };
  }

  /**
   * Poll Gmail inbox for a user and extract all matching common events
   */
  public static async pollAndExtractGmailEvents(userId: string): Promise<CommonEvent[]> {
    const rawMessages = await pollGmailForUser(userId);
    const events: CommonEvent[] = [];

    for (const msg of rawMessages) {
      const parsed = parseGmailMessage(msg, userId);
      if (parsed) {
        events.push(parsed);
      }
    }

    return events;
  }
}

export { DedupService, generateFingerprint, isFuzzyFingerprintMatch };
export * from './types';

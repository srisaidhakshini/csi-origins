import crypto from 'crypto';
import { normalizeMerchant } from './smsParser';

export interface FingerprintParams {
  amount: number;
  merchant: string;
  timestamp: Date;
}

/**
 * Calculates a 48-hour time window bucket index
 */
export function getTimeWindowBucket(timestamp: Date, windowHours = 48): number {
  const windowMs = windowHours * 60 * 60 * 1000;
  return Math.floor(timestamp.getTime() / windowMs);
}

/**
 * Generates a deterministic fingerprint for deduplication.
 * Hash of (amount bucket, normalized merchant name, time window ±2 days).
 */
export function generateFingerprint(amount: number, merchant: string, timestamp: Date): string {
  const normalizedMerchant = normalizeMerchant(merchant)
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');

  // Exact amount bucket rounded to 2 decimal places
  const amountBucket = Math.round(amount * 100) / 100;

  // 48-hour time window bucket
  const windowBucket = getTimeWindowBucket(timestamp, 48);

  const rawKey = `${normalizedMerchant}:${amountBucket}:${windowBucket}`;
  const hash = crypto.createHash('sha256').update(rawKey).digest('hex').substring(0, 16);

  return `fp_${normalizedMerchant}_${amountBucket}_${hash}`;
}

/**
 * Checks if two events match within the ±2 day time window and identical normalized merchant/amount.
 */
export function isFuzzyFingerprintMatch(
  ev1: { amount: number; merchant: string; timestamp: Date },
  ev2: { amount: number; merchant: string; timestamp: Date }
): boolean {
  // 1. Amount match (exact or within ₹1 difference for rounding)
  const amountDiff = Math.abs(ev1.amount - ev2.amount);
  if (amountDiff > 1.0) {
    return false;
  }

  // 2. Normalized merchant match
  const norm1 = normalizeMerchant(ev1.merchant).toLowerCase().replace(/[^a-z0-9]/g, '');
  const norm2 = normalizeMerchant(ev2.merchant).toLowerCase().replace(/[^a-z0-9]/g, '');
  const merchantMatch = norm1 === norm2 || norm1.includes(norm2) || norm2.includes(norm1);
  if (!merchantMatch) {
    return false;
  }

  // 3. Time window check (±48 hours)
  const timeDiffMs = Math.abs(ev1.timestamp.getTime() - ev2.timestamp.getTime());
  const maxDiffMs = 48 * 60 * 60 * 1000; // 48 hours
  return timeDiffMs <= maxDiffMs;
}

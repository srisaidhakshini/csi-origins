import { CommonEvent, RawSMSPayload } from './types';
import { CashiroParserFactory } from './cashiro/cashiroParsers';

export function normalizeMerchant(raw: string): string {
  if (!raw) return 'Unknown Entity';

  let cleaned = raw.trim();

  // Remove common prefix tokens
  cleaned = cleaned.replace(/^(VPA|UPI|INFO|NEFT|IMPS|RTGS|POS|ACH|BIL|VPS|AT)\s*[-/:]?\s*/i, '');
  // Remove transaction IDs, trailing reference numbers
  cleaned = cleaned.replace(/[0-9]{8,}/g, '');
  cleaned = cleaned.replace(/\bRef\s*#?[A-Z0-9]+\b/gi, '');
  // Clean whitespace and special characters
  cleaned = cleaned.replace(/[*_#]+/g, ' ').replace(/\s+/g, ' ').trim();

  // Match known recognizable merchants / categories
  const lower = cleaned.toLowerCase();
  if (lower.includes('skyline') || lower.includes('rent') || lower.includes('landlord')) return 'Skyline Properties';
  if (lower.includes('techcorp')) return 'TechCorp Labs';
  if (lower.includes('upwork')) return 'Upwork Global';
  if (lower.includes('swiggy') || lower.includes('bundl')) return 'Swiggy';
  if (lower.includes('zomato')) return 'Zomato';
  if (lower.includes('amazon') || lower.includes('amzn')) return 'Amazon';
  if (lower.includes('flipkart')) return 'Flipkart';
  if (lower.includes('uber')) return 'Uber';
  if (lower.includes('ola')) return 'Ola';
  if (lower.includes('bse star') || lower.includes('mf') || lower.includes('sip') || lower.includes('ppfas')) return 'BSE Star MF (SIP)';
  if (lower.includes('act fiber') || lower.includes('broadband') || lower.includes('airtel') || lower.includes('jio')) return 'Broadband / Utilities';
  if (lower.includes('bescom') || lower.includes('tneb') || lower.includes('electricity')) return 'Electricity Board';

  return cleaned.length > 2 ? cleaned : 'Merchant';
}

export function inferCategory(merchant: string, text: string): string {
  const combined = (merchant + ' ' + text).toLowerCase();
  if (combined.includes('rent') || combined.includes('skyline') || combined.includes('housing')) return 'housing';
  if (combined.includes('sip') || combined.includes('mf') || combined.includes('mutual fund') || combined.includes('bse') || combined.includes('zerodha') || combined.includes('groww')) return 'investment';
  if (combined.includes('techcorp') || combined.includes('upwork') || combined.includes('retainer') || combined.includes('salary') || combined.includes('freelance') || combined.includes('payout')) return 'income';
  if (combined.includes('swiggy') || combined.includes('zomato') || combined.includes('restaurant') || combined.includes('dining') || combined.includes('cafe')) return 'food_dining';
  if (combined.includes('uber') || combined.includes('ola') || combined.includes('metro') || combined.includes('fuel') || combined.includes('petrol')) return 'transportation';
  if (combined.includes('amazon') || combined.includes('flipkart') || combined.includes('myntra')) return 'shopping';
  if (combined.includes('electricity') || combined.includes('broadband') || combined.includes('wifi') || combined.includes('airtel') || combined.includes('bescom')) return 'utilities';
  return 'general';
}

/**
 * Parses financial SMS text using ported Cashiro Kotlin Pattern Parsers
 */
export function parseSMS(payload: RawSMSPayload, userId: string): CommonEvent | null {
  const body = payload.body || '';
  const sender = payload.sender || '';
  if (!body) return null;

  // Use Cashiro Bank Parser Factory
  const parsed = CashiroParserFactory.parse(sender, body);
  if (!parsed) return null;

  let timestamp = new Date();
  if (payload.timestamp) {
    const parsedTime = new Date(payload.timestamp);
    if (!isNaN(parsedTime.getTime())) {
      timestamp = parsedTime;
    }
  }

  return {
    userId,
    source: 'sms',
    amount: parsed.amount,
    merchant: parsed.merchant,
    type: parsed.type,
    timestamp,
    category: parsed.category,
    confidence: 'inferred',
    rawPayload: {
      amount: parsed.amount,
      merchant: parsed.merchant,
      type: parsed.type,
      category: parsed.category,
      accountNumber: parsed.accountNumber,
      referenceNumber: parsed.referenceNumber,
      balance: parsed.balance,
      bankName: parsed.bankName,
      originalSender: payload.sender,
      originalBody: payload.body,
      parsedAt: new Date().toISOString()
    }
  };
}

import { CommonEvent, RawSMSPayload } from './types';

/**
 * Normalizes merchant names from SMS text strings.
 */
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

/**
 * Infer spending category based on merchant and description
 */
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
 * Parses financial SMS text into a standardized CommonEvent
 */
export function parseSMS(payload: RawSMSPayload, userId: string): CommonEvent | null {
  const body = payload.body || '';
  if (!body) return null;

  // 1. Detect transaction type (credit vs debit)
  const isCredit = /(?:credited|received|deposited|added to|refunded|payout of)\b/i.test(body);
  const isDebit = /(?:debited|spent|sent|paid|transferred to|withdrawn|charged)\b/i.test(body);

  if (!isCredit && !isDebit) {
    return null; // Not a financial transaction SMS
  }
  const type: 'credit' | 'debit' = isCredit ? 'credit' : 'debit';

  // 2. Extract amount (Rs. / INR / Rs / ₹)
  const amountRegex = /(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)/i;
  const matchAmount = body.match(amountRegex);
  if (!matchAmount) return null;

  const rawAmountStr = matchAmount[1].replace(/,/g, '');
  const amount = parseFloat(rawAmountStr);
  if (isNaN(amount) || amount <= 0) return null;

  // 3. Extract Merchant / Beneficiary / Payer
  let rawMerchant = '';
  const toMatch = body.match(/(?:to|at|info\/|towards|vpa|paid to)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|using|avail|bal|avbl|avl|dated|\.|\n|$))/i);
  const fromMatch = body.match(/(?:from|by|payout by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|using|avail|bal|avbl|avl|dated|\.|\n|$))/i);

  if (type === 'credit' && fromMatch) {
    rawMerchant = fromMatch[1];
  } else if (toMatch) {
    rawMerchant = toMatch[1];
  } else if (fromMatch) {
    rawMerchant = fromMatch[1];
  } else {
    // Fallback: search for words after common bank phrases
    rawMerchant = payload.sender || 'Banking Transaction';
  }

  const merchant = normalizeMerchant(rawMerchant);
  const category = inferCategory(merchant, body);

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
    amount,
    merchant,
    type,
    timestamp,
    category,
    confidence: 'inferred',
    rawPayload: {
      amount,
      merchant,
      type,
      category,
      originalSender: payload.sender,
      originalBody: payload.body,
      parsedAt: new Date().toISOString()
    }
  };
}

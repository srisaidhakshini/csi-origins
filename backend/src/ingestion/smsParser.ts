import { CommonEvent, RawSMSPayload } from './types';
import { CashiroParserFactory } from './cashiro/cashiroParsers';

/**
 * Dynamically sanitizes and formats real merchant / beneficiary names extracted from SMS
 */
export function normalizeMerchant(raw: string): string {
  if (!raw) return 'Merchant';

  let cleaned = raw.trim();

  // 1. Remove common banking routing & protocol leading tokens repeatedly
  let previous = '';
  while (previous !== cleaned) {
    previous = cleaned;
    cleaned = cleaned.replace(/^(?:VPA|UPI|INFO|NEFT|IMPS|RTGS|POS|ACH|BIL|VPS|AT|TRANSFER\s*TO|PAYMENT\s*TO|PAID\s*TO|TO|FROM|BY)\s*[-/:]?\s*/i, '').trim();
  }
  
  // 2. Clean UPI IDs / VPA handles (e.g. "zomato@icici" -> "Zomato", "merchant.pay@okhdfc" -> "Merchant Pay")
  if (cleaned.includes('@')) {
    cleaned = cleaned.split('@')[0].replace(/[._-]+/g, ' ');
  }

  // 3. Remove trailing routing words, reference numbers, or transaction metadata
  cleaned = cleaned.replace(/\b(?:on|via|ref|using|avbl|avl|bal|balance|total\s*bal|dated|upi\s*ref|upi)\b.*$/i, '');
  cleaned = cleaned.replace(/[0-9]{6,}/g, '');
  cleaned = cleaned.replace(/\bRef\s*#?[A-Za-z0-9]+\b/gi, '');

  // 4. Clean special characters, asterisks, trailing periods/commas, and excessive whitespace
  cleaned = cleaned.replace(/[*_#\/\\:;]+/g, ' ');
  cleaned = cleaned.replace(/[.,;]+$/g, '');
  cleaned = cleaned.replace(/\s+[.,;]+\s+/g, ' ');
  cleaned = cleaned.replace(/\s+/g, ' ').trim();

  if (cleaned.length < 2) {
    return 'Merchant';
  }

  // 5. Convert to clean Title Case
  return cleaned
    .split(' ')
    .filter(w => w.length > 0)
    .map(w => {
      const cleanW = w.replace(/^[.,;]+|[.,;]+$/g, '');
      if (cleanW.length === 0) return '';
      // Preserve uppercase abbreviations (e.g. MF, SIP, ACT, PNB, SBI, HDFC)
      if (cleanW.length <= 3 && cleanW === cleanW.toUpperCase()) {
        return cleanW;
      }
      return cleanW.charAt(0).toUpperCase() + cleanW.slice(1).toLowerCase();
    })
    .filter(w => w.length > 0)
    .join(' ');
}

/**
 * Dynamically infers standard financial category from merchant text & SMS body context
 */
export function inferCategory(merchant: string, text: string): string {
  const combined = (merchant + ' ' + text).toLowerCase();

  // Housing, Rent & Real Estate
  if (combined.includes('rent') || combined.includes('housing') || combined.includes('landlord') || combined.includes('flat') || combined.includes('maintenance') || combined.includes('pg fee') || combined.includes('lease') || combined.includes('properties') || combined.includes('realty') || combined.includes('estate') || combined.includes('society')) {
    return 'housing';
  }

  // Investments, Mutual Funds & Stocks
  if (combined.includes('sip') || combined.includes('mutual fund') || combined.includes('mf') || combined.includes('bse') || combined.includes('nse') || combined.includes('zerodha') || combined.includes('groww') || combined.includes('stock') || combined.includes('sebi') || combined.includes('deposit') || combined.includes('ppf') || combined.includes('nps') || combined.includes('wealth')) {
    return 'investment';
  }

  // Income, Salary & Gig Payouts
  if (combined.includes('salary') || combined.includes('payout') || combined.includes('payroll') || combined.includes('retainer') || combined.includes('freelance') || combined.includes('upwork') || combined.includes('fiverr') || combined.includes('stipend') || combined.includes('dividend') || combined.includes('refund')) {
    return 'income';
  }

  // Quick Commerce & Groceries
  if (combined.includes('blinkit') || combined.includes('zepto') || combined.includes('instamart') || combined.includes('bigbasket') || combined.includes('grocery') || combined.includes('supermarket') || combined.includes('dmart') || combined.includes('nature basket') || combined.includes('spencer')) {
    return 'groceries';
  }

  // Food & Dining
  if (combined.includes('swiggy') || combined.includes('zomato') || combined.includes('restaurant') || combined.includes('dining') || combined.includes('cafe') || combined.includes('starbucks') || combined.includes('pizza') || combined.includes('bakery') || combined.includes('eats') || combined.includes('food')) {
    return 'food_dining';
  }

  // Transportation & Commute
  if (combined.includes('uber') || combined.includes('ola') || combined.includes('metro') || combined.includes('fuel') || combined.includes('petrol') || combined.includes('diesel') || combined.includes('rapido') || combined.includes('flight') || combined.includes('airline') || combined.includes('irctc') || combined.includes('train') || combined.includes('fastag') || combined.includes('toll')) {
    return 'transportation';
  }

  // Entertainment & Subscriptions
  if (combined.includes('netflix') || combined.includes('spotify') || combined.includes('prime') || combined.includes('hotstar') || combined.includes('youtube') || combined.includes('subscription') || combined.includes('cinema') || combined.includes('bookmyshow') || combined.includes('gaming')) {
    return 'entertainment';
  }

  // Shopping & E-Commerce
  if (combined.includes('amazon') || combined.includes('flipkart') || combined.includes('myntra') || combined.includes('apple') || combined.includes('google') || combined.includes('store') || combined.includes('retail') || combined.includes('mall') || combined.includes('clothing') || combined.includes('fashion') || combined.includes('shop')) {
    return 'shopping';
  }

  // Utilities & Broadband
  if (combined.includes('electricity') || combined.includes('power') || combined.includes('broadband') || combined.includes('fiber') || combined.includes('fibernet') || combined.includes('wifi') || combined.includes('airtel') || combined.includes('jio') || combined.includes('vi ') || combined.includes('water') || combined.includes('gas') || combined.includes('cylinder') || combined.includes('bill desk') || combined.includes('bbps') || combined.includes('telecom')) {
    return 'utilities';
  }

  return 'general';
}

/**
 * Parses real financial SMS text using Cashiro Pattern Engine
 */
export function parseSMS(payload: RawSMSPayload, userId: string): CommonEvent | null {
  const body = payload.body || '';
  const sender = payload.sender || '';
  if (!body) return null;

  // Use Cashiro Bank Parser Factory (with dynamic OTP / spam pre-filter)
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
      currency: parsed.currency || 'INR',
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

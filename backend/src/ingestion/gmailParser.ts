import { CommonEvent, RawEmailPayload } from './types';
import { normalizeMerchant, inferCategory } from './smsParser';

/**
 * Scoped deterministic Gmail parser for 3 primary financial formats:
 * Format 1: Bank Transaction / E-statement Notification (e.g. HDFC / ICICI / SBI)
 * Format 2: Gig Payout Alert (e.g. Upwork / Freelance Client / Stripe)
 * Format 3: Merchant Receipt / Utility Bill (e.g. Swiggy / Broadband / Rent Receipt)
 */
export function parseGmailMessage(payload: RawEmailPayload, userId: string): CommonEvent | null {
  const subject = payload.subject || '';
  const body = payload.body || payload.snippet || '';
  const fullText = `${subject}\n${body}`;

  // Determine transaction type
  const isCredit = /(?:credit alert|payment received|payout processed|payment processed|amount credited|credited to|funds transferred to|payment sent to you|deposit confirmed|earnings withdrawal|salary credited)\b/i.test(fullText);
  const isDebit = /(?:debit alert|transaction alert|payment receipt|bill payment|bill paid|debited from|debited for|charge confirmed|order confirmation|spent on|withdrawn from)\b/i.test(fullText);

  let type: 'credit' | 'debit';
  if (isCredit && !isDebit) {
    type = 'credit';
  } else if (isDebit && !isCredit) {
    type = 'debit';
  } else if (isCredit && isDebit) {
    // Disambiguate based on keywords in subject or body
    if (/(?:payout|retainer|earnings|credited|deposit|received)/i.test(subject)) {
      type = 'credit';
    } else {
      type = 'debit';
    }
  } else {
    // Default fallback based on subject
    if (/(?:payout|salary|retainer|deposit|received)/i.test(subject)) {
      type = 'credit';
    } else {
      type = 'debit';
    }
  }

  // 1. Extract Amount
  // Matches: INR 35,000.00 | Rs. 28,000.00 | ₹12,000 | USD 450.00 (INR 37,350) | $500
  let amount = 0;
  const inrMatch = fullText.match(/(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)/i);
  if (inrMatch) {
    amount = parseFloat(inrMatch[1].replace(/,/g, ''));
  } else {
    const usdMatch = fullText.match(/\$\s*([\d,]+(?:\.\d{1,2})?)/);
    if (usdMatch) {
      // Convert USD approx for gig platforms if INR isn't mentioned
      const usdVal = parseFloat(usdMatch[1].replace(/,/g, ''));
      amount = Math.round(usdVal * 83); // Standard USD-INR conversion factor
    }
  }

  if (isNaN(amount) || amount <= 0) {
    return null;
  }

  // 2. Extract Merchant / Entity based on known Scoped Formats
  let rawMerchant = '';

  // Format 2: Gig Payout Alert (Upwork / TechCorp / Stripe)
  if (/upwork/i.test(payload.sender) || /upwork/i.test(subject) || /upwork/i.test(body)) {
    rawMerchant = 'Upwork Global';
  } else if (/techcorp/i.test(subject) || /techcorp/i.test(body) || /techcorp/i.test(payload.sender)) {
    rawMerchant = 'TechCorp Labs';
  }
  // Format 3: Merchant Receipt / Utility
  else if (/swiggy|bundl/i.test(payload.sender) || /swiggy/i.test(subject)) {
    rawMerchant = 'Swiggy';
  } else if (/zomato/i.test(payload.sender) || /zomato/i.test(subject)) {
    rawMerchant = 'Zomato';
  } else if (/skyline|rent/i.test(subject) || /skyline/i.test(body)) {
    rawMerchant = 'Skyline Properties';
  } else if (/bse|mf|mutual fund|ppfas/i.test(subject) || /bse|ppfas/i.test(body)) {
    rawMerchant = 'BSE Star MF (SIP)';
  } else if (/act fibernet|airtel|broadband/i.test(subject) || /broadband/i.test(body)) {
    rawMerchant = 'Broadband / Utilities';
  }
  // Format 1: Bank Transaction / E-statement Alert (Extract from text)
  else {
    const toMatch = fullText.match(/(?:towards|to merchant|paid to|beneficiary|info\/|at)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|dated|ref|using|a\/c|\.|\n|$))/i);
    const fromMatch = fullText.match(/(?:from|by sender|received from|payer)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|dated|ref|using|a\/c|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else if (fromMatch) {
      rawMerchant = fromMatch[1];
    } else {
      rawMerchant = payload.sender.split('<')[0].replace(/"/g, '').trim() || 'Bank Notification';
    }
  }

  const merchant = normalizeMerchant(rawMerchant);
  const category = inferCategory(merchant, fullText);

  let timestamp = new Date();
  if (payload.date) {
    const parsedTime = new Date(payload.date);
    if (!isNaN(parsedTime.getTime())) {
      timestamp = parsedTime;
    }
  }

  return {
    id: payload.id,
    userId,
    source: 'gmail',
    amount,
    merchant,
    type,
    timestamp,
    category,
    confidence: 'confirmed', // Gmail receipts / statements have high ground truth confidence
    rawPayload: {
      messageId: payload.id,
      subject: payload.subject,
      sender: payload.sender,
      date: payload.date,
      snippet: payload.snippet || body.substring(0, 150),
      parsedAt: new Date().toISOString()
    }
  };
}

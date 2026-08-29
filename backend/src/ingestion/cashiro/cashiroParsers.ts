import { BankParser, CashiroParsedTransaction, CashiroTransactionType } from './types';
import { inferCategory, normalizeMerchant } from '../smsParser';

/**
 * Common utility extractors ported and extended from Cashiro parser-core
 */
export class CashiroExtractors {
  // Amount pattern supporting multi-currency: INR, Rs., ₹, USD, $, EUR, €, GBP, £, SGD, S$, AED
  private static MULTI_CURRENCY_REGEX = /(?:(INR|Rs\.?|₹|USD|\$|EUR|€|GBP|£|SGD|S\$|AED))\s*([\d,]+(?:\.\d{1,2})?)/i;
  private static FALLBACK_AMOUNT_REGEX = /([\d,]+(?:\.\d{1,2})?)\s*(?:(INR|Rs\.?|₹|USD|\$|EUR|€|GBP|£|SGD|S\$|AED))\b/i;

  // Account / Card number ending digits
  private static ACC_REGEX = /(?:A\/C|A\/c|Account|Card|Acct|Acc)\s*(?:no\.?|ending|is|ending with)?\s*[*xX]*([0-9]{3,6})/i;

  // Available balance
  private static BAL_REGEX = /(?:Avail(?:able)?\s*Bal(?:ance)?|Bal(?:ance)?|Avl\s*Bal|Balance)\s*(?:is|:)?\s*(?:INR|Rs\.?|₹|USD|\$|EUR|€|GBP|£|SGD|S\$|AED)?\s*([\d,]+(?:\.\d{1,2})?)/i;

  // Reference number / UTR / Txn ID
  private static REF_REGEX = /(?:Ref\s*(?:no\.?|#)?|UPI\s*ref\s*(?:no\.?)?|UTR|Txn\s*ID|Txn\s*#|IMPS\s*Ref)\s*([A-Za-z0-9]+)/i;

  // Dedicated OTP and Spam indicators
  private static OTP_REGEX = /\b(?:OTP|one[- ]time[- ]password|verification[- ]code|secret[- ]code|login[- ]code|security[- ]code|is your verification|do not share|never share)\b/i;
  private static PROMO_SPAM_REGEX = /\b(?:pre[- ]approved|instant[- ]loan|apply[- ]now|click[- ]here|congratulations|claim[- ]your|exclusive[- ]offer|hurry|call[- ]now)\b/i;
  private static BALANCE_QUERY_ONLY_REGEX = /^(?:your\s+)?(?:avail(?:able)?\s+)?bal(?:ance)?\s+(?:for|of|is)\b/i;

  /**
   * Pre-filter: Detects OTPs, non-transactional messages, and promotional spam
   */
  public static isNonFinancialOrOtp(text: string): boolean {
    if (!text) return true;

    // Check for OTPs
    if (this.OTP_REGEX.test(text)) {
      return true;
    }

    // Check for marketing spam without actual transactional debit/credit
    if (this.PROMO_SPAM_REGEX.test(text) && !this.detectType(text)) {
      return true;
    }

    // Check balance inquiry messages that don't involve an actual transaction debit or credit
    if (this.BALANCE_QUERY_ONLY_REGEX.test(text.trim()) && !/(?:debited|credited|spent|withdrawn|deposited|paid|received)/i.test(text)) {
      return true;
    }

    return false;
  }

  /**
   * Extracts amount and canonical currency code
   */
  public static extractAmountWithCurrency(text: string): { amount: number; currency: string } | null {
    let match = text.match(this.MULTI_CURRENCY_REGEX);
    let rawCurrency = '';
    let rawAmount = '';

    if (match) {
      rawCurrency = match[1];
      rawAmount = match[2];
    } else {
      match = text.match(this.FALLBACK_AMOUNT_REGEX);
      if (match) {
        rawAmount = match[1];
        rawCurrency = match[2];
      }
    }

    if (!match || !rawAmount) return null;

    const amount = parseFloat(rawAmount.replace(/,/g, ''));
    if (isNaN(amount) || amount <= 0) return null;

    let currency = 'INR';
    const c = (rawCurrency || '').toUpperCase();
    if (c === '$' || c === 'USD') currency = 'USD';
    else if (c === '€' || c === 'EUR') currency = 'EUR';
    else if (c === '£' || c === 'GBP') currency = 'GBP';
    else if (c === 'S$' || c === 'SGD') currency = 'SGD';
    else if (c === 'AED') currency = 'AED';
    else if (c.includes('RS') || c === '₹' || c === 'INR') currency = 'INR';

    return { amount, currency };
  }

  public static extractAmount(text: string): number | null {
    const res = this.extractAmountWithCurrency(text);
    return res ? res.amount : null;
  }

  public static extractAccount(text: string): string | undefined {
    const match = text.match(this.ACC_REGEX);
    return match ? match[1] : undefined;
  }

  public static extractBalance(text: string): number | undefined {
    const match = text.match(this.BAL_REGEX);
    if (!match) return undefined;
    const bal = parseFloat(match[1].replace(/,/g, ''));
    return isNaN(bal) ? undefined : bal;
  }

  public static extractReference(text: string): string | undefined {
    const match = text.match(this.REF_REGEX);
    return match ? match[1] : undefined;
  }

  public static detectType(text: string): CashiroTransactionType | null {
    const isCredit = /(?:credited|received|deposited|added to|refunded|payout of|cashback|salary credited)\b/i.test(text);
    const isDebit = /(?:debited|spent|sent|paid|transferred to|withdrawn|charged|purchase of|txn of|payment of|transaction of)\b/i.test(text);

    if (isCredit && !isDebit) return 'credit';
    if (isDebit && !isCredit) return 'debit';
    if (isCredit && isDebit) {
      if (/(?:payout|credited|received|refund|salary)/i.test(text)) return 'credit';
      return 'debit';
    }
    return null;
  }
}

/**
 * HDFC Bank SMS Parser (Ported from Cashiro HdfcParser.kt)
 */
export class HdfcBankParser implements BankParser {
  public bankName = 'HDFC Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('HDFC') || s.includes('HDFCBK') || /hdfc bank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

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
      rawMerchant = 'HDFC Transaction';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * ICICI Bank SMS Parser (Ported from Cashiro IciciParser.kt)
 */
export class IciciBankParser implements BankParser {
  public bankName = 'ICICI Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('ICICI') || s.includes('ICICIB') || /icici bank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:to|at|towards|info\/|paid to)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|using|avail|bal|avl|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|credited by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|using|avail|bal|avl|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'ICICI Beneficiary';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * State Bank of India SMS Parser (Ported from Cashiro SbiParser.kt)
 */
export class SbiBankParser implements BankParser {
  public bankName = 'State Bank of India';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('SBI') || s.includes('SBIINB') || s.includes('SBIPAY') || /sbi/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:transfer to|to|towards|vpa|paid to)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);
    const fromMatch = body.match(/(?:credited by|from)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'SBI Transfer';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Axis Bank SMS Parser (Ported from Cashiro AxisParser.kt)
 */
export class AxisBankParser implements BankParser {
  public bankName = 'Axis Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('AXIS') || s.includes('AXISBK') || /axis bank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:towards|to|at|info\/)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'Axis Transaction';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Kotak Mahindra Bank SMS Parser
 */
export class KotakBankParser implements BankParser {
  public bankName = 'Kotak Mahindra Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('KOTAK') || s.includes('KOTAKB') || s.includes('KMB') || /kotak bank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:to|towards|at|paid to)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|avbl|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|credited by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'Kotak Payee';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Punjab National Bank (PNB) SMS Parser
 */
export class PnbBankParser implements BankParser {
  public bankName = 'Punjab National Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('PNBSMS') || s.includes('PUNJAB') || s.includes('PNB') || /pnb/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:to|towards|at|paid to)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|credited by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'PNB Beneficiary';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Canara Bank SMS Parser
 */
export class CanaraBankParser implements BankParser {
  public bankName = 'Canara Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('CANBNK') || s.includes('CANARA') || s.includes('CNRB') || /canara bank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:to|towards|at)\s+([A-Za-z0-9\s_\-@&]+?)(?:\s+(?:on|via|ref|bal|total|\.|\n|$)|[.,;\n]|$)/i);
    const fromMatch = body.match(/(?:from|by)\s+([A-Za-z0-9\s_\-@&]+?)(?:\s+(?:on|via|ref|bal|total|\.|\n|$)|[.,;\n]|$)/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'Canara Payee';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * IndusInd Bank SMS Parser
 */
export class IndusIndBankParser implements BankParser {
  public bankName = 'IndusInd Bank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('INDUSB') || s.includes('INDUSIND') || /indusind/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:at|to|towards)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'IndusInd Transaction';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Union Bank of India SMS Parser
 */
export class UnionBankParser implements BankParser {
  public bankName = 'Union Bank of India';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('UNIONB') || s.includes('UBIN') || /union bank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:towards|to|at)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|bal|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'Union Bank Payee';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Standard Chartered Bank SMS Parser
 */
export class StanChartParser implements BankParser {
  public bankName = 'Standard Chartered';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('SCISMS') || s.includes('SCBL') || s.includes('SCBANK') || /stanchart|standard chartered/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:at|to|towards)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'Standard Chartered Payee';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Citibank SMS Parser
 */
export class CitiBankParser implements BankParser {
  public bankName = 'Citibank';

  public canParse(sender: string, body: string): boolean {
    const s = sender.toUpperCase();
    return s.includes('CITIBK') || s.includes('CITI') || /citibank/i.test(body);
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:at|to|towards)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else {
      rawMerchant = 'Citibank Merchant';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Generic Bank / Multi-pattern fallback (Ported from Cashiro GenericBankParser.kt)
 */
export class GenericBankParser implements BankParser {
  public bankName = 'Banking Transaction';

  public canParse(_sender: string, _body: string): boolean {
    return true; // Universal fallback
  }

  public parse(sender: string, body: string): CashiroParsedTransaction | null {
    const type = CashiroExtractors.detectType(body);
    const extracted = CashiroExtractors.extractAmountWithCurrency(body);
    if (!type || !extracted) return null;

    let rawMerchant = '';
    const toMatch = body.match(/(?:to|at|towards|vpa|paid to|info\/)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|using|bal|avail|\.|\n|$))/i);
    const fromMatch = body.match(/(?:from|by|credited by|payout by)\s+([A-Za-z0-9\s._\-@&]+?)(?:\s+(?:on|via|ref|using|bal|avail|\.|\n|$))/i);

    if (type === 'credit' && fromMatch) {
      rawMerchant = fromMatch[1];
    } else if (toMatch) {
      rawMerchant = toMatch[1];
    } else if (fromMatch) {
      rawMerchant = fromMatch[1];
    } else {
      rawMerchant = sender.replace(/^[A-Z]{2}-/i, '') || 'Merchant';
    }

    const merchant = normalizeMerchant(rawMerchant);
    const category = inferCategory(merchant, body);

    return {
      amount: extracted.amount,
      currency: extracted.currency,
      type,
      merchant,
      accountNumber: CashiroExtractors.extractAccount(body),
      referenceNumber: CashiroExtractors.extractReference(body),
      balance: CashiroExtractors.extractBalance(body),
      category,
      bankName: this.bankName,
      rawBody: body,
    };
  }
}

/**
 * Cashiro Parser Factory: Dispatches incoming SMS to bank-specific parser or generic fallback
 */
export class CashiroParserFactory {
  private static parsers: BankParser[] = [
    new HdfcBankParser(),
    new IciciBankParser(),
    new SbiBankParser(),
    new AxisBankParser(),
    new KotakBankParser(),
    new PnbBankParser(),
    new CanaraBankParser(),
    new IndusIndBankParser(),
    new UnionBankParser(),
    new StanChartParser(),
    new CitiBankParser(),
    new GenericBankParser(),
  ];

  public static parse(sender: string, body: string): CashiroParsedTransaction | null {
    // 1. Upfront OTP and Spam Pre-Filter
    if (CashiroExtractors.isNonFinancialOrOtp(body)) {
      return null;
    }

    // 2. Bank Parser Dispatch
    for (const parser of this.parsers) {
      if (parser.canParse(sender, body)) {
        const result = parser.parse(sender, body);
        if (result) {
          return result;
        }
      }
    }
    return null;
  }
}

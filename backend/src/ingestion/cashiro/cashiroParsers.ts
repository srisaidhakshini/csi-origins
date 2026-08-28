import { BankParser, CashiroParsedTransaction, CashiroTransactionType } from './types';
import { inferCategory, normalizeMerchant } from '../smsParser';

/**
 * Common utility extractors ported from Cashiro parser-core
 */
export class CashiroExtractors {
  // Amount pattern supporting Rs., INR, ₹ with comma/decimal notation
  private static AMOUNT_REGEX = /(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)/i;

  // Account / Card number ending digits
  private static ACC_REGEX = /(?:A\/C|A\/c|Account|Card|Acct)\s*(?:no\.?|ending|is|ending with)?\s*[*xX]*([0-9]{3,6})/i;

  // Available balance
  private static BAL_REGEX = /(?:Avail(?:able)?\s*Bal(?:ance)?|Bal(?:ance)?|Avl\s*Bal|Balance)\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)/i;

  // Reference number / UTR / Txn ID
  private static REF_REGEX = /(?:Ref\s*(?:no\.?|#)?|UPI\s*ref\s*(?:no\.?)?|UTR|Txn\s*ID|Txn\s*#)\s*([A-Za-z0-9]+)/i;

  public static extractAmount(text: string): number | null {
    const match = text.match(this.AMOUNT_REGEX);
    if (!match) return null;
    const amount = parseFloat(match[1].replace(/,/g, ''));
    return isNaN(amount) || amount <= 0 ? null : amount;
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
    const isCredit = /(?:credited|received|deposited|added to|refunded|payout of|cashback)\b/i.test(text);
    const isDebit = /(?:debited|spent|sent|paid|transferred to|withdrawn|charged|purchase of)\b/i.test(text);

    if (isCredit && !isDebit) return 'credit';
    if (isDebit && !isCredit) return 'debit';
    if (isCredit && isDebit) {
      if (/(?:payout|credited|received|refund)/i.test(text)) return 'credit';
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
    const amount = CashiroExtractors.extractAmount(body);
    if (!type || !amount) return null;

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
      amount,
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
    const amount = CashiroExtractors.extractAmount(body);
    if (!type || !amount) return null;

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
      amount,
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
    const amount = CashiroExtractors.extractAmount(body);
    if (!type || !amount) return null;

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
      amount,
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
    const amount = CashiroExtractors.extractAmount(body);
    if (!type || !amount) return null;

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
      amount,
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
    const amount = CashiroExtractors.extractAmount(body);
    if (!type || !amount) return null;

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
      amount,
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
    new GenericBankParser(),
  ];

  public static parse(sender: string, body: string): CashiroParsedTransaction | null {
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

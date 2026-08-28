export type CashiroTransactionType = 'credit' | 'debit';

export interface CashiroParsedTransaction {
  amount: number;
  currency?: string;
  type: CashiroTransactionType;
  merchant: string;
  accountNumber?: string;
  referenceNumber?: string;
  balance?: number;
  category: string;
  bankName: string;
  rawBody: string;
  isOtp?: boolean;
}

export interface BankParser {
  bankName: string;
  canParse(sender: string, body: string): boolean;
  parse(sender: string, body: string): CashiroParsedTransaction | null;
}

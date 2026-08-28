export type CashiroTransactionType = 'credit' | 'debit';

export interface CashiroParsedTransaction {
  amount: number;
  type: CashiroTransactionType;
  merchant: string;
  accountNumber?: string;
  referenceNumber?: string;
  balance?: number;
  category: string;
  bankName: string;
  rawBody: string;
}

export interface BankParser {
  bankName: string;
  canParse(sender: string, body: string): boolean;
  parse(sender: string, body: string): CashiroParsedTransaction | null;
}

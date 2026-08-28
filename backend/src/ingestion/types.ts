export type EventSource = 'sms' | 'gmail' | 'manual';
export type TransactionType = 'credit' | 'debit';
export type NodeConfidence = 'confirmed' | 'inferred' | 'predicted';

export interface CommonEvent {
  id?: string;
  userId: string;
  source: EventSource;
  amount: number;
  merchant: string;
  type: TransactionType;
  timestamp: Date;
  category?: string;
  confidence?: NodeConfidence;
  rawPayload: Record<string, any>;
}

export interface RawEmailPayload {
  id: string;
  threadId?: string;
  subject: string;
  sender: string;
  body: string;
  snippet?: string;
  date: string | Date;
}

export interface RawSMSPayload {
  sender: string;
  body: string;
  timestamp?: string | number | Date;
}

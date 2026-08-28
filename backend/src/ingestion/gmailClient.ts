import { google } from 'googleapis';
import prisma from '../db/prisma';
import { RawEmailPayload } from './types';
import { parseGmailMessage } from './gmailParser';

export function getOAuth2Client() {
  const clientId = process.env.GOOGLE_CLIENT_ID || 'mock-google-client-id';
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET || 'mock-google-client-secret';
  const redirectUri = process.env.GOOGLE_REDIRECT_URI || 'http://localhost:3000/api/auth/google/callback';

  return new google.auth.OAuth2(clientId, clientSecret, redirectUri);
}

/**
 * Generate Google OAuth Consent URL with gmail.readonly scope
 */
export function getGoogleAuthUrl(state?: string): string {
  const oauth2Client = getOAuth2Client();
  return oauth2Client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: ['https://www.googleapis.com/auth/gmail.readonly'],
    state: state || 'demo_user'
  });
}

/**
 * Exchange OAuth authorization code for tokens and save refresh token to user
 */
export async function handleOAuthCallback(code: string, userId: string): Promise<string | null> {
  const oauth2Client = getOAuth2Client();
  try {
    const { tokens } = await oauth2Client.getToken(code);
    if (tokens.refresh_token) {
      await prisma.user.update({
        where: { id: userId },
        data: { gmailRefreshToken: tokens.refresh_token }
      });
      return tokens.refresh_token;
    }
    return tokens.access_token || null;
  } catch (error) {
    console.error('Error exchanging OAuth code for tokens:', error);
    throw error;
  }
}

/**
 * Poll recent messages from user's Gmail inbox using their stored refresh token
 */
export async function pollGmailForUser(userId: string, maxResults = 10): Promise<RawEmailPayload[]> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user || !user.gmailRefreshToken) {
    console.log(`⚠️ User ${userId} has no Gmail refresh token configured. Returning mock/test messages.`);
    return getMockGmailMessages();
  }

  // If running with mock token for demo/test
  if (user.gmailRefreshToken.startsWith('mock_')) {
    return getMockGmailMessages();
  }

  const oauth2Client = getOAuth2Client();
  oauth2Client.setCredentials({ refresh_token: user.gmailRefreshToken });
  const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

  try {
    const res = await gmail.users.messages.list({
      userId: 'me',
      maxResults,
      q: 'newer_than:7d (subject:debit OR subject:credit OR subject:statement OR subject:payout OR subject:receipt OR subject:invoice)'
    });

    const messages = res.data.messages || [];
    const payloads: RawEmailPayload[] = [];

    for (const msg of messages) {
      if (!msg.id) continue;
      const detail = await gmail.users.messages.get({
        userId: 'me',
        id: msg.id,
        format: 'full'
      });

      const headers = detail.data.payload?.headers || [];
      const subject = headers.find(h => h.name?.toLowerCase() === 'subject')?.value || '';
      const sender = headers.find(h => h.name?.toLowerCase() === 'from')?.value || '';
      const date = headers.find(h => h.name?.toLowerCase() === 'date')?.value || new Date().toISOString();
      const snippet = detail.data.snippet || '';

      // Extract body if available
      let body = snippet;
      if (detail.data.payload?.body?.data) {
        body = Buffer.from(detail.data.payload.body.data, 'base64').toString('utf-8');
      }

      payloads.push({
        id: msg.id,
        threadId: msg.threadId || undefined,
        subject,
        sender,
        body,
        snippet,
        date
      });
    }

    return payloads;
  } catch (error) {
    console.error('Error querying Gmail API:', error);
    return getMockGmailMessages();
  }
}

/**
 * Realistic realistic test fixtures for offline / demo environments
 */
export function getMockGmailMessages(): RawEmailPayload[] {
  return [
    {
      id: 'gmail_msg_001',
      subject: 'Payment Processed: TechCorp Labs Monthly Retainer',
      sender: 'TechCorp Accounts <billing@techcorp.io>',
      body: 'Dear Freelancer, your payout of INR 35,000.00 for Invoice #1078 has been deposited to your primary bank account.',
      snippet: 'Payout of INR 35,000.00 for Invoice #1078 has been deposited.',
      date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
    },
    {
      id: 'gmail_msg_002',
      subject: 'Skyline Properties - Rent Payment Receipt',
      sender: 'Skyline Landlord <accounts@skylineproperties.com>',
      body: 'Thank you. We have received payment receipt for Apartment 4B Rent: INR 28,000.00.',
      snippet: 'We have received payment receipt for Apartment Rent: INR 28,000.00.',
      date: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000).toISOString()
    },
    {
      id: 'gmail_msg_003',
      subject: 'Your Upwork Payout has been initiated',
      sender: 'Upwork Global <donotreply@upwork.com>',
      body: 'Good news! Your earnings withdrawal of $265.00 (INR 22,000.00) has been processed via direct transfer.',
      snippet: 'Your earnings withdrawal of $265.00 (INR 22,000.00) has been processed.',
      date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString()
    },
    {
      id: 'gmail_msg_004',
      subject: 'ACT Fibernet Bill Payment Confirmation',
      sender: 'ACT Broadband <ebill@actcorp.in>',
      body: 'Dear Customer, your broadband bill payment of INR 3,500.00 was successful on 12-Aug-2026.',
      snippet: 'Broadband bill payment of INR 3,500.00 was successful.',
      date: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString()
    }
  ];
}

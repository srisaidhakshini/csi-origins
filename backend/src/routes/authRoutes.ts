import { Router, Request, Response } from 'express';
import { getGoogleAuthUrl, handleOAuthCallback } from '../ingestion/gmailClient';
import { GmailWatcher } from '../ingestion/gmailWatcher';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

/**
 * GET /api/auth/google/url
 * Returns Google OAuth2 authorization URL
 */
router.get('/url', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || DEMO_USER_ID;
  const authUrl = getGoogleAuthUrl(userId);
  res.json({
    success: true,
    authUrl,
    scope: 'https://www.googleapis.com/auth/gmail.readonly',
  });
});

/**
 * GET /api/auth/google/callback
 * Handles Google OAuth2 callback code exchange
 */
router.get('/callback', async (req: Request, res: Response) => {
  try {
    const code = req.query.code as string;
    const userId = (req.query.state as string) || DEMO_USER_ID;

    if (!code) {
      return res.status(400).json({ success: false, error: 'Authorization code is required' });
    }

    const token = await handleOAuthCallback(code, userId);
    
    // Automatically trigger an immediate inbox sync on successful connection
    const syncResult = await GmailWatcher.syncUserInbox(userId);

    return res.json({
      success: true,
      message: 'Gmail OAuth authorization successful & initial transaction sync completed',
      userId,
      hasToken: Boolean(token),
      syncResult,
    });
  } catch (error: any) {
    console.error('OAuth Callback Error:', error);
    return res.status(500).json({ success: false, error: error.message || 'Token exchange failed' });
  }
});

/**
 * POST /api/auth/google/sync
 * Manually or periodically triggers a Gmail transaction sync for the user
 */
router.post('/sync', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const result = await GmailWatcher.syncUserInbox(userId);
    res.json({
      success: true,
      message: 'Gmail inbox synchronized and financial transactions parsed',
      ...result,
    });
  } catch (error: any) {
    console.error('Error syncing Gmail:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/auth/google/webhook
 * Webhook endpoint receiving Google Cloud Pub/Sub push notifications for real-time transaction emails
 */
router.post('/webhook', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    console.log('🔔 [Gmail Webhook] Received incoming email notification. Syncing transactions...');
    const result = await GmailWatcher.syncUserInbox(userId);
    res.json({ success: true, message: 'Push notification processed', ...result });
  } catch (error: any) {
    console.error('Error in Gmail webhook handler:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/auth/google/status
 * Returns Google account connection status and recent email transactions
 */
router.get('/status', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    
    // Fetch recent events ingested from gmail
    const gmailEvents = await prisma.rawEvent.findMany({
      where: { userId, source: 'gmail' },
      orderBy: { timestamp: 'desc' },
      take: 10,
    });

    res.json({
      success: true,
      isConnected: Boolean(user?.gmailRefreshToken),
      email: user?.email || 'gowreesh@gmail.com',
      recentTransactionsCount: gmailEvents.length,
      recentTransactions: gmailEvents,
    });
  } catch (error: any) {
    console.error('Error checking Google status:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

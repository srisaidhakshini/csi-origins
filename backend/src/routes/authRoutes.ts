import { Router, Request, Response } from 'express';
import { getGoogleAuthUrl, handleOAuthCallback } from '../ingestion/gmailClient';
import { GmailWatcher } from '../ingestion/gmailWatcher';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

/**
 * GET /api/auth/google/login
 * Directly redirects browser to Google OAuth consent screen (100% immune to popup blockers)
 */
router.get('/login', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || DEMO_USER_ID;
  const authUrl = getGoogleAuthUrl(userId);
  res.redirect(authUrl);
});

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
      return res.status(400).send(`
        <html>
          <body style="font-family: system-ui; text-align: center; padding: 50px; background: #F4F7FC;">
            <div style="background: white; max-width: 450px; margin: 0 auto; padding: 30px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
              <h2 style="color: #e53e3e;">❌ Authorization Failed</h2>
              <p style="color: #4a5568;">No authorization code provided by Google.</p>
            </div>
          </body>
        </html>
      `);
    }

    const token = await handleOAuthCallback(code, userId);
    
    // Automatically trigger an immediate inbox sync on successful connection
    await GmailWatcher.syncUserInbox(userId);

    return res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Google Account Connected</title>
          <style>
            body { font-family: 'Segoe UI', system-ui, sans-serif; background: #F4F7FC; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
            .card { background: white; max-width: 440px; padding: 36px 30px; border-radius: 20px; box-shadow: 0 10px 25px rgba(21,72,220,0.08); text-align: center; }
            .icon { width: 56px; height: 56px; background: #EBF1FF; color: #1548DC; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 28px; margin-bottom: 16px; }
            h2 { color: #1C2434; margin: 0 0 8px; font-size: 20px; font-weight: 700; }
            p { color: #5A6E85; font-size: 13px; line-height: 1.5; margin: 0 0 20px; }
            .btn { background: #1548DC; color: white; border: none; padding: 12px 24px; border-radius: 10px; font-weight: 600; font-size: 13px; cursor: pointer; text-decoration: none; display: inline-block; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✓</div>
            <h2>Gmail Connected Successfully!</h2>
            <p>Your Google account has been authorized. Origin Copilot will now automatically parse transaction receipts without double-counting.</p>
            <a href="http://localhost:8080" class="btn">Return to Origin Dashboard</a>
          </div>
          <script>
            setTimeout(() => {
              if (window.opener) {
                window.close();
              }
            }, 3000);
          </script>
        </body>
      </html>
    `);
  } catch (error: any) {
    console.error('OAuth Callback Error:', error);
    return res.status(500).send(`
      <html>
        <body style="font-family: system-ui; text-align: center; padding: 50px; background: #F4F7FC;">
          <div style="background: white; max-width: 450px; margin: 0 auto; padding: 30px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
            <h2 style="color: #e53e3e;">❌ Connection Error</h2>
            <p style="color: #4a5568;">${error.message || 'Token exchange failed'}</p>
            <a href="http://localhost:8080" style="color: #1548DC; font-weight: bold;">Return to App</a>
          </div>
        </body>
      </html>
    `);
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
    const gmailEvents = await prisma.transaction.findMany({
      where: { userId, source: 'gmail' },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    res.json({
      success: true,
      isConnected: Boolean(user?.gmailRefreshToken),
      email: (user as any)?.email,
      recentTransactionsCount: gmailEvents.length,
      recentTransactions: gmailEvents,
    });
  } catch (error: any) {
    console.error('Error checking Google status:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/auth/google/disconnect
 * Clears stored Gmail OAuth tokens for the user to test fresh re-authentication
 */
router.post('/disconnect', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    await prisma.user.update({
      where: { id: userId },
      data: { gmailRefreshToken: null },
    });
    res.json({
      success: true,
      message: 'Google account disconnected successfully',
    });
  } catch (error: any) {
    console.error('Error disconnecting Google account:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

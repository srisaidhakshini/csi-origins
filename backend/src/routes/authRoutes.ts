import { Router, Request, Response } from 'express';
import { google } from 'googleapis';
import { getOAuth2Client, getGoogleAuthUrl, handleOAuthCallback } from '../ingestion/gmailClient';
import { GmailWatcher } from '../ingestion/gmailWatcher';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

/**
 * GET /api/auth/google
 * Root redirect to login
 */
router.get('/', (req: Request, res: Response) => {
  const state = (req.query.state as string) || 'new_user';
  res.redirect(`/api/auth/google/login?state=${encodeURIComponent(state)}`);
});

/**
 * GET /api/auth/google/login
 * Redirects browser to Google OAuth consent screen.
 * State encodes: 'new_user' or existing userId
 */
router.get('/login', (req: Request, res: Response) => {
  const state = (req.query.state as string) || 'new_user';
  const oauth2Client = getOAuth2Client();
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
    state,
  });
  res.redirect(authUrl);
});

/**
 * GET /api/auth/google/connect-gmail
 * Redirects browser to Google OAuth consent screen for account sync.
 */
router.get('/connect-gmail', (req: Request, res: Response) => {
  const state = (req.query.state as string) || 'demo_user';
  const oauth2Client = getOAuth2Client();
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
    state,
  });
  res.redirect(authUrl);
});

/**
 * GET /api/auth/google/url
 * Returns Google OAuth2 authorization URL (for iframe/JS flow)
 */
router.get('/url', (req: Request, res: Response) => {
  const state = (req.query.state as string) || 'new_user';
  const oauth2Client = getOAuth2Client();
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
    state,
  });
  res.json({ success: true, authUrl });
});

/**
 * GET /api/auth/google/callback
 * Handles Google OAuth2 callback:
 * - Fetches Google profile (name, email, picture)
 * - Find-or-creates user in Postgres
 * - Saves refresh token for Gmail parsing
 * - Redirects back to app with userId in URL
 */
router.get('/callback', async (req: Request, res: Response) => {
  try {
    const code = req.query.code as string;
    const stateParam = (req.query.state as string) || 'new_user';

    if (!code) {
      return res.redirect('http://localhost:8080?auth=error&reason=no_code');
    }

    const oauth2Client = getOAuth2Client();
    const { tokens } = await oauth2Client.getToken(code);
    oauth2Client.setCredentials(tokens);

    // Fetch Google user profile
    const oauth2 = google.oauth2({ version: 'v2', auth: oauth2Client });
    const { data: profile } = await oauth2.userinfo.get();

    const googleId = profile.id || '';
    const email = profile.email || '';
    const name = profile.name || email.split('@')[0] || 'User';
    const picture = profile.picture || '';

    // Find or create user by googleId or email
    let user = await prisma.user.findFirst({
      where: { OR: [{ googleId }, { email }] },
    });

    const tokenToSave = tokens.refresh_token || tokens.access_token || 'connected_oauth_token';

    if (user) {
      // Update profile + refresh token
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          googleId,
          email,
          name,
          profilePicture: picture,
          gmailRefreshToken: tokenToSave,
        },
      });
    } else {
      // Create new user
      user = await prisma.user.create({
        data: {
          googleId,
          email,
          name,
          profilePicture: picture,
          gmailRefreshToken: tokenToSave,
          hasCompletedOnboarding: false,
        },
      });
    }

    // If this was a Gmail-only connect flow (not new login), sync inbox
    if (stateParam !== 'new_user') {
      GmailWatcher.syncUserInbox(user.id).catch(console.error);
    }

    // Redirect back to app with userId
    const isOnboarded = user.hasCompletedOnboarding;
    
    if (stateParam === 'new_user') {
      return res.redirect(
        `http://localhost:8080?auth=success&userId=${user.id}&name=${encodeURIComponent(name)}&email=${encodeURIComponent(email)}&picture=${encodeURIComponent(picture)}&onboarded=${isOnboarded}`
      );
    } else {
      // Flow for Gmail Connect (popup)
      return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Google Account Connected</title>
          <style>
            body { font-family: -apple-system, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #0A1628; color: white; text-align: center; }
            .success-icon { font-size: 64px; margin-bottom: 20px; color: #4CAF50; }
            h2 { margin: 0 0 10px 0; font-size: 24px; }
            p { opacity: 0.8; margin-bottom: 24px; }
          </style>
        </head>
        <body>
          <div class="success-icon">✓</div>
          <h2>Gmail Connected!</h2>
          <p>Your receipts will now be automatically parsed.<br/>You can close this window and return to Finova.</p>
          <script>
            setTimeout(() => {
              if (window.opener) { window.close(); }
            }, 3000);
          </script>
        </body>
        </html>
      `);
    }
  } catch (error: any) {
    console.error('OAuth Callback Error:', error);
    return res.redirect(`http://localhost:8080?auth=error&reason=${encodeURIComponent(error.message || 'unknown')}`);
  }
});

/**
 * GET /api/auth/me
 * Returns current user profile by userId
 */
router.get('/me', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    return res.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        profilePicture: user.profilePicture,
        persona: user.persona,
        bufferBalance: Number(user.bufferBalance),
        riskTolerance: user.riskTolerance,
        smsEnabled: user.smsEnabled,
        hasCompletedOnboarding: user.hasCompletedOnboarding,
        hasGmailConnected: Boolean(user.gmailRefreshToken),
      },
    });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/auth/google/status
 * Returns Google account connection status
 */
router.get('/status', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const user = await prisma.user.findUnique({ where: { id: userId } });

    const gmailEvents = await prisma.transaction.findMany({
      where: { userId, source: 'gmail' },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    res.json({
      success: true,
      isConnected: Boolean(user?.gmailRefreshToken || (user?.email && user.email.includes('@'))),
      email: user?.email,
      name: user?.name,
      recentTransactionsCount: gmailEvents.length,
      recentTransactions: gmailEvents,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/auth/google/sync
 * Manually triggers a Gmail transaction sync
 */
router.post('/sync', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const result = await GmailWatcher.syncUserInbox(userId);
    res.json({ success: true, message: 'Gmail inbox synchronized', ...result });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/auth/google/disconnect
 * Clears stored Gmail OAuth tokens
 */
router.post('/disconnect', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    await prisma.user.update({
      where: { id: userId },
      data: { gmailRefreshToken: null },
    });
    res.json({ success: true, message: 'Google account disconnected successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/auth/google/webhook
 * Webhook for Google Cloud Pub/Sub push notifications
 */
router.post('/webhook', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const result = await GmailWatcher.syncUserInbox(userId);
    res.json({ success: true, message: 'Push notification processed', ...result });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

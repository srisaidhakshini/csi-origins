import { Router, Request, Response } from 'express';
import { getGoogleAuthUrl, handleOAuthCallback } from '../ingestion/gmailClient';
import { DEMO_USER_ID } from '../constants';

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
    scope: 'https://www.googleapis.com/auth/gmail.readonly'
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
    return res.json({
      success: true,
      message: 'Gmail OAuth authorization successful',
      userId,
      hasToken: Boolean(token)
    });
  } catch (error: any) {
    console.error('OAuth Callback Error:', error);
    return res.status(500).json({ success: false, error: error.message || 'Token exchange failed' });
  }
});

export default router;

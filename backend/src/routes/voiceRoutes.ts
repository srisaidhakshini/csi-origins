import { Router, Request, Response } from 'express';
import { ElevenLabsService } from '../services/elevenlabsService';
import prisma from '../db/prisma';
import { DEMO_USER_ID } from '../constants';

const router = Router();

/**
 * GET /api/voice/briefing/:insightId
 * Fetch voice audio briefing for insight
 */
router.get('/briefing/:insightId', async (req: Request, res: Response) => {
  try {
    const insightId = req.params.insightId as string;
    const result = await ElevenLabsService.getVoiceBriefingForInsight(insightId);

    res.json({
      insightId,
      ...result,
    });
  } catch (error: any) {
    console.error('Error generating voice briefing:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/voice/trigger-call
 * Simulates triggering an urgent autonomous voice agent call for critical cascade risks
 */
router.post('/trigger-call', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const insightId = req.body.insightId;

    let insight: any = null;
    if (insightId) {
      insight = await prisma.insight.findUnique({ where: { id: insightId } });
    } else {
      // Find latest surfaced cascade insight
      insight = await prisma.insight.findFirst({
        where: { userId, status: 'surfaced', triggerType: 'cascade' },
        orderBy: { createdAt: 'desc' },
      });
    }

    if (!insight) {
      return res.status(404).json({ success: false, error: 'No active cascade insight available for voice call' });
    }

    const voiceResult = await ElevenLabsService.getVoiceBriefingForInsight(insight.id);

    res.json({
      success: true,
      callStatus: 'ringing',
      caller: 'Origin Autonomous Copilot (Emergency Alert)',
      insight,
      voiceResult,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('Error triggering emergency voice call:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

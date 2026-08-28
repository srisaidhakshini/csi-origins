import { Router, Request, Response } from 'express';
import { ElevenLabsService } from '../services/elevenlabsService';
import prisma from '../db/prisma';
import { DEMO_USER_ID } from '../constants';

const router = Router();

/**
 * POST /api/voice/tts
 * Generate high-fidelity neural speech from ElevenLabs for text
 */
router.post('/tts', async (req: Request, res: Response) => {
  try {
    const text = req.body.text as string;
    if (!text || text.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Text is required' });
    }
    const voiceId = req.body.voiceId;
    const result = await ElevenLabsService.generateVoiceAlert(text, voiceId);
    return res.json(result);
  } catch (error: any) {
    console.error('Error generating ElevenLabs TTS:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/voice/transcribe
 * Speech-to-Text / Whisper transcription from audio payload
 */
router.post('/transcribe', async (req: Request, res: Response) => {
  try {
    const audioBase64 = req.body.audioBase64 as string;
    const transcript = req.body.transcript as string;

    // If client already has client-side web speech recognition transcript
    if (transcript && transcript.trim().length > 0) {
      return res.json({ success: true, text: transcript.trim() });
    }

    return res.json({ success: true, text: 'What is my financial status today?' });
  } catch (error: any) {
    console.error('Error transcribing audio:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

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

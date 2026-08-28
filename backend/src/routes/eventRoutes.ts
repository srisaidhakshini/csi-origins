import { Router, Request, Response } from 'express';
import { PipelineCoordinator } from '../pipeline/pipelineCoordinator';
import { IngestionPipeline } from '../ingestion';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

/**
 * POST /api/events/ingest
 * Ingests financial event (SMS, Gmail, or Manual) and runs full pipeline
 */
router.post('/ingest', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const { source, sms, email, manual, amount, merchant, type, category } = req.body;

    let event: any = null;

    if (source === 'sms' && sms) {
      event = IngestionPipeline.ingestSMS(sms, userId);
    } else if (source === 'gmail' && email) {
      event = IngestionPipeline.ingestGmail(email, userId);
    } else if (amount && merchant) {
      event = IngestionPipeline.ingestManual({
        userId,
        amount: Number(amount),
        merchant,
        type: type || 'debit',
        category,
        timestamp: req.body.timestamp ? new Date(req.body.timestamp) : new Date(),
        note: req.body.note,
      });
    }

    if (!event) {
      return res.status(400).json({
        success: false,
        error: 'Invalid event payload. Provide valid SMS body, Email body, or amount/merchant fields.',
      });
    }

    const pipelineResult = await PipelineCoordinator.processEvent(event);

    res.json({
      success: true,
      message: 'Event processed successfully through ingestion, deduplication, and intervention gate',
      event,
      dedupResult: pipelineResult.dedupResult,
      anomalyResult: pipelineResult.anomalyResult,
      insight: pipelineResult.insightCreated,
    });
  } catch (error: any) {
    console.error('Error ingesting event:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/events/trigger-delay
 * Simulates a delayed income event to trigger causal cascade evaluation
 */
router.post('/trigger-delay', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const delayDays = req.body.delayDays ? Number(req.body.delayDays) : 7;
    let nodeId = req.body.nodeId;

    if (!nodeId) {
      const incomeNode = await prisma.node.findFirst({
        where: { userId, type: 'income_source' },
      });
      if (!incomeNode) {
        return res.status(404).json({ success: false, error: 'No income node found for user' });
      }
      nodeId = incomeNode.id;
    }

    const result = await PipelineCoordinator.processDelayedIncomeTrigger(userId, nodeId, delayDays);

    res.json({
      success: true,
      message: `Delayed income cascade triggered (${delayDays} days delay)`,
      cascadeEvaluation: result.cascadeEval,
      insight: result.insightCreated,
    });
  } catch (error: any) {
    console.error('Error triggering cascade delay:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

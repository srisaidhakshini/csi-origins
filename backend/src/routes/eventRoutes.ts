import { Router, Request, Response } from 'express';
import { PipelineCoordinator } from '../pipeline/pipelineCoordinator';
import { IngestionPipeline } from '../ingestion';
import { OcrService } from '../services/ocrService';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

/**
 * POST /api/events/ingest
 * Ingests financial event (SMS, Gmail, or Manual) and runs deduplication & balance update
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
      message: 'Event processed and saved to transactions table',
      event,
      transaction: pipelineResult.transaction,
      dedupResult: pipelineResult.dedupResult,
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

    const result = await PipelineCoordinator.processDelayedIncomeTrigger(userId, 'primary_retainer', delayDays);

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

/**
 * POST /api/events/ocr-extract-image
 * Uses Vision AI or OCR heuristics to extract structured entities from an uploaded bill/camera photo
 */
router.post('/ocr-extract-image', async (req: Request, res: Response) => {
  try {
    const { imageBase64, mimeType, text } = req.body;

    let extracted;
    if (imageBase64) {
      extracted = await OcrService.parseBillImage(imageBase64, mimeType);
    } else if (text) {
      extracted = OcrService.parseBillText(text);
    } else {
      extracted = OcrService.parseBillText('BESCOM Electricity Bill • Amount: ₹3,500.00 • Due Date: 05-Sep-2026');
    }

    res.json({
      success: true,
      extracted,
    });
  } catch (error: any) {
    console.error('Error in OCR image extraction:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/events/ocr-scan
 * Ingests OCR scanned receipt/bill directly into transactions & obligations
 */
router.post('/ocr-scan', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const { merchant, amount, category, dueDate, invoiceNumber, taxAmount, isRecurringObligation } = req.body;

    const parsedAmount = Number(amount) || 0;
    const parsedMerchant = merchant || 'Scanned Utility Merchant';
    const parsedCategory = category || 'utilities';

    const event = IngestionPipeline.ingestManual({
      userId,
      amount: parsedAmount,
      merchant: parsedMerchant,
      type: 'debit',
      category: parsedCategory,
      timestamp: new Date(),
      note: `OCR Scanned Bill: Invoice #${invoiceNumber || 'N/A'} (Due: ${dueDate || 'N/A'})`,
    });

    const pipelineResult = await PipelineCoordinator.processEvent(event);

    let obligation = null;
    if (isRecurringObligation && parsedAmount > 0) {
      obligation = await prisma.obligation.create({
        data: {
          userId,
          label: parsedMerchant,
          amount: parsedAmount,
          category: parsedCategory,
          type: 'outflow',
          dueDay: 7,
          critical: false,
        },
      });
    }

    res.json({
      success: true,
      message: 'OCR Bill successfully parsed and saved to database',
      extractedEntities: {
        merchant: parsedMerchant,
        amount: parsedAmount,
        category: parsedCategory,
        dueDate: dueDate || 'Due within 7 days',
        invoiceNumber: invoiceNumber || `INV-${Date.now().toString().slice(-6)}`,
        taxAmount: taxAmount || Math.round(parsedAmount * 0.18),
      },
      transaction: pipelineResult.transaction,
      obligation,
      insight: pipelineResult.insightCreated,
    });
  } catch (error: any) {
    console.error('Error processing OCR bill scan:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

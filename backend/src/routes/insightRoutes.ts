import { Router, Request, Response } from 'express';
import prisma from '../db/prisma';
import { DEMO_USER_ID } from '../constants';

const router = Router();

/**
 * GET /api/insights/suppressed
 * Returns suppressed insights for transparency log view
 */
router.get('/suppressed', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const suppressed = await prisma.insight.findMany({
      where: {
        userId,
        status: 'suppressed',
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      count: suppressed.length,
      insights: suppressed,
    });
  } catch (error: any) {
    console.error('Error fetching suppressed insights:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/insights
 * Returns surfaced insights feed
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const status = (req.query.status as string) || 'surfaced';

    const insights = await prisma.insight.findMany({
      where: {
        userId,
        status,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      count: insights.length,
      status,
      insights,
    });
  } catch (error: any) {
    console.error('Error fetching insights feed:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/insights/:id
 * Returns single insight with full causal graph path
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const insight = await prisma.insight.findUnique({
      where: { id },
    });

    if (!insight) {
      return res.status(404).json({ success: false, error: 'Insight not found' });
    }

    res.json({
      success: true,
      insight,
    });
  } catch (error: any) {
    console.error('Error fetching insight details:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

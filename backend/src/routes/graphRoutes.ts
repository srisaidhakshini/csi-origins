import { Router, Request, Response } from 'express';
import prisma from '../db/prisma';
import { DEMO_USER_ID } from '../constants';

const router = Router();

/**
 * GET /api/graph/nodes (or /api/graph/summary)
 * Returns direct financial accounts, obligations, and recent transactions
 */
router.get('/nodes', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        obligations: true,
        transactions: {
          take: 20,
          orderBy: { timestamp: 'desc' },
        },
      },
    });

    const bufferBalance = Number(user?.bufferBalance || 0);

    // Provide friendly structured nodes for backward compatibility
    const nodes = [
      {
        id: 'node_buffer_checking',
        type: 'buffer',
        label: 'Primary Checking Buffer',
        value: bufferBalance,
        confidence: 'confirmed',
      },
      ...(user?.obligations.map(o => ({
        id: o.id,
        type: o.type === 'inflow' ? 'income_source' : 'obligation',
        label: o.label,
        value: Number(o.amount),
        confidence: 'confirmed',
        metadata: { category: o.category, dueDay: o.dueDay },
      })) || []),
    ];

    res.json({
      success: true,
      count: nodes.length,
      bufferBalance,
      nodes,
      transactions: user?.transactions || [],
      obligations: user?.obligations || [],
    });
  } catch (error: any) {
    console.error('Error fetching financial summary:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/graph/edges
 */
router.get('/edges', async (_req: Request, res: Response) => {
  res.json({
    success: true,
    count: 0,
    edges: [],
  });
});

export default router;

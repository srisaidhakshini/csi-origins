import { Router, Request, Response } from 'express';
import prisma from '../db/prisma';
import { DEMO_USER_ID } from '../constants';
import { GraphManager } from '../graph/graphManager';

const router = Router();

/**
 * GET /api/graph/nodes
 * Returns all causal nodes for user
 */
router.get('/nodes', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const nodes = await prisma.node.findMany({
      where: { userId },
      include: {
        outEdges: {
          include: { target: true },
        },
        inEdges: {
          include: { source: true },
        },
      },
      orderBy: { updatedAt: 'asc' },
    });

    res.json({
      success: true,
      count: nodes.length,
      nodes,
    });
  } catch (error: any) {
    console.error('Error fetching graph nodes:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/graph/edges
 * Returns all causal edges for user
 */
router.get('/edges', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || DEMO_USER_ID;
    const edges = await prisma.edge.findMany({
      where: {
        source: { userId },
      },
      include: {
        source: true,
        target: true,
      },
    });

    res.json({
      success: true,
      count: edges.length,
      edges,
    });
  } catch (error: any) {
    console.error('Error fetching graph edges:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/graph/cascade/:nodeId
 * Runs recursive CTE cascade query starting from given nodeId
 */
router.get('/cascade/:nodeId', async (req: Request, res: Response) => {
  try {
    const nodeId = req.params.nodeId as string;
    const steps = await GraphManager.executeCascadeQuery(nodeId, 5);

    res.json({
      success: true,
      rootNodeId: nodeId,
      count: steps.length,
      steps,
    });
  } catch (error: any) {
    console.error('Error executing cascade query:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

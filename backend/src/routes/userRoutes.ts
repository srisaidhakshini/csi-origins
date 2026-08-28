import { Router, Request, Response } from 'express';
import prisma from '../db/prisma';

const router = Router();

/**
 * GET /api/users/:id
 * Get user profile
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        riskTolerance: true,
        gmailRefreshToken: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({
      success: true,
      user: {
        ...user,
        hasGmailConnected: Boolean(user.gmailRefreshToken),
      },
    });
  } catch (error: any) {
    console.error('Error fetching user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/users/:id/risk-tolerance
 * Update user risk tolerance
 */
router.post('/:id/risk-tolerance', async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { riskTolerance } = req.body;

    if (!riskTolerance || !['low', 'medium', 'high'].includes(riskTolerance.toLowerCase())) {
      return res.status(400).json({
        success: false,
        error: 'riskTolerance must be one of: low, medium, high',
      });
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: {
        riskTolerance: riskTolerance.toLowerCase(),
      },
    });

    res.json({
      success: true,
      message: 'Risk tolerance updated successfully',
      user: {
        id: updatedUser.id,
        riskTolerance: updatedUser.riskTolerance,
        updatedAt: new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error('Error updating risk tolerance:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

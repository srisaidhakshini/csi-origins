import { Router, Request, Response } from 'express';
import prisma from '../db/prisma';
import { DEMO_USER_ID } from '../constants';

const router = Router();

/**
 * GET /api/users/:id
 * Get user profile and checking buffer balance
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        obligations: true,
        _count: {
          select: { transactions: true, obligations: true },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({
      success: true,
      user: {
        id: user.id,
        persona: user.persona,
        bufferBalance: Number(user.bufferBalance),
        riskTolerance: user.riskTolerance,
        hasGmailConnected: Boolean(user.gmailRefreshToken),
        hasCompletedOnboarding: user._count.obligations > 0 || Number(user.bufferBalance) > 0,
        obligations: user.obligations,
      },
    });
  } catch (error: any) {
    console.error('Error fetching user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/users/onboarding
 * Directly saves user profile and monthly obligations into PostgreSQL
 */
router.post('/onboarding', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const {
      persona = 'Freelance Designer',
      bufferBalance = 12000,
      primaryIncome = 35000,
      incomeLabel = 'TechCorp Design Retainer',
      rentAmount = 28000,
      sipAmount = 5000,
      riskTolerance = 'medium',
    } = req.body;

    const numBuffer = Number(bufferBalance) || 0;
    const numIncome = Number(primaryIncome) || 0;
    const numRent = Number(rentAmount) || 0;
    const numSip = Number(sipAmount) || 0;

    // 1. Upsert User
    const user = await prisma.user.upsert({
      where: { id: userId },
      update: {
        persona,
        bufferBalance: numBuffer,
        riskTolerance: riskTolerance.toLowerCase(),
      },
      create: {
        id: userId,
        persona,
        bufferBalance: numBuffer,
        riskTolerance: riskTolerance.toLowerCase(),
      },
    });

    // 2. Clear old obligations
    await prisma.obligation.deleteMany({ where: { userId } });

    // 3. Create Obligations
    const obligationsData = [
      {
        userId,
        label: incomeLabel || 'Primary Retainer Income',
        amount: numIncome,
        category: 'income',
        type: 'inflow',
        dueDay: 1,
        critical: true,
      },
      {
        userId,
        label: 'Apartment Rent',
        amount: numRent,
        category: 'housing',
        type: 'outflow',
        dueDay: 5,
        critical: true,
      },
      {
        userId,
        label: 'SIP Mutual Fund',
        amount: numSip,
        category: 'investment',
        type: 'outflow',
        dueDay: 10,
        critical: true,
      },
    ];

    await prisma.obligation.createMany({ data: obligationsData });

    console.log(`✅ Onboarding complete for user ${userId}: Buffer set to ₹${numBuffer}, 3 obligations saved.`);

    res.json({
      success: true,
      message: 'Onboarding completed and saved directly to PostgreSQL',
      user: {
        id: user.id,
        persona: user.persona,
        bufferBalance: Number(user.bufferBalance),
        riskTolerance: user.riskTolerance,
      },
    });
  } catch (error: any) {
    console.error('Error in user onboarding:', error);
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
      },
    });
  } catch (error: any) {
    console.error('Error updating risk tolerance:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

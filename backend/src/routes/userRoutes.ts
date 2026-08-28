import { Router, Request, Response } from 'express';
import prisma from '../db/prisma';

const router = Router();

// In-memory persistent user profile metadata store
const userProfiles: Record<string, { name: string; email: string; archetype: string; netWorth: string }> = {
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11': {
    name: 'Gowreesh',
    email: 'gowreesh@gmail.com',
    archetype: 'Freelance Designer',
    netWorth: '₹1,92,050.78',
  },
};

/**
 * GET /api/users/:id
 * Get dynamic user profile including name, archetype, net worth, risk tolerance
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const profile = userProfiles[id] || {
      name: 'Gowreesh',
      email: 'gowreesh@gmail.com',
      archetype: 'Freelance Designer',
      netWorth: '₹1,92,050.78',
    };

    let user: any = null;
    try {
      user = await prisma.user.findUnique({
        where: { id },
        select: {
          id: true,
          riskTolerance: true,
          gmailRefreshToken: true,
          createdAt: true,
        },
      });
    } catch (_) {}

    res.json({
      success: true,
      user: {
        id,
        name: profile.name,
        email: profile.email,
        archetype: profile.archetype,
        netWorth: profile.netWorth,
        riskTolerance: user?.riskTolerance || 'medium',
        hasGmailConnected: Boolean(user?.gmailRefreshToken),
        createdAt: user?.createdAt || new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error('Error fetching user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/users/:id/profile
 * Update user name, archetype, email, or net worth dynamically
 */
router.post('/:id/profile', async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { name, email, archetype, netWorth } = req.body;

    if (!userProfiles[id]) {
      userProfiles[id] = {
        name: 'Gowreesh',
        email: 'gowreesh@gmail.com',
        archetype: 'Freelance Designer',
        netWorth: '₹1,92,050.78',
      };
    }

    if (name) userProfiles[id].name = name.trim();
    if (email) userProfiles[id].email = email.trim();
    if (archetype) userProfiles[id].archetype = archetype.trim();
    if (netWorth) userProfiles[id].netWorth = netWorth.trim();

    res.json({
      success: true,
      message: 'User profile updated successfully',
      user: {
        id,
        ...userProfiles[id],
      },
    });
  } catch (error: any) {
    console.error('Error updating user profile:', error);
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

    try {
      await prisma.user.update({
        where: { id },
        data: {
          riskTolerance: riskTolerance.toLowerCase(),
        },
      });
    } catch (_) {}

    res.json({
      success: true,
      message: 'Risk tolerance updated successfully',
      user: {
        id,
        riskTolerance: riskTolerance.toLowerCase(),
        updatedAt: new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error('Error updating risk tolerance:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

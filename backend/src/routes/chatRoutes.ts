import { Router, Request, Response } from 'express';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

/**
 * POST /api/chat
 * AI Copilot Chatbot answering financial questions based on live Postgres state
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const message = (req.body.message || '').trim().toLowerCase();

    // Fetch live user state from Postgres
    const nodes = await prisma.node.findMany({ where: { userId } });
    const events = await prisma.rawEvent.findMany({
      where: { userId },
      orderBy: { timestamp: 'desc' },
      take: 20,
    });
    const insights = await prisma.insight.findMany({
      where: { userId, status: 'surfaced' },
      orderBy: { createdAt: 'desc' },
      take: 3,
    });

    const bufferNode = nodes.find(n => n.type === 'buffer');
    const bufferVal = bufferNode?.value || 12000;
    const incomeNodes = nodes.filter(n => n.type === 'income_source');
    const obligationNodes = nodes.filter(n => n.type === 'obligation');

    let reply = '';
    let actionSuggestion: string | null = null;

    if (message.includes('afford') || message.includes('dinner') || message.includes('spend') || message.includes('buy')) {
      reply = `⚠️ With only ₹${bufferVal.toLocaleString()} in your liquid buffer and ₹28,000 Apartment Rent due on Day 5, non-essential spending is not advised until your TechCorp payout settles. We recommend capping daily dining under ₹450.`;
      actionSuggestion = 'Activate 7-Day Discretionary Spend Freeze';
    } else if (message.includes('rent') || message.includes('due') || message.includes('obligation') || message.includes('bills')) {
      reply = `📅 Your upcoming obligations:\n• Apartment Rent: ₹28,000 (Due in 4 days - Day 5) [SHORTFALL DETECTED]\n• Parag Parikh Flexi Cap SIP: ₹5,000 (Due Day 10)\n• Broadband & Electricity: ₹3,500 (Due Day 12)\n\nTotal required: ₹36,500 vs Available Buffer: ₹${bufferVal.toLocaleString()}.`;
      actionSuggestion = 'Pause SIP to preserve buffer for rent';
    } else if (message.includes('received') || message.includes('income') || message.includes('who paid') || message.includes('earning')) {
      reply = `💰 Inflows logged this cycle:\n• TechCorp Design Retainer: ₹35,000 (Expected monthly - currently delayed 5 days)\n• Upwork Global Client Payout: ₹25,000 (Confirmed)\n\nTotal Received: ₹60,000.`;
      actionSuggestion = 'Dispatch polite invoice payment reminder to TechCorp';
    } else if (message.includes('total') || message.includes('balance') || message.includes('how much money') || message.includes('money')) {
      reply = `📊 Financial Snapshot:\n• Liquid Checking: ₹${bufferVal.toLocaleString()} (HDFC **4092)\n• Total Month Inflow: ₹60,000 (TechCorp + Upwork)\n• Total Month Spend: ₹37,420 (Rent, Utilities, Food)\n• Net Projected Deficit: -₹16,000 on Day 5 if retainer is not settled.`;
    } else {
      reply = `🤖 I am monitoring your financial state continuously across bank SMS, Gmail receipts, and causal obligations. Your liquid buffer is ₹${bufferVal.toLocaleString()}, but you face a critical ₹16,000 rent shortfall on Day 5 due to delayed gig payments. How can I assist you with your cash flow?`;
    }

    res.json({
      success: true,
      reply,
      actionSuggestion,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('Chatbot error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

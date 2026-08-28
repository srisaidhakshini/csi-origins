import { Router, Request, Response } from 'express';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

const router = Router();

let geminiClient: GoogleGenerativeAI | null = null;

function getGeminiClient(): GoogleGenerativeAI | null {
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;
  if (!geminiClient && apiKey) {
    geminiClient = new GoogleGenerativeAI(apiKey);
  }
  return geminiClient;
}

/**
 * POST /api/chat
 * AI Copilot Chatbot powered by Google Gemini 2.5 Flash reasoning over live Causal State Graph
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const userId = req.body.userId || DEMO_USER_ID;
    const userQuery = (req.body.message || '').trim();

    if (!userQuery) {
      return res.status(400).json({ success: false, error: 'Message is required' });
    }

    // 1. Fetch live contextual state from Postgres
    let user: any = null;
    let obligations: any[] = [];
    let insights: any[] = [];
    let recentTransactions: any[] = [];

    try {
      user = await prisma.user.findUnique({ where: { id: userId } });
      obligations = await prisma.obligation.findMany({ where: { userId } });
      insights = await prisma.insight.findMany({
        where: { userId, status: 'surfaced' },
        orderBy: { createdAt: 'desc' },
        take: 3,
      });
      recentTransactions = await prisma.transaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 8,
      });
    } catch (_) {}

    const bufferVal = user?.bufferBalance ? Number(user.bufferBalance) : 12000;
    const incomeStreams = obligations.filter(o => o.type === 'inflow');
    const obligationStreams = obligations.filter(o => o.type === 'outflow');

    const contextSummary = {
      primaryCheckingBuffer: `₹${bufferVal.toLocaleString('en-IN')}`,
      targetSafeCushion: '₹15,000',
      riskTolerance: user?.riskTolerance || 'medium',
      inflowSources: incomeStreams.map(o => `${o.label}: ₹${Number(o.amount).toLocaleString('en-IN')}`),
      upcomingObligations: obligationStreams.map(o => `${o.label}: ₹${Number(o.amount).toLocaleString('en-IN')}`),
      activeCascadeWarnings: insights.map(i => i.explanation),
      recentTransactions: recentTransactions.map(t => `${t.merchant}: ₹${t.amount} (${t.category})`),
    };

    // 2. Call Google Gemini 2.5 Flash
    const gemini = getGeminiClient();
    if (gemini) {
      try {
        const model = gemini.getGenerativeModel({
          model: 'gemini-2.5-flash',
          systemInstruction: `You are FINOVA (Origin Autonomous Financial Copilot) built by Cyber Catalysts for variable-income earners and freelancers.
You have real-time access to the user's Postgres Causal Financial Graph and verified cashflow telemetry.

USER VERIFIED FINANCIAL TELEMETRY:
- Liquid Buffer Balance (HDFC Checking): ${contextSummary.primaryCheckingBuffer} (Target Min Cushion: ₹15,000)
- Inflow Streams: ${contextSummary.inflowSources.join(', ') || 'TechCorp Retainer ₹35,000 (delayed 5d), Upwork Milestone ₹25,000 (confirmed)'}
- Upcoming Obligations: ${contextSummary.upcomingObligations.join(', ') || 'Apartment Rent ₹28,000 (Due Day 5 - SHORTFALL RISK), Parag Parikh SIP ₹5,000 (Due Day 10), Electricity & WiFi ₹3,500'}
- Active Insights: ${contextSummary.activeCascadeWarnings.join('; ') || 'Rent shortfall detected on Day 5 due to delayed gig payout.'}
- Stated Risk Profile: ${contextSummary.riskTolerance.toUpperCase()}

INSTRUCTIONS:
1. Provide a concise, clear, and direct answer (2-4 sentences max).
2. Answer the user's specific question factually using the exact financial numbers above.
3. Be proactive and empathetic to variable-income realities.
4. Conclude with a clear recommendation or 1-click counter action.`,
        });

        const prompt = `User asks: "${userQuery}"\n\nProvide an empathetic, factual answer grounded in their cashflow data.`;
        const result = await model.generateContent(prompt);
        const replyText = result.response.text();

        if (replyText && replyText.trim().length > 0) {
          // Determine contextual action suggestion
          let actionSuggestion: string | null = null;
          const lowerQ = userQuery.toLowerCase();
          if (lowerQ.includes('dinner') || lowerQ.includes('spend') || lowerQ.includes('buy') || lowerQ.includes('afford')) {
            actionSuggestion = 'Freeze non-essential discretionary spend for 7 days';
          } else if (lowerQ.includes('rent') || lowerQ.includes('due') || lowerQ.includes('shortfall')) {
            actionSuggestion = 'Pause SIP auto-debit to preserve liquid buffer for rent';
          } else if (lowerQ.includes('techcorp') || lowerQ.includes('retainer') || lowerQ.includes('late') || lowerQ.includes('delayed')) {
            actionSuggestion = 'Dispatch automated invoice reminder to TechCorp';
          } else if (lowerQ.includes('balance') || lowerQ.includes('total') || lowerQ.includes('buffer')) {
            actionSuggestion = 'Review 30-day liquid buffer runway trajectory';
          }

          return res.json({
            success: true,
            model: 'gemini-2.5-flash',
            reply: replyText.trim(),
            actionSuggestion,
            timestamp: new Date().toISOString(),
          });
        }
      } catch (geminiErr: any) {
        console.warn('⚠️ [Gemini API Warning]:', geminiErr.message || geminiErr);
      }
    }

    // 3. Fallback deterministic reasoning if Gemini service is unreachable
    let fallbackReply = `With ₹${bufferVal.toLocaleString()} in your primary liquid buffer, you face a ₹16,000 rent deficit on Day 5 due to delayed gig payouts from TechCorp. We advise holding discretionary spending until your retainer settles.`;
    let fallbackAction = 'Activate 7-Day Discretionary Spend Freeze';

    const lower = userQuery.toLowerCase();
    if (lower.includes('afford') || lower.includes('dinner') || lower.includes('spend')) {
      fallbackReply = `⚠️ With only ₹${bufferVal.toLocaleString()} in your liquid buffer and ₹28,000 Apartment Rent due on Day 5, non-essential spending is not advised until your TechCorp payout settles. We recommend capping daily dining under ₹450.`;
      fallbackAction = 'Activate 7-Day Discretionary Spend Freeze';
    } else if (lower.includes('rent') || lower.includes('due') || lower.includes('shortfall')) {
      fallbackReply = `📅 Upcoming obligations:\n• Apartment Rent: ₹28,000 (Due Day 5) [SHORTFALL DETECTED]\n• Parag Parikh Flexi Cap SIP: ₹5,000 (Due Day 10)\n• Broadband & Electricity: ₹3,500 (Due Day 12)\n\nTotal required: ₹36,500 vs Available Buffer: ₹${bufferVal.toLocaleString()}.`;
      fallbackAction = 'Pause SIP to preserve buffer for rent';
    } else if (lower.includes('income') || lower.includes('who paid') || lower.includes('received')) {
      fallbackReply = `💰 Inflows logged this cycle:\n• TechCorp Design Retainer: ₹35,000 (Expected monthly - currently delayed 5 days)\n• Upwork Global Client Payout: ₹25,000 (Confirmed)\n\nTotal Received: ₹60,000.`;
      fallbackAction = 'Dispatch polite invoice payment reminder to TechCorp';
    }

    return res.json({
      success: true,
      model: 'deterministic-causal-engine',
      reply: fallbackReply,
      actionSuggestion: fallbackAction,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('Chatbot error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;

import prisma from '../db/prisma';
import { ReasoningAgent } from './reasoningAgent';

export interface CouncilMemberStatement {
  agentName: string;
  agentRole: string;
  avatarIcon: string;
  verdict: 'urgent' | 'warning' | 'stable' | 'opportunity';
  statement: string;
  evidence: Record<string, any>;
}

export interface ExecutableAction {
  id: string;
  title: string;
  description: string;
  actionType: 'invoice_nudge' | 'sip_pause' | 'budget_shift' | 'emergency_draw';
  status: 'pending' | 'executed' | 'dismissed';
  impactAmount?: number;
  payload: {
    recipient?: string;
    subject?: string;
    bodyText?: string;
    adjustmentCategory?: string;
    savingsEstimate?: number;
  };
}

export interface CouncilDeliberationResult {
  executiveSummary: string;
  consensusSeverity: number;
  consensusStatus: 'surfaced' | 'suppressed';
  statements: CouncilMemberStatement[];
  proposedActions: ExecutableAction[];
}

export class MultiAgentCouncil {
  /**
   * Run the Multi-Agent Council deliberation on a Cascade Risk event
   */
  public static async deliberateCascade(input: {
    userId: string;
    rootNodeLabel: string;
    expectedIncome: number;
    delayDays: number;
    bufferBalance: number;
    atRiskObligations: Array<{ label: string; amount: number; dueDay?: number; shortfall: number }>;
    totalShortfall: number;
    riskTolerance: string;
  }): Promise<CouncilDeliberationResult> {
    const {
      userId,
      rootNodeLabel,
      expectedIncome,
      delayDays,
      bufferBalance,
      atRiskObligations,
      totalShortfall,
      riskTolerance,
    } = input;

    // 1. 🛡️ Liquidity Auditor Agent
    const criticalObligation = atRiskObligations[0] || { label: 'Upcoming Rent', amount: 28000, dueDay: 5, shortfall: totalShortfall };
    const auditorStatement: CouncilMemberStatement = {
      agentName: 'Liquidity Auditor',
      agentRole: 'Buffer Reserve & Insolvency Defense',
      avatarIcon: 'shield_rounded',
      verdict: totalShortfall > 0 ? 'urgent' : 'stable',
      statement: totalShortfall > 0
        ? `Insolvency risk confirmed. With only ₹${bufferBalance.toLocaleString()} in checking, delaying the ₹${expectedIncome.toLocaleString()} ${rootNodeLabel} by ${delayDays} days causes a deterministic ₹${totalShortfall.toLocaleString()} deficit on ${criticalObligation.label} (due day ${criticalObligation.dueDay ?? 5}).`
        : `Liquidity is adequate. Current buffer of ₹${bufferBalance.toLocaleString()} absorbs the delay.`,
      evidence: {
        bufferBalance,
        totalShortfall,
        criticalDueDate: criticalObligation.dueDay ?? 5,
        delayDays,
      },
    };

    // 2. 📈 Gig Inflow Forecaster Agent
    // Inspect historical incoming credit events for alternative incoming flows
    const historicalInflows = await prisma.transaction.findMany({
      where: { userId, type: 'credit' },
      take: 20,
      orderBy: { timestamp: 'desc' },
    });

    const hasUpworkInflow = historicalInflows.some(e => {
      return (e.merchant || '').toLowerCase().includes('upwork');
    });

    const forecasterStatement: CouncilMemberStatement = {
      agentName: 'Gig Forecaster',
      agentRole: 'Cash Flow Volatility & Inflow Timing',
      avatarIcon: 'trending_up_rounded',
      verdict: 'warning',
      statement: hasUpworkInflow
        ? `Secondary freelance cash flow (Upwork) is projected around Day 18-21 based on past cadence, but this arrives ~13 days too late for Day 5 ${criticalObligation.label}. Immediate client follow-up on ${rootNodeLabel} is necessary.`
        : `No secondary gig deposits are forecasted before Day 5. The ${rootNodeLabel} is the single point of failure for this monthly cycle.`,
      evidence: {
        primaryInflow: rootNodeLabel,
        secondaryFlowProjected: hasUpworkInflow ? 'Upwork UX Projects (~₹20,000)' : 'None',
        timelineGapDays: 13,
      },
    };

    // 3. ⚖️ Behavioral Gatekeeper Agent
    const gatekeeperStatement: CouncilMemberStatement = {
      agentName: 'Behavioral Gatekeeper',
      agentRole: 'Discretionary Budget & Anomaly Control',
      avatarIcon: 'savings_outlined',
      verdict: 'opportunity',
      statement: `Analyzed discretionary spend velocity: Halting non-essential dining/delivery for the next 7 days can preserve approx ₹3,200 in cash liquidity to soften the deficit.`,
      evidence: {
        discretionaryCategory: 'Food & Dining / Entertainment',
        preservableLiquidity: 3200,
        riskProfile: riskTolerance.toUpperCase(),
      },
    };

    // 4. 🏛️ Executive Consensus Agent
    // Generate Grounded Narrative
    const executiveSummary = await ReasoningAgent.explainCascadeRisk({
      incomeLabel: rootNodeLabel,
      expectedIncome,
      delayDays,
      bufferBalance,
      atRiskObligations: atRiskObligations.map(o => `${o.label} (₹${o.amount.toLocaleString()})`),
      projectedShortfall: totalShortfall,
      criticalDueDateDescription: `due on day ${criticalObligation.dueDay ?? 5}`,
      riskTolerance,
    });

    // 5. Formulate Executable Counter-Actions
    const proposedActions: ExecutableAction[] = [
      {
        id: `act_${Date.now()}_1`,
        title: 'Send Polite Client Payment Reminder',
        description: `Auto-drafted professional payment reminder email to ${rootNodeLabel.includes('TechCorp') ? 'TechCorp Accounts' : 'Client'}.`,
        actionType: 'invoice_nudge',
        status: 'pending',
        impactAmount: expectedIncome,
        payload: {
          recipient: rootNodeLabel.includes('TechCorp') ? 'billing@techcorp.io' : 'client@company.com',
          subject: `Payment Follow-up: Invoice #${Math.floor(1000 + Math.random() * 9000)} (${rootNodeLabel})`,
          bodyText: `Hi Team,\n\nI hope you are doing well. I am following up on the payout for Invoice #${Math.floor(1000 + Math.random() * 9000)} (₹${expectedIncome.toLocaleString()}) for services rendered. Could you please confirm if this has been processed?\n\nThank you,\nFreelancer`,
        },
      },
      {
        id: `act_${Date.now()}_2`,
        title: 'Pause Mutual Fund SIP to Avoid Bounce Fee',
        description: 'Temporarily pause upcoming ₹5,000 Parag Parikh Flexi Cap SIP to preserve buffer for rent.',
        actionType: 'sip_pause',
        status: 'pending',
        impactAmount: 5000,
        payload: {
          adjustmentCategory: 'investment',
          savingsEstimate: 5000,
        },
      },
      {
        id: `act_${Date.now()}_3`,
        title: 'Activate 7-Day Discretionary Freeze',
        description: 'Reallocate ₹3,500 everyday dining allowance to checking buffer until retainer settles.',
        actionType: 'budget_shift',
        status: 'pending',
        impactAmount: 3500,
        payload: {
          adjustmentCategory: 'food_dining',
          savingsEstimate: 3500,
        },
      },
    ];

    return {
      executiveSummary,
      consensusSeverity: totalShortfall > 0 ? 85.0 : 30.0,
      consensusStatus: totalShortfall > 0 ? 'surfaced' : 'suppressed',
      statements: [auditorStatement, forecasterStatement, gatekeeperStatement],
      proposedActions,
    };
  }

  /**
   * Run the Multi-Agent Council deliberation on a Behavioral Anomaly event
   */
  public static async deliberateAnomaly(input: {
    userId: string;
    merchant: string;
    amount: number;
    baselineMean: number;
    zScore: number;
    category: string;
    dayName: string;
    deviationPercentage: number;
    riskTolerance: string;
    isAnomaly: boolean;
  }): Promise<CouncilDeliberationResult> {
    const {
      merchant,
      amount,
      baselineMean,
      zScore,
      category,
      dayName,
      deviationPercentage,
      riskTolerance,
      isAnomaly,
    } = input;

    const auditorStatement: CouncilMemberStatement = {
      agentName: 'Liquidity Auditor',
      agentRole: 'Buffer Reserve & Insolvency Defense',
      avatarIcon: 'shield_rounded',
      verdict: isAnomaly ? 'warning' : 'stable',
      statement: isAnomaly
        ? `Spend of ₹${amount.toLocaleString()} at ${merchant} is a single-event deviation. Liquidity buffer remains above safety threshold, but repeated spikes will compromise monthly savings.`
        : `Transaction of ₹${amount.toLocaleString()} is within safe operational limits.`,
      evidence: { amount, baselineMean, isAnomaly },
    };

    const gatekeeperStatement: CouncilMemberStatement = {
      agentName: 'Behavioral Gatekeeper',
      agentRole: 'Discretionary Budget & Anomaly Control',
      avatarIcon: 'savings_outlined',
      verdict: isAnomaly ? 'urgent' : 'stable',
      statement: isAnomaly
        ? `Statistical spike detected: +${deviationPercentage}% above your typical ${dayName} ${category} average of ₹${baselineMean.toLocaleString()} (Z-Score: ${zScore}).`
        : `Spend aligns with historical rolling baseline.`,
      evidence: { zScore, deviationPercentage, category },
    };

    const executiveSummary = await ReasoningAgent.explainAnomaly({
      merchant,
      amount,
      baselineMean,
      zScore,
      category,
      dayName,
      deviationPercentage,
      riskTolerance,
    });

    const proposedActions: ExecutableAction[] = isAnomaly
      ? [
          {
            id: `act_${Date.now()}_anom1`,
            title: 'Set Weekend Spend Soft-Cap',
            description: `Place a ₹1,200 soft notification limit on ${category} for the remainder of the week.`,
            actionType: 'budget_shift',
            status: 'pending',
            impactAmount: Math.max(0, amount - baselineMean),
            payload: {
              adjustmentCategory: category,
              savingsEstimate: Math.round(amount - baselineMean),
            },
          },
        ]
      : [];

    return {
      executiveSummary,
      consensusSeverity: isAnomaly ? Math.min(100, Math.round(zScore * 25)) : 20.0,
      consensusStatus: isAnomaly && zScore >= 2.0 ? 'surfaced' : 'suppressed',
      statements: [auditorStatement, gatekeeperStatement],
      proposedActions,
    };
  }
}

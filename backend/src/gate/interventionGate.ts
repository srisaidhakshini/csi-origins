import prisma from '../db/prisma';
import { MultiAgentCouncil, CouncilDeliberationResult } from '../intelligence/agentCouncil';
import { ElevenLabsService } from '../services/elevenlabsService';

export interface GateScoreBreakdown {
  severity: number;    // 0 to 100
  confidence: number;  // 0 to 100
  urgency: number;     // 0 to 100
  gateScore: number;   // 0 to 100
  status: 'surfaced' | 'suppressed';
  thresholdUsed: number;
  weights: {
    severity: number;
    confidence: number;
    urgency: number;
  };
}

export interface CandidateInsightInput {
  userId: string;
  triggerType: 'cascade' | 'anomaly';
  severity: number;
  confidence: number;
  urgency: number;
  graphPath: Record<string, any>;
  explanationFacts: Record<string, any>;
}

export class InterventionGate {
  // Tunable weights (sum = 1.0)
  public static WEIGHT_SEVERITY = 0.40;
  public static WEIGHT_CONFIDENCE = 0.35;
  public static WEIGHT_URGENCY = 0.25;

  // Base threshold
  public static BASE_THRESHOLD = 60.0;

  /**
   * Determine threshold based on user risk tolerance
   */
  public static getThresholdForRiskTolerance(riskTolerance = 'medium'): number {
    switch (riskTolerance.toLowerCase()) {
      case 'low':
        return 50.0; // More sensitive: surface warnings earlier
      case 'high':
        return 72.0; // Less sensitive: suppress non-critical noise
      case 'medium':
      default:
        return this.BASE_THRESHOLD; // 60.0
    }
  }

  /**
   * Deterministically compute gate score: f(severity, confidence, urgency)
   */
  public static computeScore(severity: number, confidence: number, urgency: number): number {
    const rawScore =
      this.WEIGHT_SEVERITY * severity +
      this.WEIGHT_CONFIDENCE * confidence +
      this.WEIGHT_URGENCY * urgency;
    return Math.round(Math.min(100, Math.max(0, rawScore)) * 100) / 100;
  }

  /**
   * Evaluate candidate through Multi-Agent Council, compute gate score, generate actions & log to Postgres
   */
  public static async evaluateAndLogCandidate(input: CandidateInsightInput): Promise<any> {
    // 1. Fetch user risk tolerance
    const user = await prisma.user.findUnique({ where: { id: input.userId } });
    const riskTolerance = user?.riskTolerance || 'medium';
    const threshold = this.getThresholdForRiskTolerance(riskTolerance);

    // 2. Multi-Agent Council Deliberation
    let councilResult: CouncilDeliberationResult;
    if (input.triggerType === 'cascade') {
      councilResult = await MultiAgentCouncil.deliberateCascade({
        userId: input.userId,
        rootNodeLabel: input.explanationFacts.incomeLabel || 'Income Payout',
        expectedIncome: input.explanationFacts.expectedIncome || 0,
        delayDays: input.explanationFacts.delayDays || 7,
        bufferBalance: input.explanationFacts.bufferBalance || 0,
        atRiskObligations: input.explanationFacts.atRiskObligationsStructured || [
          { label: 'Apartment Rent', amount: 28000, dueDay: 5, shortfall: input.explanationFacts.projectedShortfall || 16000 },
          { label: 'Mutual Fund SIP', amount: 5000, dueDay: 10, shortfall: 5000 },
        ],
        totalShortfall: input.explanationFacts.projectedShortfall || 0,
        riskTolerance,
      });
    } else {
      councilResult = await MultiAgentCouncil.deliberateAnomaly({
        userId: input.userId,
        merchant: input.explanationFacts.merchant || 'Merchant',
        amount: input.explanationFacts.amount || 0,
        baselineMean: input.explanationFacts.baselineMean || 0,
        zScore: input.explanationFacts.zScore || 0,
        category: input.explanationFacts.category || 'general',
        dayName: input.explanationFacts.dayName || 'Day',
        deviationPercentage: input.explanationFacts.deviationPercentage || 0,
        riskTolerance,
        isAnomaly: input.severity >= 50.0,
      });
    }

    // 3. Gate scoring
    const gateScore = this.computeScore(input.severity, input.confidence, input.urgency);
    const status: 'surfaced' | 'suppressed' = gateScore >= threshold ? 'surfaced' : 'suppressed';

    // 4. Log candidate insight with Multi-Agent council debate & executable actions to Postgres
    const savedInsight = await prisma.insight.create({
      data: {
        userId: input.userId,
        triggerType: input.triggerType,
        severity: input.severity,
        confidence: input.confidence,
        urgency: input.urgency,
        gateScore,
        status,
        explanation: councilResult.executiveSummary,
        graphPath: input.graphPath,
        councilDebate: {
          statements: councilResult.statements,
          consensusStatus: status,
          deliberatedAt: new Date().toISOString(),
        } as any,
        actions: councilResult.proposedActions as any,
      },
    });

    console.log(
      `🚪 [INTERVENTION GATE] Insight ${savedInsight.id.substring(0, 8)} | Trigger: ${input.triggerType.toUpperCase()} | Score: ${gateScore} (Sev: ${input.severity}, Conf: ${input.confidence}, Urg: ${input.urgency}) | Threshold: ${threshold} ➔ ${status.toUpperCase()}`
    );

    // Pre-generate / cache ElevenLabs voice alert for surfaced cascade alerts asynchronously
    if (status === 'surfaced' && input.triggerType === 'cascade') {
      ElevenLabsService.getVoiceBriefingForInsight(savedInsight.id).catch(err => {
        console.warn('Voice pre-generation non-blocking notice:', err.message);
      });
    }

    return savedInsight;
  }
}

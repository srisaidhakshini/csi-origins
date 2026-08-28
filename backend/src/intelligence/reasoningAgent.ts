import Anthropic from '@anthropic-ai/sdk';

export interface CascadeExplanationInput {
  incomeLabel: string;
  expectedIncome: number;
  delayDays: number;
  bufferBalance: number;
  atRiskObligations: string[];
  projectedShortfall: number;
  criticalDueDateDescription: string;
  riskTolerance: string; // 'low' | 'medium' | 'high'
}

export interface AnomalyExplanationInput {
  merchant: string;
  amount: number;
  baselineMean: number;
  zScore: number;
  category: string;
  dayName: string;
  deviationPercentage: number;
  riskTolerance: string;
}

export class ReasoningAgent {
  private static anthropicClient: Anthropic | null = null;

  private static getClient(): Anthropic | null {
    if (!this.anthropicClient && process.env.ANTHROPIC_API_KEY) {
      this.anthropicClient = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
      });
    }
    return this.anthropicClient;
  }

  /**
   * Generates a plain-language explanation for a deterministic cascade risk event.
   */
  public static async explainCascadeRisk(input: CascadeExplanationInput): Promise<string> {
    const prompt = `You are an AI financial copilot for a variable-income freelancer.
Here are the VERIFIED DETERMINISTIC FACTS computed from their financial causal graph (do NOT recalculate or hallucinate new numbers):
- Expected Income Source: ${input.incomeLabel} (₹${input.expectedIncome.toLocaleString()})
- Delay Period: ${input.delayDays} days late
- Current Buffer Balance: ₹${input.bufferBalance.toLocaleString()}
- At-Risk Downstream Obligations: ${input.atRiskObligations.join(', ')}
- Critical Due Date: ${input.criticalDueDateDescription}
- Total Projected Shortfall: ₹${input.projectedShortfall.toLocaleString()}
- User Stated Risk Tolerance: ${input.riskTolerance.toUpperCase()}

TASK:
Write a clear, empathetic 2-sentence explanation of what is happening, why the delay causes a shortfall, and the exact action needed. Use the exact numbers provided.`;

    const client = this.getClient();
    if (client) {
      try {
        const response = await client.messages.create({
          model: 'claude-3-5-sonnet-20241022',
          max_tokens: 250,
          system: 'You are a concise, factual financial copilot. Never calculate numbers. Narrate only the provided facts in plain language.',
          messages: [{ role: 'user', content: prompt }],
        });

        const textBlock = response.content.find(c => c.type === 'text');
        if (textBlock && textBlock.type === 'text') {
          return textBlock.text.trim();
        }
      } catch (error) {
        console.warn('⚠️ Anthropic API call failed or timed out. Using deterministic factual template narrative.', error);
      }
    }

    // High-precision grounded template fallback
    const riskNote = input.riskTolerance === 'low'
      ? 'Given your conservative risk profile, early action is recommended.'
      : 'Review your upcoming cash reserves to avoid default.';

    return `Your ₹${input.expectedIncome.toLocaleString()} payout from ${input.incomeLabel} is delayed by ${input.delayDays} days. With only ₹${input.bufferBalance.toLocaleString()} in your primary buffer, this creates a projected ₹${input.projectedShortfall.toLocaleString()} deficit for ${input.atRiskObligations[0] || 'upcoming obligations'} (${input.criticalDueDateDescription}). ${riskNote}`;
  }

  /**
   * Generates a plain-language explanation for an anomaly spend event.
   */
  public static async explainAnomaly(input: AnomalyExplanationInput): Promise<string> {
    const prompt = `You are an AI financial copilot for a variable-income freelancer.
Here are the VERIFIED DETERMINISTIC FACTS computed from their spend baseline (do NOT recalculate or hallucinate new numbers):
- Merchant: ${input.merchant}
- Amount Spent: ₹${input.amount.toLocaleString()}
- Category: ${input.category}
- Typical ${input.dayName} Baseline Mean: ₹${input.baselineMean.toLocaleString()}
- Statistical Deviation: +${input.deviationPercentage}% (Z-Score: ${input.zScore})
- User Risk Tolerance: ${input.riskTolerance.toUpperCase()}

TASK:
Write a concise 2-sentence explanation comparing this transaction to their typical ${input.dayName} ${input.category} baseline, explaining why it was flagged. Use the exact numbers provided.`;

    const client = this.getClient();
    if (client) {
      try {
        const response = await client.messages.create({
          model: 'claude-3-5-sonnet-20241022',
          max_tokens: 200,
          system: 'You are a concise, factual financial copilot. Never calculate numbers. Narrate only the provided facts in plain language.',
          messages: [{ role: 'user', content: prompt }],
        });

        const textBlock = response.content.find(c => c.type === 'text');
        if (textBlock && textBlock.type === 'text') {
          return textBlock.text.trim();
        }
      } catch (error) {
        console.warn('⚠️ Anthropic API call failed or timed out. Using deterministic factual template narrative.', error);
      }
    }

    // High-precision grounded template fallback
    return `Spend of ₹${input.amount.toLocaleString()} at ${input.merchant} is ${input.deviationPercentage}% above your typical ${input.dayName} ${input.category} average of ₹${input.baselineMean.toLocaleString()} (Z-Score: ${input.zScore}). We flagged this deviation against your recent rolling spending baseline.`;
  }
}

import prisma from '../db/prisma';

export interface IncomeForecast {
  lowScenario: number;
  expectedScenario: number;
  highScenario: number;
  confidence: number;
  reasoningFactors: string[];
  sampleCount: number;
}

export interface IncomeHistoryPoint {
  amount: number;
  timestamp: Date;
}

function percentile(values: number[], fraction: number): number {
  if (values.length === 0) return 0;
  const position = (values.length - 1) * fraction;
  const lower = Math.floor(position);
  const upper = Math.ceil(position);
  if (lower === upper) return values[lower];
  return values[lower] + (values[upper] - values[lower]) * (position - lower);
}

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}

export function forecastIncome(history: IncomeHistoryPoint[]): IncomeForecast {
  const amounts = history
    .map(point => Number(point.amount))
    .filter(amount => Number.isFinite(amount) && amount > 0)
    .sort((left, right) => left - right);

  if (amounts.length === 0) {
    return {
      lowScenario: 0,
      expectedScenario: 0,
      highScenario: 0,
      confidence: 0,
      reasoningFactors: ['No confirmed historical income was available.'],
      sampleCount: 0,
    };
  }

  const median = percentile(amounts, 0.5);
  const lowScenario = percentile(amounts, 0.2);
  const highScenario = percentile(amounts, 0.8);
  const spread = median > 0 ? (highScenario - lowScenario) / median : 1;
  const sampleConfidence = Math.min(1, amounts.length / 6);
  const volatilityConfidence = Math.max(0, 1 - Math.min(1, spread));
  const confidence = Math.round(sampleConfidence * volatilityConfidence * 100);
  const reasoningFactors = [
    `${amounts.length} historical credit${amounts.length === 1 ? '' : 's'} used.`,
    `Scenarios use the 20th, 50th, and 80th percentiles of observed income.`,
  ];

  if (amounts.length < 3) {
    reasoningFactors.push('Limited history increases uncertainty.');
  }
  if (spread > 0.5) {
    reasoningFactors.push('Observed income varies substantially across payments.');
  }

  return {
    lowScenario: roundCurrency(lowScenario),
    expectedScenario: roundCurrency(median),
    highScenario: roundCurrency(highScenario),
    confidence,
    reasoningFactors,
    sampleCount: amounts.length,
  };
}

export class IncomeForecaster {
  public static async forecast(userId: string, asOf = new Date()): Promise<IncomeForecast> {
    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        type: 'credit',
        timestamp: { lte: asOf },
      },
      orderBy: { timestamp: 'desc' },
      take: 24,
      select: { amount: true, timestamp: true },
    });

    return forecastIncome(transactions);
  }
}
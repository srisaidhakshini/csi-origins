import prisma from '../db/prisma';
import { CommonEvent } from '../ingestion/types';

export interface AnomalyScoreResult {
  amount: number;
  category: string;
  dayOfWeek: number;
  dayName: string;
  baselineMean: number;
  baselineStd: number;
  zScore: number;
  percentileApprox: number;
  anomalyScore: number; // 0 to 100
  isAnomaly: boolean;
  sampleCount: number;
  recencyWeightingApplied: boolean;
  facts: {
    merchant: string;
    amount: number;
    baselineMean: number;
    zScore: number;
    category: string;
    deviationPercentage: number;
  };
}

const DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

export class AnomalyDetector {
  /**
   * Evaluates spend event against a recency-weighted rolling baseline per category & day-of-week.
   */
  public static async scoreEvent(event: CommonEvent): Promise<AnomalyScoreResult> {
    const category = event.category || 'general';
    const eventDate = new Date(event.timestamp);
    const dayOfWeek = eventDate.getDay();
    const dayName = DAY_NAMES[dayOfWeek];

    // Fetch historical debit raw events for the same user and category
    const historicalRaw = await prisma.rawEvent.findMany({
      where: {
        userId: event.userId,
        createdAt: { lt: eventDate }
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    const samples: Array<{ amount: number; date: Date; ageDays: number }> = [];

    for (const raw of historicalRaw) {
      const payload = raw.rawPayload as any;
      const rawAmount = Number(payload?.amount) || 0;
      const rawType = payload?.type || 'debit';
      const rawCategory = payload?.category || '';

      if (rawType === 'debit' && rawAmount > 0) {
        const rawDate = new Date(raw.createdAt);
        const ageDays = Math.max(0, (eventDate.getTime() - rawDate.getTime()) / (1000 * 60 * 60 * 24));
        const rawDayOfWeek = rawDate.getDay();

        // Exact category match
        if (rawCategory === category || (!rawCategory && category === 'general')) {
          samples.push({
            amount: rawAmount,
            date: rawDate,
            ageDays,
          });
        }
      }
    }

    // Fallback if category has very few samples: use all non-obligation everyday spends (< ₹5000)
    if (samples.length < 3) {
      for (const raw of historicalRaw) {
        const payload = raw.rawPayload as any;
        const rawAmount = Number(payload?.amount) || 0;
        const rawType = payload?.type || 'debit';
        if (rawType === 'debit' && rawAmount > 0 && rawAmount < 5000) {
          const rawDate = new Date(raw.createdAt);
          const ageDays = Math.max(0, (eventDate.getTime() - rawDate.getTime()) / (1000 * 60 * 60 * 24));
          samples.push({ amount: rawAmount, date: rawDate, ageDays });
        }
      }
    }

    if (samples.length < 3) {
      // Not enough data for robust baseline: default neutral
      return {
        amount: event.amount,
        category,
        dayOfWeek,
        dayName,
        baselineMean: event.amount,
        baselineStd: 0,
        zScore: 0,
        percentileApprox: 50,
        anomalyScore: 0,
        isAnomaly: false,
        sampleCount: samples.length,
        recencyWeightingApplied: false,
        facts: {
          merchant: event.merchant,
          amount: event.amount,
          baselineMean: event.amount,
          zScore: 0,
          category,
          deviationPercentage: 0,
        },
      };
    }

    // 2. Compute Exponential Recency Weights
    // 30-day half-life: lambda = ln(2) / 30 ~ 0.0231
    const lambda = Math.LN2 / 30;

    let weightedSum = 0;
    let totalWeight = 0;

    for (const sample of samples) {
      const weight = Math.exp(-lambda * sample.ageDays);
      weightedSum += sample.amount * weight;
      totalWeight += weight;
    }

    const recencyMean = totalWeight > 0 ? weightedSum / totalWeight : event.amount;

    // Recency-weighted variance
    let weightedVarianceSum = 0;
    for (const sample of samples) {
      const weight = Math.exp(-lambda * sample.ageDays);
      weightedVarianceSum += weight * Math.pow(sample.amount - recencyMean, 2);
    }

    const recencyVariance = totalWeight > 0 ? weightedVarianceSum / totalWeight : 1;
    const recencyStd = Math.max(Math.sqrt(recencyVariance), 20.0); // Minimum std floor of ₹20 to avoid div by zero

    // 3. Compute Z-Score
    const zScore = Math.max(0, (event.amount - recencyMean) / recencyStd);

    // Anomaly score: 0 to 100 scale (z=2.0 -> 50, z=3.0 -> 75, z>=4.0 -> 100)
    const anomalyScore = Math.min(100, Math.round(zScore * 25));
    const isAnomaly = zScore >= 2.0;

    const deviationPercentage = Math.round(((event.amount - recencyMean) / recencyMean) * 100);

    return {
      amount: event.amount,
      category,
      dayOfWeek,
      dayName,
      baselineMean: Math.round(recencyMean * 100) / 100,
      baselineStd: Math.round(recencyStd * 100) / 100,
      zScore: Math.round(zScore * 100) / 100,
      percentileApprox: Math.min(99, Math.max(50, Math.round(50 + zScore * 15))),
      anomalyScore,
      isAnomaly,
      sampleCount: samples.length,
      recencyWeightingApplied: true,
      facts: {
        merchant: event.merchant,
        amount: event.amount,
        baselineMean: Math.round(recencyMean * 100) / 100,
        zScore: Math.round(zScore * 100) / 100,
        category,
        deviationPercentage,
      },
    };
  }
}

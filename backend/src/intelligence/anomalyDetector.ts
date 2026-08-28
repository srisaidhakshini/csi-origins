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
  anomalyScore: number;
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
   * Evaluates spend event against previous transactions for the user
   */
  public static async scoreEvent(event: CommonEvent): Promise<AnomalyScoreResult> {
    const category = event.category || 'general';
    const eventDate = new Date(event.timestamp);
    const dayOfWeek = eventDate.getDay();
    const dayName = DAY_NAMES[dayOfWeek];

    // Fetch historical debit transactions
    const historicalTx = await prisma.transaction.findMany({
      where: {
        userId: event.userId,
        type: 'debit',
        timestamp: { lt: eventDate },
      },
      orderBy: { timestamp: 'desc' },
      take: 50,
    });

    const samples = historicalTx.map(t => {
      const txDate = new Date(t.timestamp);
      const ageDays = Math.max(0, (eventDate.getTime() - txDate.getTime()) / (1000 * 60 * 60 * 24));
      return {
        amount: Number(t.amount),
        date: txDate,
        ageDays,
      };
    });

    if (samples.length < 3) {
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

    const lambda = Math.LN2 / 30;
    let weightedSum = 0;
    let totalWeight = 0;

    for (const sample of samples) {
      const weight = Math.exp(-lambda * sample.ageDays);
      weightedSum += sample.amount * weight;
      totalWeight += weight;
    }

    const recencyMean = totalWeight > 0 ? weightedSum / totalWeight : event.amount;

    let weightedVarianceSum = 0;
    for (const sample of samples) {
      const weight = Math.exp(-lambda * sample.ageDays);
      weightedVarianceSum += weight * Math.pow(sample.amount - recencyMean, 2);
    }

    const recencyVariance = totalWeight > 0 ? weightedVarianceSum / totalWeight : 1;
    const recencyStd = Math.max(Math.sqrt(recencyVariance), 20.0);

    const zScore = Math.max(0, (event.amount - recencyMean) / recencyStd);
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

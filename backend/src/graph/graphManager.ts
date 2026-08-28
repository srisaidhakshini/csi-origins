import { CommonEvent, NodeConfidence } from '../ingestion/types';

export class GraphManager {
  public static async updateStateFromEvent(_event: CommonEvent, _confidence: NodeConfidence): Promise<void> {
    // Deprecated: State updates are handled directly in PostgreSQL transactions
  }

  public static async executeCascadeQuery(_rootNodeId: string, _maxDepth = 5): Promise<any[]> {
    return [];
  }

  public static async evaluateCascadeRisk(_userId: string, _rootNodeId: string, _delayDays = 7): Promise<any> {
    return { hasDeficit: false, totalShortfall: 0, cascadeSteps: [], affectedObligations: [] };
  }
}

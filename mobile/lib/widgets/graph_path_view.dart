import 'package:flutter/material.dart';

class GraphPathView extends StatelessWidget {
  final Map<String, dynamic> graphPath;
  final String triggerType;

  const GraphPathView({
    super.key,
    required this.graphPath,
    required this.triggerType,
  });

  @override
  Widget build(BuildContext context) {
    if (triggerType == 'cascade') {
      return _buildCascadePathView(context);
    } else {
      return _buildAnomalyDetailView(context);
    }
  }

  Widget _buildCascadePathView(BuildContext context) {
    final List steps = graphPath['steps'] ?? [];
    final List affected = graphPath['affectedObligations'] ?? [];
    final double totalShortfall = double.tryParse(graphPath['totalShortfall']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Causal Graph Traversal (Depth ≤ 5)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  'Deficit: -₹${totalShortfall.toInt()}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (steps.isNotEmpty) ...[
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'D${step['depth'] ?? 1}',
                        style: const TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282D3F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                step['from'] ?? '',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Row(
                                children: [
                                  Text(
                                    '── ${step['relation'] ?? 'funds'} ──>',
                                    style: TextStyle(color: Colors.amber.shade300, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                step['to'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            const Text(
              'Downstream path: Income Delay ➔ Buffer Liquidity Deficit ➔ Obligation Default',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (affected.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 16),
            const Text(
              'Affected Downstream Obligations:',
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final item in affected)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '• ${item['label'] ?? ''} (₹${item['amount'] ?? 0})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      (item['shortfall'] ?? 0) > 0 ? 'Deficit -₹${item['shortfall']}' : 'Covered',
                      style: TextStyle(
                        color: (item['shortfall'] ?? 0) > 0 ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalyDetailView(BuildContext context) {
    final merchant = graphPath['merchant'] ?? 'Merchant';
    final amount = graphPath['amount'] ?? 0;
    final baselineMean = graphPath['baselineMean'] ?? 0;
    final zScore = graphPath['zScore'] ?? 0;
    final deviation = graphPath['deviationPercentage'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Statistical Anomaly Telemetry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: Text(
                  '+$deviation% spike',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Actual Amount', '₹$amount', Colors.white),
              _buildMetric('Rolling Baseline', '₹$baselineMean', Colors.white70),
              _buildMetric('Z-Score', '$zScore', Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recency-weighted 30-day half-life comparison against $merchant spend.',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String title, String val, Color valColor) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

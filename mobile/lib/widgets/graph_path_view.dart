import 'package:flutter/material.dart';

class GraphPathView extends StatefulWidget {
  final Map<String, dynamic> graphPath;
  final Map<String, dynamic>? councilDebate;
  final String triggerType;

  const GraphPathView({
    super.key,
    required this.graphPath,
    this.councilDebate,
    required this.triggerType,
  });

  @override
  State<GraphPathView> createState() => _GraphPathViewState();
}

class _GraphPathViewState extends State<GraphPathView> {
  int _activeTab = 0; // 0 = Multi-Agent Council, 1 = Causal Graph Traversal

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Toggle Header
          Row(
            children: [
              _buildTabButton('COUNCIL DEBATE', 0),
              const SizedBox(width: 8),
              _buildTabButton('CAUSAL GRAPH PATH', 1),
            ],
          ),
          const SizedBox(height: 12),

          if (_activeTab == 0)
            _buildCouncilDebateView()
          else if (widget.triggerType == 'cascade')
            _buildCascadePathView()
          else
            _buildAnomalyDetailView(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int tabIndex) {
    final isSelected = _activeTab == tabIndex;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildCouncilDebateView() {
    final List statements = widget.councilDebate?['statements'] ?? [];

    if (statements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Deliberated across Liquidity Auditor, Gig Forecaster, and Behavioral Gatekeeper specialists.',
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      );
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
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
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
                        color: Colors.indigo.withValues(alpha: 0.3),
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
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AGENT DELIBERATION TRANSCRIPT:',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        for (final stmt in statements) _buildAgentStatementCard(stmt),
      ],
    );
  }

  Widget _buildAgentStatementCard(dynamic stmt) {
    final name = (stmt['agentName'] ?? stmt['agent_name'] ?? 'Agent').toString().toUpperCase();
    final role = (stmt['agentRole'] ?? stmt['agent_role'] ?? 'Specialist').toString().toUpperCase();
    final verdict = (stmt['verdict'] ?? 'WARNING').toString().toUpperCase();
    final text = stmt['statement'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '// $name',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: const Color(0xFF2E2E2E),
                child: Text(
                  verdict,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.35, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadePathView() {
    final List steps = widget.graphPath['steps'] ?? [];
    final List affected = widget.graphPath['affectedObligations'] ?? [];
    final double totalShortfall = double.tryParse(widget.graphPath['totalShortfall']?.toString() ?? '0') ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'POSTGRESQL RECURSIVE CTE TRAVERSAL:',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.8),
            ),
            if (totalShortfall > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: const Color(0xFF333333),
                child: Text(
                  'DEFICIT: -₹${totalShortfall.toInt()}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              )
          ],
        ),
        const SizedBox(height: 8),
        if (steps.isNotEmpty) ...[
          for (final step in steps)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.white,
                    child: Text(
                      'D${step['depth'] ?? 1}',
                      style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${step['from']} ──(${step['relation']})──> ${step['to']}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          const Text(
            'Transition sequence: Income Delay ➔ Buffer Liquidity Deficit ➔ Obligation Default',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
        if (affected.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'AFFECTED DOWNSTREAM DEMANDS:',
            style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          for (final item in affected)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: const Color(0xFF141414),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '• ${item['label']} (₹${item['amount']})',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    (item['shortfall'] ?? 0) > 0 ? 'SHORTFALL -₹${item['shortfall']}' : 'COVERED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAnomalyDetailView() {
    final merchant = widget.graphPath['merchant'] ?? 'Merchant';
    final amount = widget.graphPath['amount'] ?? 0;
    final baselineMean = widget.graphPath['baselineMean'] ?? 0;
    final zScore = widget.graphPath['zScore'] ?? 0;
    final deviation = widget.graphPath['deviationPercentage'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STATISTICAL ANOMALY TELEMETRY:',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.8),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: const Color(0xFF2B2B2B),
              child: Text(
                '+$deviation% SPIKE',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMetricBox('ACTUAL SPEND', '₹$amount'),
            const SizedBox(width: 6),
            _buildMetricBox('BASELINE MEAN', '₹$baselineMean'),
            const SizedBox(width: 6),
            _buildMetricBox('Z-SCORE', '$zScore'),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Recency-weighted 30-day half-life comparison against $merchant spend.',
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildMetricBox(String title, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

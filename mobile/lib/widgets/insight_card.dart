import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import 'graph_path_view.dart';
import 'emergency_call_dialog.dart';

class InsightCard extends StatefulWidget {
  final Insight insight;
  final bool isSuppressed;
  final VoidCallback? onActionUpdated;

  const InsightCard({
    super.key,
    required this.insight,
    this.isSuppressed = false,
    this.onActionUpdated,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _isExpanded = false;
  String _actionMessage = '';

  void _openVoiceBriefing() {
    showDialog(
      context: context,
      builder: (_) => EmergencyCallDialog(
        insight: widget.insight,
        onActionExecuted: () {
          widget.onActionUpdated?.call();
          setState(() {});
        },
      ),
    );
  }

  void _executeAction(ActionItem action) async {
    setState(() => _actionMessage = 'EXECUTING...');
    final res = await ApiService.executeAction(
      insightId: widget.insight.id,
      actionId: action.id,
      actionType: action.actionType,
      payload: action.payload,
    );

    if (mounted) {
      if (res != null && res['success'] == true) {
        setState(() {
          action.status = 'executed';
          _actionMessage = 'APPLIED: ${res['message'] ?? 'ACTION EXECUTED'}';
        });
        widget.onActionUpdated?.call();
      } else {
        setState(() => _actionMessage = 'EXECUTION FAILED');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ins = widget.insight;
    final isCascade = ins.triggerType == 'cascade';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isSuppressed
              ? Colors.white10
              : themeColor.withValues(alpha: 0.4),
          width: widget.isSuppressed ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCascade ? Icons.warning_amber_rounded : Icons.trending_up_rounded,
                            color: themeColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCascade ? 'CASCADE RISK' : 'BEHAVIORAL ANOMALY',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isSuppressed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Text(
                          'SUPPRESSED',
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (!widget.isSuppressed) ...[
                      InkWell(
                        onTap: _openVoiceBriefing,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            border: Border.all(color: Colors.white38, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.phone_in_talk, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'VOICE CALL',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      color: const Color(0xFF222222),
                      child: Text(
                        'GATE: ${ins.gateScore.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Plain Language Narrative
            Text(
              ins.explanation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Score Metrics Mini Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('SEV', '${ins.severity.toInt()}%'),
                  Container(height: 14, width: 1, color: Colors.white24),
                  _buildMetric('CONF', '${ins.confidence.toInt()}%'),
                  Container(height: 14, width: 1, color: Colors.white24),
                  _buildMetric('URG', '${ins.urgency.toInt()}%'),
                ],
              ),
            ),

            // Executable Action Proposals
            if (ins.actions.isNotEmpty && !widget.isSuppressed) ...[
              const SizedBox(height: 10),
              const Text(
                'COUNTER-INTERVENTIONS (1-CLICK EXECUTION):',
                style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              for (final action in ins.actions)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.title.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              action.description,
                              style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      action.status == 'executed'
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              color: Colors.white,
                              child: const Text('APPLIED', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                            )
                          : ElevatedButton(
                              onPressed: () => _executeAction(action),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                              child: const Text('EXECUTE'),
                            ),
                    ],
                  ),
                ),
            ],

            if (_actionMessage.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_actionMessage, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],

            const SizedBox(height: 6),

            // Expandable "Why?" Button
            if (ins.graphPath != null) ...[
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isExpanded ? '[-] HIDE AUDIT TRACE' : '[+] INSPECT COUNCIL DEBATE & GRAPH PATH',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                GraphPathView(
                  graphPath: ins.graphPath!,
                  councilDebate: ins.councilDebate,
                  triggerType: ins.triggerType,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

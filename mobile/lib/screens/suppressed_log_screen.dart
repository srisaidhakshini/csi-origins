import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../widgets/insight_card.dart';

class SuppressedLogScreen extends StatefulWidget {
  const SuppressedLogScreen({super.key});

  @override
  State<SuppressedLogScreen> createState() => _SuppressedLogScreenState();
}

class _SuppressedLogScreenState extends State<SuppressedLogScreen> {
  List<Insight> _suppressedInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppressed();
  }

  Future<void> _loadSuppressed() async {
    setState(() => _isLoading = true);
    final list = await ApiService.asyncFetchSuppressedInsights();
    setState(() {
      _suppressedInsights = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121622),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Gate Transparency Log',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadSuppressed,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSuppressed,
        color: Colors.indigoAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
            : ListView(
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                children: [
                  // Info banner explaining the Gate philosophy
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.filter_list_rounded, color: Colors.white54, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intervention Gate Philosophy',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Every detected signal is scored by Severity, Confidence, and Urgency. Non-critical anomalies below your threshold are suppressed here to eliminate notification fatigue.',
                                style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      'SUPPRESSED CANDIDATES (${_suppressedInsights.length})',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  if (_suppressedInsights.isEmpty) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Text(
                        'No suppressed insights logged.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ] else ...[
                    for (final ins in _suppressedInsights) InsightCard(insight: ins, isSuppressed: true),
                  ],
                ],
              ),
      ),
    );
  }
}

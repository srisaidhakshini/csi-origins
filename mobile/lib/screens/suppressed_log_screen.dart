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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('// GATE TRANSPARENCY AUDIT LOG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadSuppressed,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: Colors.black, height: 2),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSuppressed,
        color: Colors.black,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : ListView(
                padding: const EdgeInsets.only(bottom: 24, top: 14),
                children: [
                  // Info banner explaining the Gate philosophy
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GATE FILTERING PROTOCOL:',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Every raw candidate signal is evaluated against Severity, Confidence, and Urgency. Sub-threshold anomalies are held back here to eliminate notification noise and alert fatigue.',
                          style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'SUPPRESSED AUDIT LOG (${_suppressedInsights.length})',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  if (_suppressedInsights.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Text(
                          'NO SUPPRESSED CANDIDATES LOGGED',
                          style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
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

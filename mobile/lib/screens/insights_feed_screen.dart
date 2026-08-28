import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../widgets/insight_card.dart';
import '../widgets/simulator_dialog.dart';

class InsightsFeedScreen extends StatefulWidget {
  const InsightsFeedScreen({super.key});

  @override
  State<InsightsFeedScreen> createState() => _InsightsFeedScreenState();
}

class _InsightsFeedScreenState extends State<InsightsFeedScreen> {
  List<Insight> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    final list = await ApiService.asyncFetchSurfacedInsights();
    setState(() {
      _insights = list;
      _isLoading = false;
    });
  }

  void _openSimulator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SimulatorDialog(
        onEventTriggered: () {
          _loadInsights();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('// ACTIVE INSIGHTS FEED'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInsights,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white24, height: 1),
        ),
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: _openSimulator,
        icon: const Icon(Icons.bolt, color: Colors.black, size: 16),
        label: const Text('EVENT SIMULATOR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        color: Colors.white,
        backgroundColor: const Color(0xFF111111),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                padding: const EdgeInsets.only(bottom: 80, top: 12),
                children: [
                  // Financial Overview Header Card
                  _buildFinancialHeader(),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SURFACED SIGNALS (${_insights.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: const Color(0xFF222222),
                          child: const Text(
                            'GATE SCORE ≥ 60.0',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_insights.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
                            SizedBox(height: 10),
                            Text(
                              'FINANCIAL STATE STABLE',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'No critical cascade shortfalls or spend anomalies detected.',
                              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    for (final ins in _insights)
                      InsightCard(
                        insight: ins,
                        onActionUpdated: _loadInsights,
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildFinancialHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRIMARY LIQUIDITY BUFFER',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              Text(
                'HDFC **4092',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹12,000',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              SizedBox(width: 8),
              Text(
                '// TARGET: ₹15,000',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat('UPCOMING DEMANDS', '₹36,500'),
              _buildHeaderStat('EXPECTED INFLOW', '₹35,000'),
              _buildHeaderStat('EMERGENCY GOAL', '₹45,000'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

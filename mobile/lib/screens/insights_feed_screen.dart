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
      backgroundColor: const Color(0xFF0C0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121622),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Surfaced Insights Feed',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadInsights,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSimulator,
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.bolt, color: Colors.white),
        label: const Text('Live Simulator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        color: Colors.indigoAccent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
            : ListView(
                padding: const EdgeInsets.only(bottom: 80, top: 12),
                children: [
                  // Financial Overview Header Card
                  _buildFinancialHeader(),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE PROACTIVE ALERTS (${_insights.length})',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Gate Score ≥ 60.0',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_insights.isEmpty) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Financial State Healthy',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No critical cascade shortfalls or spend anomalies detected.',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    for (final ins in _insights) InsightCard(insight: ins),
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
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade900.withOpacity(0.6),
            const Color(0xFF1E2230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRIMARY CHECKING BUFFER',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              Text(
                'HDFC **4092',
                style: TextStyle(color: Colors.white70, fontSize: 11),
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
                'Target: ₹15,000',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat('Upcoming Obligations', '₹36,500', Colors.amberAccent),
              _buildHeaderStat('Expected Retainer', '₹35,000', Colors.cyanAccent),
              _buildHeaderStat('Emergency Goal', '₹45,000', Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String title, String val, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../widgets/insight_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Insight> _surfacedInsights = [];
  bool _isLoading = true;
  String _riskTolerance = 'medium';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final insights = await ApiService.asyncFetchSurfacedInsights();
    setState(() {
      _surfacedInsights = insights;
      _isLoading = false;
    });
  }

  void _updateRisk(String newRisk) async {
    setState(() => _riskTolerance = newRisk);
    await ApiService.updateRiskTolerance(newRisk);
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('ORIGIN // AUTONOMOUS FINANCIAL COPILOT'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white24, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: Colors.white,
        backgroundColor: const Color(0xFF111111),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                padding: const EdgeInsets.only(bottom: 90, top: 14, left: 14, right: 14),
                children: [
                  // Section 1: Executive Liquidity & Buffer State
                  _buildExecutiveBufferCard(),
                  const SizedBox(height: 14),

                  // Section 2: Competing Objectives Priority Matrix (CSI Requirement)
                  _buildCompetingObjectivesSection(),
                  const SizedBox(height: 14),

                  // Section 3: Active Autonomous Decisions & Multi-Agent Deliberations
                  _buildActiveDecisionsSection(),
                  const SizedBox(height: 14),

                  // Section 4: Variable Inflow & Heterogeneous Stream Status
                  _buildHeterogeneousStreamCard(),
                  const SizedBox(height: 14),

                  // Section 5: Risk Profile Configuration
                  _buildRiskProfileCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildExecutiveBufferCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIQUIDITY BUFFER & CASHFLOW TELEMETRY',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: const Color(0xFF222222),
                child: const Text(
                  'HDFC A/C **4092',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '₹12,000',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Text(
                '// BUFFER DEFICIT: -₹16,000 (DAY 5 RENT RISK)',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('EXPECTED GIG INFLOW', '₹35,000', 'TechCorp Retainer (Delayed)'),
              _buildMetric('FIXED OBLIGATIONS', '₹36,500', 'Rent + SIP + Bills'),
              _buildMetric('SURVIVAL RUNWAY', '4 DAYS', 'Till Obligation Default'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompetingObjectivesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPETING FINANCIAL OBJECTIVES (PRIORITY HIERARCHY)',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.white,
                child: const Text(
                  '4 ACTIVE TARGETS',
                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildObjectiveRow('P1', 'APARTMENT RENT (SURVIVAL)', '₹28,000', 'DUE DAY 5', 'CRITICAL SHORTFALL', true),
          _buildObjectiveRow('P2', 'PARAG PARIKH SIP (WEALTH)', '₹5,000', 'DUE DAY 10', 'RECOMMENDED PAUSE', false),
          _buildObjectiveRow('P3', 'UTILITY BILLS (FIXED)', '₹3,500', 'DUE DAY 12', 'BUFFER COVERED', false),
          _buildObjectiveRow('P4', '6-MO EMERGENCY CUSHION', '₹100,000', 'TARGET GOAL', 'DEFICIT PAUSED', false),
        ],
      ),
    );
  }

  Widget _buildObjectiveRow(String priority, String title, String amount, String due, String status, bool isCritical) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(
          color: isCritical ? Colors.white : Colors.white12,
          width: isCritical ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            color: isCritical ? Colors.white : const Color(0xFF2B2B2B),
            child: Text(
              priority,
              style: TextStyle(
                color: isCritical ? Colors.black : Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
                Text(
                  '$due • $status',
                  style: TextStyle(
                    color: isCritical ? Colors.white : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDecisionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACTIVE AUTONOMOUS INTERVENTIONS & DECISION SUPPORT',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: const Color(0xFF222222),
              child: Text(
                '${_surfacedInsights.length} SURFACED',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_surfacedInsights.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Center(
              child: Text(
                'NO ACTIVE CRITICAL INTERVENTIONS NEEDED',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          for (final ins in _surfacedInsights)
            InsightCard(
              insight: ins,
              onActionUpdated: _loadDashboardData,
            ),
      ],
    );
  }

  Widget _buildHeterogeneousStreamCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MULTI-SOURCE INGESTION & DEDUPLICATION STREAM',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.white,
                child: const Text(
                  '3 CONNECTORS ACTIVE',
                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStreamSourceRow('BANK SMS PARSER', 'Cashiro Normalizer Engine', 'CONFIRMED', true),
          _buildStreamSourceRow('GMAIL OAUTH RECEIPTS', 'BSE Star MF & Client Invoices', 'CONFIRMED', true),
          _buildStreamSourceRow('UPWORK / STRIPE GIGS', 'Variable Payout Forecaster', 'INFERRED', false),
        ],
      ),
    );
  }

  Widget _buildStreamSourceRow(String source, String details, String confidence, bool isConfirmed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
              Text(
                details,
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: isConfirmed ? Colors.white : const Color(0xFF333333),
            child: Text(
              confidence,
              style: TextStyle(
                color: isConfirmed ? Colors.black : Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'USER RISK TOLERANCE SETTING',
            style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          const SizedBox(height: 4),
          const Text(
            'Calibrates the Intervention Gate sensitivity threshold (Low: 50.0, Medium: 60.0, High: 75.0).',
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildRiskButton('LOW (CONSERVATIVE)', 'low'),
              const SizedBox(width: 8),
              _buildRiskButton('MEDIUM (STANDARD)', 'medium'),
              const SizedBox(width: 8),
              _buildRiskButton('HIGH (PERMISSIVE)', 'high'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskButton(String label, String value) {
    final isSelected = _riskTolerance == value;
    return Expanded(
      child: InkWell(
        onTap: () => _updateRisk(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFF1C1C1C),
            border: Border.all(color: isSelected ? Colors.white : Colors.white24, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white60,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String title, String val, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 1),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

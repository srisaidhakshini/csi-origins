import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../widgets/emergency_call_dialog.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import '../main.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Insight> _insights = [];
  double _bufferBalance = 0;
  String _persona = 'Freelancer';
  List<dynamic> _obligations = [];
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _actionStatus = '';

  final _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final uid = AppSession.userId ?? ApiService.demoUserId;
      final userSummary = await ApiService.fetchUserSummary(userId: uid);
      final txList = await ApiService.fetchTransactions(userId: uid);
      final insightList = await ApiService.asyncFetchSurfacedInsights(userId: uid);

      if (mounted) {
        setState(() {
          if (userSummary != null) {
            _bufferBalance = userSummary['bufferBalance'] != null ? (double.tryParse(userSummary['bufferBalance'].toString()) ?? 0.0) : 0.0;
            _persona = userSummary['persona'] ?? 'Freelancer';
            _obligations = userSummary['obligations'] ?? [];
          }
          _transactions = txList;
          _insights = insightList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _executeAction(Insight ins, ActionItem action) async {
    setState(() => _actionStatus = 'Applying action...');
    final res = await ApiService.executeAction(
      insightId: ins.id,
      actionId: action.id,
      actionType: action.actionType,
      payload: action.payload,
    );

    if (mounted) {
      if (res != null && res['success'] == true) {
        setState(() {
          action.status = 'executed';
          _actionStatus = 'Success: ${res['message'] ?? 'Action Applied'}';
        });
        _loadData();
      } else {
        setState(() => _actionStatus = 'Execution Failed');
      }
    }
  }

  void _openVoiceCall(Insight ins) {
    showDialog(
      context: context,
      builder: (_) => EmergencyCallDialog(
        insight: ins,
        onActionExecuted: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate dynamic inflows and outflows
    final inflowObligations = _obligations.where((o) => o['type'] == 'inflow').toList();
    final outflowObligations = _obligations.where((o) => o['type'] == 'outflow').toList();

    final creditTransactions = _transactions.where((t) => t['type'] == 'credit').toList();
    final debitTransactions = _transactions.where((t) => t['type'] == 'debit').toList();

    final double totalInflows = inflowObligations.fold(0.0, (sum, o) => sum + (o['amount'] != null ? (double.tryParse(o['amount'].toString()) ?? 0.0) : 0.0)) +
        creditTransactions.fold(0.0, (sum, t) => sum + (t['amount'] != null ? (double.tryParse(t['amount'].toString()) ?? 0.0) : 0.0));

    final double totalOutflows = outflowObligations.fold(0.0, (sum, o) => sum + (o['amount'] != null ? (double.tryParse(o['amount'].toString()) ?? 0.0) : 0.0)) +
        debitTransactions.fold(0.0, (sum, t) => sum + (t['amount'] != null ? (double.tryParse(t['amount'].toString()) ?? 0.0) : 0.0));

    final double totalObligationsDue = outflowObligations.fold(0.0, (sum, o) => sum + (o['amount'] != null ? (double.tryParse(o['amount'].toString()) ?? 0.0) : 0.0));
    final bool hasShortfall = _bufferBalance < totalObligationsDue && totalObligationsDue > 0;
    final double deficitAmount = totalObligationsDue - _bufferBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Origin Dashboard', style: TextStyle(fontSize: 16)),
            if (AppSession.userName != null && AppSession.userName!.isNotEmpty)
              Text('Welcome, ${AppSession.userName}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                child: AppSession.userPicture != null && AppSession.userPicture!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage('http://localhost:3000/api/image-proxy?url=${Uri.encodeComponent(AppSession.userPicture!)}'),
                        radius: 16,
                      )
                    : const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 16,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1548DC)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // Top Deep Blue Banner Header
                  _buildBalanceHeader(hasShortfall, deficitAmount, totalObligationsDue),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inflow vs Outflow Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryBox(
                                'TOTAL RECEIVED',
                                _currencyFormatter.format(totalInflows),
                                '${inflowObligations.length + creditTransactions.length} Inflows logged',
                                Icons.arrow_downward_rounded,
                                const Color(0xFF00A86B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryBox(
                                'TOTAL OUTFLOWS',
                                _currencyFormatter.format(totalOutflows),
                                '${outflowObligations.length + debitTransactions.length} Debits & Obligations',
                                Icons.arrow_upward_rounded,
                                const Color(0xFF1548DC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Spend vs Income Trend Graph
                        const Text(
                          'CASH FLOW TREND (LAST 7 DAYS)',
                          style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                                        return Text(days[value.toInt()], style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 10));
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 1000),
                                    FlSpot(1, 1500),
                                    FlSpot(2, 800),
                                    FlSpot(3, 2000),
                                    FlSpot(4, 1200),
                                    FlSpot(5, 3000),
                                    FlSpot(6, 2500),
                                  ],
                                  isCurved: true,
                                  color: const Color(0xFF1548DC),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF1548DC).withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recent Transfers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'RECENT TRANSFERS',
                              style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See All', style: TextStyle(fontSize: 11, color: Color(0xFF1548DC))),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildTransferAvatar('Alex', null),
                              _buildTransferAvatar('Sarah', null),
                              _buildTransferAvatar('Mike', null),
                              _buildTransferAvatar('Emma', null),
                              _buildTransferAvatar('John', null),
                            ],
                          ),
                        ),


                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransferAvatar(String name, String? imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            backgroundColor: const Color(0xFFE5E9F2),
            child: imageUrl == null
                ? Text(
                    name.substring(0, 1),
                    style: const TextStyle(color: Color(0xFF5A6E85), fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 11.5),
      ),
    );
  }

  Widget _buildBalanceHeader(bool hasShortfall, double deficitAmount, double totalObligations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF0D32B2),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRIMARY CHECKING BUFFER',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _persona.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencyFormatter.format(_bufferBalance),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasShortfall
                        ? 'DEFICIT: -${_currencyFormatter.format(deficitAmount)}'
                        : 'HEALTHY BUFFER',
                    style: TextStyle(
                      color: hasShortfall ? const Color(0xFFC62828) : const Color(0xFF0D32B2),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalObligations > 0
                ? 'Scheduled Obligations: ${_currencyFormatter.format(totalObligations)} • State: ${hasShortfall ? 'Shortfall Warning' : 'Adequate Cushion'}'
                : 'No scheduled monthly obligations pending.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String amount, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 9.5, fontWeight: FontWeight.bold)),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(amount, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }




}


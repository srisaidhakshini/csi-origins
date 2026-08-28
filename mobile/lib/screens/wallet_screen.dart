import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../widgets/emergency_call_dialog.dart';
import 'onboarding_screen.dart';

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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of Origin Copilot?', style: TextStyle(color: Color(0xFF1C2434), fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'You will be disconnected and returned to the profile onboarding setup.',
          style: TextStyle(color: Color(0xFF5A6E85), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A99AD), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userSummary = await ApiService.fetchUserSummary();
      final txList = await ApiService.fetchTransactions();
      final insightList = await ApiService.asyncFetchSurfacedInsights();

      if (mounted) {
        setState(() {
          if (userSummary != null) {
            _bufferBalance = (userSummary['bufferBalance'] as num?)?.toDouble() ?? 0.0;
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

    final double totalInflows = inflowObligations.fold(0.0, (sum, o) => sum + (o['amount'] as num? ?? 0).toDouble()) +
        creditTransactions.fold(0.0, (sum, t) => sum + (t['amount'] as num? ?? 0).toDouble());

    final double totalOutflows = outflowObligations.fold(0.0, (sum, o) => sum + (o['amount'] as num? ?? 0).toDouble()) +
        debitTransactions.fold(0.0, (sum, t) => sum + (t['amount'] as num? ?? 0).toDouble());

    final double totalObligationsDue = outflowObligations.fold(0.0, (sum, o) => sum + (o['amount'] as num? ?? 0).toDouble());
    final bool hasShortfall = _bufferBalance < totalObligationsDue && totalObligationsDue > 0;
    final double deficitAmount = totalObligationsDue - _bufferBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Origin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: _confirmLogout,
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

                        // Section 1: Money Received From (Inflows)
                        const Text(
                          'MONEY RECEIVED FROM (INFLOWS)',
                          style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        if (inflowObligations.isEmpty && creditTransactions.isEmpty)
                          _buildEmptyPlaceholder('No income streams or credit deposits recorded yet.')
                        else ...[
                          for (final o in inflowObligations)
                            _buildInflowCard(
                              o['label']?.toString() ?? 'Income Retainer',
                              _currencyFormatter.format(o['amount'] ?? 0),
                              'Expected Monthly • Day ${o['dueDay'] ?? 1}',
                              'SCHEDULED',
                              true,
                            ),
                          for (final t in creditTransactions)
                            _buildInflowCard(
                              t['merchant']?.toString() ?? 'Credit Deposit',
                              _currencyFormatter.format(t['amount'] ?? 0),
                              'Bank Deposit • ${t['category'] ?? 'income'}',
                              'RECEIVED',
                              true,
                            ),
                        ],
                        const SizedBox(height: 20),

                        // Section 2: Money Spent On (Outflows & Obligations)
                        const Text(
                          'UPCOMING DEMANDS & RECENT SPENT',
                          style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        if (outflowObligations.isEmpty && debitTransactions.isEmpty)
                          _buildEmptyPlaceholder('No scheduled obligations or debits recorded.')
                        else ...[
                          for (final o in outflowObligations)
                            _buildOutflowCard(
                              o['label']?.toString() ?? 'Monthly Obligation',
                              _currencyFormatter.format(o['amount'] ?? 0),
                              'Scheduled Monthly • Due Day ${o['dueDay'] ?? 5}',
                              hasShortfall ? 'DEFICIT RISK' : 'COVERED',
                              hasShortfall,
                            ),
                          for (final t in debitTransactions)
                            _buildOutflowCard(
                              t['merchant']?.toString() ?? 'Debit Purchase',
                              _currencyFormatter.format(t['amount'] ?? 0),
                              'Bank Debit • ${t['category'] ?? 'spend'}',
                              'DEBITED',
                              false,
                            ),
                        ],
                        const SizedBox(height: 20),

                        // Section 3: Active Interventions & 1-Click Action Hub
                        if (_insights.isNotEmpty) ...[
                          const Text(
                            'AUTONOMOUS INTERVENTIONS (1-CLICK EXECUTE)',
                            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 8),
                          if (_actionStatus.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF1FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_actionStatus, style: const TextStyle(color: Color(0xFF1548DC), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                          ],
                          for (final ins in _insights) _buildInterventionCard(ins),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
            color: const Color(0xFF1548DC).withValues(alpha: 0.06),
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

  Widget _buildInflowCard(String payer, String amount, String details, String tag, bool isConfirmed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF1548DC), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payer, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(details, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: Color(0xFF00A86B), fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isConfirmed ? const Color(0xFFEBF1FF) : const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isConfirmed ? const Color(0xFF1548DC) : const Color(0xFF8A99AD),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutflowCard(String merchant, String amount, String category, String status, bool isAtRisk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isAtRisk ? const Color(0xFFFFEBEE) : const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAtRisk ? Icons.warning_amber_rounded : Icons.arrow_upward_rounded,
              color: isAtRisk ? const Color(0xFFC62828) : const Color(0xFF5A6E85),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchant, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(category, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAtRisk ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isAtRisk ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(Insight ins) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEBEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC62828).withValues(alpha: 0.05),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CRITICAL INTERVENTION',
                  style: TextStyle(color: Color(0xFFC62828), fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1548DC), size: 20),
                onPressed: () => _openVoiceCall(ins),
                tooltip: 'Emergency Voice Call',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ins.explanation,
            style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12.5, height: 1.35),
          ),
          if (ins.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final action in ins.actions)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: action.status == 'executed' ? null : () => _executeAction(ins, action),
                    icon: Icon(action.status == 'executed' ? Icons.check_circle : Icons.flash_on_rounded, size: 14),
                    label: Text(action.status == 'executed' ? 'Executed' : action.title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.status == 'executed' ? const Color(0xFF00A86B) : const Color(0xFF1548DC),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

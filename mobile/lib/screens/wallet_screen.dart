import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  String _actionStatus = '';

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
    final list = await ApiService.asyncFetchSurfacedInsights();
    setState(() {
      _insights = list;
      _isLoading = false;
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Origin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
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
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Top Deep Blue Banner Header
                _buildBalanceHeader(),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inflow vs Outflow Cards
                      Row(
                        children: [
                          Expanded(child: _buildSummaryBox('TOTAL RECEIVED', '₹60,000', '2 Inflows (TechCorp, Upwork)', Icons.arrow_downward_rounded, const Color(0xFF00A86B))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSummaryBox('TOTAL SPENT', '₹37,420', 'Rent, SIP & Bills', Icons.arrow_upward_rounded, const Color(0xFF1548DC))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 1: Money Received From (Inflows)
                      const Text(
                        'MONEY RECEIVED FROM (INFLOWS)',
                        style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      _buildInflowCard('TechCorp Labs', '₹35,000', 'Design Retainer Payout (Delayed 5d)', 'GIG INVOICE', false),
                      _buildInflowCard('Upwork Global', '₹25,000', 'Mobile Dev Milestone Payout', 'CONFIRMED', true),
                      const SizedBox(height: 20),

                      // Section 2: Money Spent On (Outflows & Obligations)
                      const Text(
                        'UPCOMING DEMANDS & RECENT SPENT',
                        style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      _buildOutflowCard('Apartment Rent (Survival)', '₹28,000', 'Landlord A/C • Due in 4 days', 'SHORTFALL', true),
                      _buildOutflowCard('Parag Parikh Flexi Cap SIP', '₹5,000', 'BSE Star MF • Due in 9 days', 'AT RISK', true),
                      _buildOutflowCard('BESCOM Electricity & ACT Broadband', '₹3,500', 'Utility Auto-Debits', 'COVERED', false),
                      _buildOutflowCard('Swiggy Food & Dining', '₹920', 'Discretionary Dining', 'DEBITED', false),
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
    );
  }

  Widget _buildBalanceHeader() {
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
                child: const Text(
                  'HDFC A/C **4092',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEFICIT: -₹16,000',
                  style: TextStyle(color: Color(0xFF0D32B2), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Target Minimum Cushion: ₹15,000 • Runway: 4 Days till Rent Default',
            style: TextStyle(color: Colors.white70, fontSize: 11),
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

  Widget _buildInflowCard(String payer, String amount, String details, String tag, bool isConfirmed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payer, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(details, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10)),
                ],
              ),
            ],
          ),
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
                  style: TextStyle(color: isConfirmed ? const Color(0xFF1548DC) : const Color(0xFF8A99AD), fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutflowCard(String merchant, String amount, String details, String tag, bool isCritical) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCritical ? Border.all(color: const Color(0xFF1548DC).withOpacity(0.3), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFFEBF1FF) : const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_upward_rounded, color: isCritical ? const Color(0xFF1548DC) : const Color(0xFF8A99AD), size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchant, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(details, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFF0D32B2) : const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(color: isCritical ? Colors.white : const Color(0xFF8A99AD), fontSize: 8.5, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1548DC).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: const Color(0xFF0D32B2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ins.triggerType == 'cascade' ? 'CASCADE DEFICIT' : 'BEHAVIORAL WARNING',
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () => _openVoiceCall(ins),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF1FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1548DC), size: 12),
                      SizedBox(width: 4),
                      Text('VOICE CALL', style: TextStyle(color: Color(0xFF1548DC), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(ins.explanation, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          for (final act in ins.actions)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(act.title, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  act.status == 'executed'
                      ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF00A86B), borderRadius: BorderRadius.circular(6)), child: const Text('APPLIED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))
                      : ElevatedButton(
                          onPressed: () => _executeAction(ins, act),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1548DC),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('EXECUTE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

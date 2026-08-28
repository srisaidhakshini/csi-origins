import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../widgets/emergency_call_dialog.dart';
import 'onboarding_screen.dart';
import '../widgets/cashflow_chart_card.dart';

class WalletTransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isReceived; // true = +, false = -
  final String tag;
  final String dateLabel;
  final IconData icon;
  final bool isCritical;
  final bool isConfirmed;

  const WalletTransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isReceived,
    required this.tag,
    required this.dateLabel,
    required this.icon,
    this.isCritical = false,
    this.isConfirmed = false,
  });
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Insight> _insights = [];
  bool _isLoading = true;
  String _actionStatus = '';
  String _transactionFilter = 'ALL'; // 'ALL', 'RECEIVED', 'SENT'

  final List<WalletTransactionItem> _transactions = const [
    WalletTransactionItem(
      id: 'tx_1',
      title: 'TechCorp Labs',
      subtitle: 'Design Retainer Payout (Delayed 5d)',
      amount: 35000,
      isReceived: true,
      tag: 'GIG INVOICE',
      dateLabel: 'Est. Sep 01',
      icon: Icons.work_outline_rounded,
      isConfirmed: false,
    ),
    WalletTransactionItem(
      id: 'tx_2',
      title: 'Apartment Rent (Survival)',
      subtitle: 'Landlord A/C • Due in 4 days',
      amount: 28000,
      isReceived: false,
      tag: 'SHORTFALL RISK',
      dateLabel: 'Due Sep 02',
      icon: Icons.home_work_outlined,
      isCritical: true,
    ),
    WalletTransactionItem(
      id: 'tx_3',
      title: 'Upwork Global',
      subtitle: 'Mobile Dev Milestone Payout',
      amount: 25000,
      isReceived: true,
      tag: 'CONFIRMED',
      dateLabel: 'Settled Today',
      icon: Icons.account_balance_wallet_outlined,
      isConfirmed: true,
    ),
    WalletTransactionItem(
      id: 'tx_4',
      title: 'Parag Parikh Flexi Cap SIP',
      subtitle: 'BSE Star MF • Due in 9 days',
      amount: 5000,
      isReceived: false,
      tag: 'AT RISK',
      dateLabel: 'Due Sep 07',
      icon: Icons.trending_up_rounded,
      isCritical: true,
    ),
    WalletTransactionItem(
      id: 'tx_5',
      title: 'BESCOM Electricity & ACT Broadband',
      subtitle: 'Utility Auto-Debits Scheduled',
      amount: 3500,
      isReceived: false,
      tag: 'COVERED',
      dateLabel: 'Due Sep 17',
      icon: Icons.bolt_rounded,
    ),
    WalletTransactionItem(
      id: 'tx_6',
      title: 'Swiggy Food & Dining',
      subtitle: 'Discretionary Debit Normalized',
      amount: 920,
      isReceived: false,
      tag: 'DEBITED',
      dateLabel: 'Paid Yesterday',
      icon: Icons.restaurant_rounded,
    ),
  ];

  String _userName = 'Gowreesh';
  String _userArchetype = 'User';
  String _netWorth = '₹1,92,050.78';

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
    final results = await Future.wait([
      ApiService.asyncFetchSurfacedInsights(),
      ApiService.fetchUserProfile(),
    ]);

    if (mounted) {
      final list = results[0] as List<Insight>;
      final profile = results[1] as Map<String, dynamic>?;

      setState(() {
        _insights = list;
        if (profile != null) {
          if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
            _userName = profile['name'];
          }
          if (profile['archetype'] != null && profile['archetype'].toString().isNotEmpty) {
            _userArchetype = profile['archetype'];
          }
          if (profile['netWorth'] != null && profile['netWorth'].toString().isNotEmpty) {
            _netWorth = profile['netWorth'];
          }
        }
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final archetypeController = TextEditingController(text: _userArchetype);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_outline_rounded, color: Color(0xFF1548DC), size: 22),
            SizedBox(width: 8),
            Text('Edit User Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DISPLAY NAME', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Gowreesh, Alex, Dhakshesh',
                filled: true,
                fillColor: const Color(0xFFF4F7FC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 14),
            const Text('OCCUPATION / ARCHETYPE', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: archetypeController,
              decoration: InputDecoration(
                hintText: 'e.g. Freelance Designer, Consultant',
                filled: true,
                fillColor: const Color(0xFFF4F7FC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF5A6E85), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newArchetype = archetypeController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _userName = newName;
                  if (newArchetype.isNotEmpty) _userArchetype = newArchetype;
                });
                Navigator.pop(ctx);
                await ApiService.updateUserProfile(name: newName, archetype: newArchetype);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1548DC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  List<WalletTransactionItem> get _filteredTransactions {
    if (_transactionFilter == 'RECEIVED') {
      return _transactions.where((t) => t.isReceived).toList();
    } else if (_transactionFilter == 'SENT') {
      return _transactions.where((t) => !t.isReceived).toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Row(
          children: [
            Icon(Icons.pie_chart_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Overview & Cashflow'),
          ],
        ),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // 1. Top Executive Net Worth & Balance Trend Hero Card (Dynamic User Name & Monthly View)
                CashflowChartCard(
                  userName: _userName,
                  archetype: _userArchetype,
                  netWorth: _netWorth,
                  topAmount: '₹6,575.42',
                  startAmount: '₹3,022.22',
                  startDate: 'Aug 01',
                  endDate: 'Aug 31',
                  timeRangeLabel: 'This Month',
                  thisMonthChange: '-₹599',
                  thisYearChange: '-₹4,546',
                  onEditProfile: _showEditProfileDialog,
                ),
                const SizedBox(height: 14),

                // 2. Inflow vs Outflow Metric Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryBox(
                              'TOTAL RECEIVED',
                              '+₹60,000',
                              '2 Inflows (Retainer & Milestone)',
                              Icons.south_west_rounded,
                              const Color(0xFF00A86B),
                              const Color(0xFFE8F8F0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryBox(
                              'TOTAL SENT / SPENT',
                              '-₹37,420',
                              'Rent, SIP & Bills',
                              Icons.north_east_rounded,
                              const Color(0xFF1548DC),
                              const Color(0xFFEBF1FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Grouped Transactions Section (Money Sent & Received together with +/-)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GROUPED MONEY FLOW & ACTIVITY',
                                style: TextStyle(
                                  color: Color(0xFF5A6E85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'All Inflows (+) & Outflows (-) Together',
                                style: TextStyle(
                                  color: Color(0xFF8A99AD),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // Quick filter chips
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAEFF8),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              children: [
                                _buildFilterChip('ALL', 'All'),
                                _buildFilterChip('RECEIVED', '+ In'),
                                _buildFilterChip('SENT', '- Out'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // List of Grouped Transactions
                      for (final tx in _filteredTransactions)
                        _buildGroupedTransactionCard(tx),

                      const SizedBox(height: 22),

                      // 5. Active Autonomous Interventions Section
                      if (_insights.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1548DC).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.shield_rounded, color: Color(0xFF1548DC), size: 14),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AUTONOMOUS INTERVENTIONS (1-CLICK EXECUTE)',
                              style: TextStyle(
                                color: Color(0xFF5A6E85),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_actionStatus.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF1FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1548DC).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF1548DC), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _actionStatus,
                                    style: const TextStyle(
                                      color: Color(0xFF1548DC),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        for (final ins in _insights) _buildInterventionCard(ins),
                      ],
              ],
            ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _transactionFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _transactionFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1548DC) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5A6E85),
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D32B2),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRIMARY CHECKING BUFFER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'HDFC A/C **4092',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '₹12,000',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEFICIT: -₹16,000',
                  style: TextStyle(color: Color(0xFFE53935), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Target Safe Cushion: ₹15,000 • Runway: 4 Days till Rent Default',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBF1FF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF5A6E85),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              color: iconColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 9.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTransactionCard(WalletTransactionItem tx) {
    final isPositive = tx.isReceived;
    final formattedAmt = tx.amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: tx.isCritical
            ? Border.all(color: const Color(0xFFE53935).withOpacity(0.35), width: 1.2)
            : Border.all(color: const Color(0xFFF0F4FA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Direction Icon + Title & Subtitle
          Expanded(
            child: Row(
              children: [
                // Inflow vs Outflow Icon Indicator
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFFE8F8F0) : const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPositive
                          ? const Color(0xFF00A86B).withOpacity(0.2)
                          : const Color(0xFF1548DC).withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isPositive ? Icons.south_west_rounded : Icons.north_east_rounded,
                    color: isPositive ? const Color(0xFF00A86B) : const Color(0xFF1548DC),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Payer / Merchant & Subtitle Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          color: Color(0xFF1C2434),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            tx.dateLabel,
                            style: const TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tx.subtitle,
                              style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right: + / - Amount & Status Tag
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}₹$formattedAmt',
                style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF00A86B)
                      : (tx.isCritical ? const Color(0xFFE53935) : const Color(0xFF1C2434)),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? (tx.isConfirmed ? const Color(0xFFE8F8F0) : const Color(0xFFFFF7ED))
                      : (tx.isCritical ? const Color(0xFFFFECEC) : const Color(0xFFF1F3F7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.tag,
                  style: TextStyle(
                    color: isPositive
                        ? (tx.isConfirmed ? const Color(0xFF00A86B) : const Color(0xFFD97706))
                        : (tx.isCritical ? const Color(0xFFE53935) : const Color(0xFF5A6E85)),
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
                      Text(
                        'VOICE CALL',
                        style: TextStyle(color: Color(0xFF1548DC), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ins.explanation,
            style: const TextStyle(
              color: Color(0xFF1C2434),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
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
                    child: Text(
                      act.title,
                      style: const TextStyle(color: Color(0xFF1C2434), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  act.status == 'executed'
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A86B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('APPLIED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        )
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

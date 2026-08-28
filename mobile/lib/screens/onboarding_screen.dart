import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form state
  String _selectedPersona = 'Freelance Designer';
  final _bufferController = TextEditingController(text: '12000');
  final _primaryIncomeController = TextEditingController(text: '35000');
  final _incomeLabelController = TextEditingController(text: 'TechCorp Design Retainer');
  final _rentController = TextEditingController(text: '28000');
  final _sipController = TextEditingController(text: '5000');
  String _riskProfile = 'medium';
  bool _isGmailConnected = true;
  bool _isSmsConnected = true;

  @override
  void dispose() {
    _pageController.dispose();
    _bufferController.dispose();
    _primaryIncomeController.dispose();
    _incomeLabelController.dispose();
    _rentController.dispose();
    _sipController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D32B2),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header with Step Counter & Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ORIGIN COPILOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = _currentStep == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 5),
                        width: isActive ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Main White Curved Page Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  children: [
                    _buildStep1Persona(),
                    _buildStep2Buffer(),
                    _buildStep3Inflows(),
                    _buildStep4Obligations(),
                    _buildStep5Connectors(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Welcome & Persona
  Widget _buildStep1Persona() {
    return _buildStepWrapper(
      title: 'Autonomous Financial Management',
      subtitle: 'Continuously models your evolving cashflow, upcoming rent obligations, and variable income.',
      svgPath: 'assets/illustrations/undraw_personal-finance_xpqg.svg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT YOUR EARNER ARCHETYPE:',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _buildSelectableCard(
            'Freelance Designer / Developer',
            'Variable retainer billing & milestone payouts',
            _selectedPersona == 'Freelance Designer',
            () => setState(() => _selectedPersona = 'Freelance Designer'),
          ),
          _buildSelectableCard(
            'Gig / Platform Worker',
            'Weekly payouts from Uber, Swiggy, Upwork',
            _selectedPersona == 'Gig Worker',
            () => setState(() => _selectedPersona = 'Gig Worker'),
          ),
          _buildSelectableCard(
            'Informal / Consultant',
            'Unscheduled client invoices & retainer contracts',
            _selectedPersona == 'Consultant',
            () => setState(() => _selectedPersona = 'Consultant'),
          ),
        ],
      ),
    );
  }

  // STEP 2: Checking Buffer
  Widget _buildStep2Buffer() {
    return _buildStepWrapper(
      title: 'Checking Buffer Baseline',
      subtitle: 'Set your primary account liquid cushion to calculate shortfall runway.',
      svgPath: 'assets/illustrations/undraw_budget-adjustments_7fj9.svg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField('PRIMARY BANK / ACCOUNT', 'HDFC Bank **4092 (Primary Checking)'),
          const SizedBox(height: 12),
          _buildEditableField('CURRENT LIQUID BUFFER BALANCE (₹)', _bufferController, isNumber: true, hint: '12000'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF1548DC), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your buffer absorbs delayed gig payouts and protects against rent bounces.',
                    style: TextStyle(color: Color(0xFF1548DC), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Variable Inflows
  Widget _buildStep3Inflows() {
    return _buildStepWrapper(
      title: 'Variable Income Streams',
      subtitle: 'Register your primary client retainers and expected payout intervals.',
      svgPath: 'assets/illustrations/undraw_freelancer_vibs.svg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField('PRIMARY INCOME SOURCE LABEL', _incomeLabelController, hint: 'TechCorp Design Retainer'),
          const SizedBox(height: 12),
          _buildEditableField('EXPECTED MONTHLY PAYOUT (₹)', _primaryIncomeController, isNumber: true, hint: '35000'),
          const SizedBox(height: 12),
          _buildInputField('SECONDARY INFLOW PLATFORMS', 'Upwork Global (Milestones), Stripe Invoices'),
        ],
      ),
    );
  }

  // STEP 4: Fixed Obligations
  Widget _buildStep4Obligations() {
    return _buildStepWrapper(
      title: 'Survival Deadlines & Obligations',
      subtitle: 'Map your critical monthly obligations into the PostgreSQL causal graph.',
      svgPath: 'assets/illustrations/undraw_schedule_ry1w.svg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField('MONTHLY APARTMENT RENT (₹) [DUE DAY 5]', _rentController, isNumber: true, hint: '28000'),
          const SizedBox(height: 12),
          _buildEditableField('MUTUAL FUND SIP (₹) [DUE DAY 10]', _sipController, isNumber: true, hint: '5000'),
          const SizedBox(height: 12),
          _buildInputField('FIXED UTILITY BILLS', 'BESCOM Electricity & ACT Broadband (₹3,500)'),
        ],
      ),
    );
  }

  // STEP 5: Connectors & Launch
  Widget _buildStep5Connectors() {
    return _buildStepWrapper(
      title: 'Connect Continuous Streams',
      subtitle: 'Continuously ingest fragmented financial notifications to corroborate data without double-counting.',
      svgPath: 'assets/illustrations/undraw_personal-email_hfut.svg',
      buttonText: 'LAUNCH FINANCIAL COPILOT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleRow('GOOGLE / GMAIL OAUTH SYNC', 'Auto-parse invoices, BSE Star MF statements', _isGmailConnected, (val) => setState(() => _isGmailConnected = val)),
          const SizedBox(height: 10),
          _buildToggleRow('BANK SMS PARSER ENGINE', 'Real-time Cashiro debit/credit normalization', _isSmsConnected, (val) => setState(() => _isSmsConnected = val)),
          const SizedBox(height: 14),
          const Text('RISK SENSITIVITY PROFILE:', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRiskOption('Conservative (Low)', 'low'),
              const SizedBox(width: 10),
              _buildRiskOption('Standard (Medium)', 'medium'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepWrapper({
    required String title,
    required String subtitle,
    required String svgPath,
    required Widget child,
    String buttonText = 'CONTINUE',
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SVG Illustration Container
          Center(
            child: Container(
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SvgPicture.asset(
                svgPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1C2434),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5A6E85),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          child,
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1548DC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: const Color(0xFF1548DC).withOpacity(0.35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableCard(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1548DC) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1548DC).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF1548DC) : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF1C2434), fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool isNumber = false, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1548DC).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Color(0xFF1C2434), fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1548DC).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF1C2434), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF1C2434), fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF1548DC),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskOption(String label, String value) {
    final isSelected = _riskProfile == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _riskProfile = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1548DC) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1548DC).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1C2434),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

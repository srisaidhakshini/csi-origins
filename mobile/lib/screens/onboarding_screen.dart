import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Role
  String _selectedRole = 'Freelancer';

  // Step 2: Finances
  final _balanceController = TextEditingController();
  final _incomeController = TextEditingController();
  final _incomeLabelController = TextEditingController();

  // Step 3: Gmail
  bool _gmailEnabled = false;
  bool _gmailConnected = false;

  // Step 4: SMS + Risk
  bool _smsEnabled = false;
  String _riskProfile = 'medium';

  static const int _totalSteps = 4;

  final _roles = [
    _RoleOption(id: 'Student', label: 'Student', sub: 'Scholarship / part-time income', svgPath: _svgStudent),
    _RoleOption(id: 'Freelancer', label: 'Freelancer', sub: 'Project-based / gig income', svgPath: _svgFreelancer),
    _RoleOption(id: 'Salaried', label: 'Salaried', sub: 'Fixed monthly salary', svgPath: _svgSalaried),
    _RoleOption(id: 'Business Owner', label: 'Business', sub: 'Business revenue & expenses', svgPath: _svgBusiness),
    _RoleOption(id: 'Retired', label: 'Retired', sub: 'Pension / investment income', svgPath: _svgRetired),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1 / _totalSteps,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _balanceController.dispose();
    _incomeController.dispose();
    _incomeLabelController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final balance = double.tryParse(_balanceController.text.replaceAll(',', '').trim()) ?? 0.0;
    final income = double.tryParse(_incomeController.text.replaceAll(',', '').trim()) ?? 0.0;
    final label = _incomeLabelController.text.trim().isNotEmpty
        ? _incomeLabelController.text.trim()
        : 'Monthly Income';

    final success = await ApiService.submitOnboarding(
      userId: widget.userId,
      persona: _selectedRole,
      bufferBalance: balance,
      primaryIncome: income,
      incomeLabel: label,
      rentAmount: 0,
      sipAmount: 0,
      riskProfile: _riskProfile,
      smsEnabled: _smsEnabled,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save profile. Make sure backend is running.'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    }
  }

  void _connectGmail() {
    AudioService.openUrl('${ApiService.baseUrl}/auth/google/connect-gmail?state=${widget.userId}', usePopup: true);
    setState(() => _gmailConnected = true);
  }

  bool get _canProceed {
    if (_currentStep == 1) {
      return _balanceController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Header ───────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        GestureDetector(
                          onTap: _prevPage,
                          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1548DC), size: 22),
                        )
                      else
                        const SizedBox(width: 22),
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: const TextStyle(
                          color: Color(0xFF5A6E85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 22),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: const Color(0xFFEBF1FF),
                      color: const Color(0xFF1548DC),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Page Content ──────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildRoleStep(),
                  _buildFinancesStep(),
                  _buildGmailStep(),
                  _buildSmsRiskStep(),
                ],
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_canProceed && !_isSubmitting) ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1548DC),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEBF1FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1 ? 'Launch Finova →' : 'Continue →',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Role ────────────────────────────────────────────────────────────
  Widget _buildRoleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Who are you?',
            style: TextStyle(color: Color(0xFF1C2434), fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Finova adapts its intelligence to your financial pattern.',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          ...(_roles.map((role) => _RoleCard(
                role: role,
                isSelected: _selectedRole == role.id,
                onTap: () => setState(() => _selectedRole = role.id),
              ))),
        ],
      ),
    );
  }

  // ── Step 2: Finances ────────────────────────────────────────────────────────
  Widget _buildFinancesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: SvgPicture.string(_svgWallet, width: 120, height: 120),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your finances',
            style: TextStyle(color: Color(0xFF1C2434), fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'This helps Finova understand your baseline and alert you accurately.',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),

          _InputLabel('Current Bank Balance *'),
          const SizedBox(height: 6),
          _MoneyField(
            controller: _balanceController,
            hint: 'e.g. 25,000',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          const Text(
            'Checking / savings balance right now',
            style: TextStyle(color: Color(0xFF8A99AD), fontSize: 11),
          ),

          const SizedBox(height: 22),

          _InputLabel('Monthly Income (optional)'),
          const SizedBox(height: 6),
          _MoneyField(
            controller: _incomeController,
            hint: 'e.g. 40,000',
            onChanged: (_) {},
          ),

          const SizedBox(height: 22),

          _InputLabel('Income Source (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _incomeLabelController,
            style: const TextStyle(color: Color(0xFF1C2434), fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _inputDecor('e.g. Upwork Freelance / Company Salary'),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Gmail ───────────────────────────────────────────────────────────
  Widget _buildGmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(child: SvgPicture.string(_svgGmail, width: 100, height: 100)),
          const SizedBox(height: 20),
          const Text(
            'Gmail Transaction\nParser',
            style: TextStyle(color: Color(0xFF1C2434), fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finova reads only bank alert emails (debit/credit notifications). Your personal emails are never accessed.',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 28),

          // Toggle Card
          _ToggleCard(
            icon: _svgGmailSmall,
            title: 'Enable Gmail Parsing',
            subtitle: 'Auto-detect transactions from bank email alerts',
            value: _gmailEnabled,
            onChanged: (v) => setState(() => _gmailEnabled = v),
          ),
          const SizedBox(height: 16),

          // Authorize button
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _gmailEnabled ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                GestureDetector(
                  onTap: _connectGmail,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gmailConnected ? const Color(0xFFEBF1FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _gmailConnected ? const Color(0xFF1548DC) : const Color(0xFFE0E8F5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.string(_svgGoogleG, width: 22, height: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _gmailConnected ? '✓ Google Account Authorized' : 'Authorize Google Account',
                                style: TextStyle(
                                  color: _gmailConnected ? const Color(0xFF1548DC) : const Color(0xFF1C2434),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _gmailConnected
                                    ? 'Gmail parser is active'
                                    : 'Opens Google sign-in in your browser',
                                style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _gmailConnected ? Icons.check_circle_rounded : Icons.open_in_new_rounded,
                          color: _gmailConnected ? const Color(0xFF1548DC) : const Color(0xFF8A99AD),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF1548DC), size: 15),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'After authorizing, return to this tab and continue.',
                          style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),
          const _PrivacyNote(),
        ],
      ),
    );
  }

  // ── Step 4: SMS + Risk ──────────────────────────────────────────────────────
  Widget _buildSmsRiskStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(child: SvgPicture.string(_svgPhone, width: 100, height: 100)),
          const SizedBox(height: 20),
          const Text(
            'Final setup',
            style: TextStyle(color: Color(0xFF1C2434), fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'SMS bank alerts and your financial risk tolerance.',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),

          // SMS Toggle
          _ToggleCard(
            icon: _svgSms,
            title: 'Live SMS Bank Alerts',
            subtitle: kIsWeb
                ? 'Available on Android only — skip for now'
                : 'Intercept real-time debit/credit SMS messages',
            value: _smsEnabled && !kIsWeb,
            onChanged: kIsWeb ? null : (v) => setState(() => _smsEnabled = v),
            disabled: kIsWeb,
          ),

          const SizedBox(height: 20),

          const Text(
            'RISK TOLERANCE',
            style: TextStyle(
              color: Color(0xFF5A6E85),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RiskPill(label: 'Low', id: 'low', selected: _riskProfile == 'low', onTap: () => setState(() => _riskProfile = 'low')),
              const SizedBox(width: 10),
              _RiskPill(label: 'Medium', id: 'medium', selected: _riskProfile == 'medium', onTap: () => setState(() => _riskProfile = 'medium')),
              const SizedBox(width: 10),
              _RiskPill(label: 'High', id: 'high', selected: _riskProfile == 'high', onTap: () => setState(() => _riskProfile = 'high')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _riskProfile == 'low'
                ? 'Finova alerts you early and often. Best for tight budgets.'
                : _riskProfile == 'medium'
                    ? 'Balanced alerts — notified at moderate risk thresholds.'
                    : 'Only critical alerts. Best for experienced money managers.',
            style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 12, height: 1.5),
          ),

          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D32B2), Color(0xFF1548DC)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'re all set!',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Tap "Launch Finova" to activate your financial copilot.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────────

class _RoleOption {
  final String id, label, sub, svgPath;
  const _RoleOption({required this.id, required this.label, required this.sub, required this.svgPath});
}

class _RoleCard extends StatelessWidget {
  final _RoleOption role;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleCard({required this.role, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1548DC) : const Color(0xFFE0E8F5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1548DC).withOpacity(0.08) : const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.string(role.svgPath, width: 28, height: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF1548DC) : const Color(0xFF1C2434),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.sub,
                    style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF1548DC), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String icon, title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? const Color(0xFF1548DC).withOpacity(0.3) : const Color(0xFFE0E8F5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFFF1F3F7) : (value ? const Color(0xFFEBF1FF) : const Color(0xFFF4F7FC)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.string(icon, width: 26, height: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: disabled ? const Color(0xFF8A99AD) : const Color(0xFF1C2434),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeColor: const Color(0xFF1548DC),
          ),
        ],
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  final String label, id;
  final bool selected;
  final VoidCallback onTap;
  const _RiskPill({required this.label, required this.id, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1548DC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? const Color(0xFF1548DC) : const Color(0xFFE0E8F5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF5A6E85),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
    );
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _MoneyField({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(color: Color(0xFF1C2434), fontSize: 16, fontWeight: FontWeight.w700),
      decoration: _inputDecor(hint).copyWith(
        prefixText: '₹ ',
        prefixStyle: const TextStyle(color: Color(0xFF5A6E85), fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF1548DC), size: 15),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your Gmail access is read-only. Finova only reads bank notification subjects — never personal emails. You can revoke access anytime from Google Account settings.',
              style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecor(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFB0BBC9), fontWeight: FontWeight.w500),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE0E8F5)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE0E8F5)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF1548DC), width: 1.5),
  ),
);

// ─── SVG Assets ────────────────────────────────────────────────────────────────

const _svgStudent = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <path d="M24 6L4 16l20 10 20-10L24 6z" fill="#1548DC" opacity="0.15"/>
  <path d="M24 6L4 16l20 10 20-10L24 6z" stroke="#1548DC" stroke-width="2" stroke-linejoin="round"/>
  <path d="M4 16v12M44 16v8" stroke="#1548DC" stroke-width="2" stroke-linecap="round"/>
  <path d="M12 20v10c0 0 4 6 12 6s12-6 12-6V20" stroke="#1548DC" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

const _svgFreelancer = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <rect x="8" y="10" width="32" height="28" rx="4" stroke="#1548DC" stroke-width="2"/>
  <path d="M8 18h32" stroke="#1548DC" stroke-width="2"/>
  <path d="M16 26h6M16 32h10" stroke="#1548DC" stroke-width="2" stroke-linecap="round"/>
  <circle cx="34" cy="32" r="5" fill="#1548DC" opacity="0.15" stroke="#1548DC" stroke-width="2"/>
  <path d="M32 32l1.5 1.5L36 30" stroke="#1548DC" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgSalaried = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <rect x="10" y="6" width="28" height="36" rx="4" stroke="#1548DC" stroke-width="2"/>
  <path d="M10 18h28" stroke="#1548DC" stroke-width="2"/>
  <circle cx="24" cy="12" r="3" fill="#1548DC" opacity="0.3"/>
  <path d="M18 26h12M18 32h8" stroke="#1548DC" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _svgBusiness = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <path d="M8 38V22l16-12 16 12v16H8z" stroke="#1548DC" stroke-width="2" stroke-linejoin="round"/>
  <rect x="18" y="28" width="12" height="10" rx="2" stroke="#1548DC" stroke-width="2"/>
  <path d="M24 10v2" stroke="#1548DC" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _svgRetired = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <circle cx="24" cy="18" r="8" stroke="#1548DC" stroke-width="2"/>
  <path d="M10 40c0-7.73 6.27-14 14-14s14 6.27 14 14" stroke="#1548DC" stroke-width="2" stroke-linecap="round"/>
  <path d="M28 38l4-4M20 38l-4-4" stroke="#1548DC" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _svgWallet = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" fill="none">
  <rect x="10" y="35" width="100" height="70" rx="14" fill="#EBF1FF"/>
  <rect x="10" y="35" width="100" height="70" rx="14" stroke="#1548DC" stroke-width="2.5"/>
  <path d="M10 55h100" stroke="#1548DC" stroke-width="2"/>
  <rect x="70" y="65" width="30" height="20" rx="6" fill="#1548DC" opacity="0.15" stroke="#1548DC" stroke-width="2"/>
  <circle cx="85" cy="75" r="4" fill="#1548DC" opacity="0.5"/>
  <rect x="25" y="10" width="70" height="30" rx="8" fill="#F4F7FC" stroke="#B0C4DE" stroke-width="1.5"/>
  <path d="M35 25h50" stroke="#B0C4DE" stroke-width="2" stroke-linecap="round"/>
  <path d="M35 32h30" stroke="#B0C4DE" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _svgGmail = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="20" fill="#EBF1FF"/>
  <path d="M20 30h60l-30 25L20 30z" fill="#1548DC" opacity="0.6"/>
  <rect x="20" y="30" width="60" height="45" rx="3" stroke="#1548DC" stroke-width="2.5" fill="none"/>
  <path d="M20 30l30 25 30-25" stroke="#1548DC" stroke-width="2.5" stroke-linejoin="round" fill="none"/>
  <path d="M20 65V35" stroke="#1548DC" stroke-width="2.5" fill="none"/>
  <path d="M80 65V35" stroke="#1548DC" stroke-width="2.5" fill="none"/>
</svg>
''';

const _svgGmailSmall = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 28" fill="none">
  <rect x="4" y="7" width="20" height="14" rx="2" stroke="#1548DC" stroke-width="1.5"/>
  <path d="M4 9l10 8 10-8" stroke="#1548DC" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgPhone = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none">
  <rect width="100" height="100" rx="20" fill="#EBF1FF"/>
  <rect x="28" y="12" width="44" height="76" rx="10" fill="white" stroke="#1548DC" stroke-width="2.5"/>
  <rect x="34" y="18" width="32" height="56" rx="6" fill="#F4F7FC"/>
  <circle cx="50" cy="82" r="3" fill="#1548DC" opacity="0.4"/>
  <rect x="40" y="10" width="20" height="4" rx="2" fill="#1548DC" opacity="0.3"/>
  <path d="M38 35h24M38 43h16M38 51h20" stroke="#1548DC" stroke-width="2" stroke-linecap="round" opacity="0.5"/>
</svg>
''';

const _svgSms = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 28" fill="none">
  <rect x="2" y="5" width="20" height="14" rx="3" stroke="#1548DC" stroke-width="1.5"/>
  <path d="M6 23l4-4h12V9" stroke="#1548DC" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M6 11h10M6 15h6" stroke="#1548DC" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

const _svgGoogleG = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

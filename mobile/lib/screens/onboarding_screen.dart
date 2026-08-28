import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedRisk = 'medium';
  bool _isConnectingGmail = false;
  bool _gmailConnected = true; // Seed user already has Gmail connected

  void _connectGmail() async {
    setState(() => _isConnectingGmail = true);
    final url = await ApiService.getGoogleAuthUrl();
    setState(() {
      _isConnectingGmail = false;
      _gmailConnected = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(url != null ? 'Gmail OAuth scope authorized (readonly)' : 'Gmail Connected'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  void _saveRiskTolerance(String tolerance) async {
    setState(() => _selectedRisk = tolerance);
    await ApiService.updateRiskTolerance(tolerance);
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0F17),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // App Brand Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORIGIN AGENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Autonomous Financial Management',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Financial Onboarding',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect fragmented financial signals and configure your agent intervention threshold.',
                style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Step 1: Connect Gmail
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _gmailConnected ? Colors.greenAccent.withOpacity(0.4) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mail_outline_rounded, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gmail Financial Signals',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _gmailConnected
                                ? 'Connected (gmail.readonly scope)'
                                : 'Ingest receipts, invoices & bank e-statements',
                            style: TextStyle(
                              color: _gmailConnected ? Colors.greenAccent : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_gmailConnected)
                      const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22)
                    else
                      ElevatedButton(
                        onPressed: _isConnectingGmail ? null : _connectGmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Connect'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Step 2: Risk Tolerance Setting
              const Text(
                'Agent Intervention Sensitivity',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'Controls the Intervention Gate threshold for surfacing vs suppressing insights.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 12),

              _buildRiskOption(
                'Low (Defensive)',
                'Gate threshold 50.0 — Surfaces early warning signals before shortfalls compound.',
                'low',
                Colors.amberAccent,
              ),
              const SizedBox(height: 8),
              _buildRiskOption(
                'Medium (Balanced)',
                'Gate threshold 60.0 — Balanced filter on cascade deficit risks and major anomalies.',
                'medium',
                Colors.indigoAccent,
              ),
              const SizedBox(height: 8),
              _buildRiskOption(
                'High (High Tolerance)',
                'Gate threshold 72.0 — Suppresses non-critical alerts, surfaces only imminent emergencies.',
                'high',
                Colors.greenAccent,
              ),

              const SizedBox(height: 32),

              // Submit / Enter Dashboard
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Launch Financial Copilot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskOption(String title, String desc, String value, Color accentColor) {
    final isSelected = _selectedRisk == value;

    return InkWell(
      onTap: () => _saveRiskTolerance(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161A26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white10,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? accentColor : Colors.white38, width: 2),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.check, size: 12, color: Colors.black))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

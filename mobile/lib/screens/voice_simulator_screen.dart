import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class VoiceSimulatorScreen extends StatefulWidget {
  const VoiceSimulatorScreen({super.key});

  @override
  State<VoiceSimulatorScreen> createState() => _VoiceSimulatorScreenState();
}

class _VoiceSimulatorScreenState extends State<VoiceSimulatorScreen> {
  bool _isPlaying = false;
  String _statusMessage = 'Ready for emergency voice simulation';
  String _callNarrative = 'Origin Copilot Emergency Warning: Your ₹35,000 design retainer from TechCorp Labs is delayed by 5 days. With only ₹12,000 in your primary checking buffer, you face an upcoming ₹16,000 shortfall on your ₹28,000 Apartment Rent due on Day 5. An auto-drafted payment reminder to TechCorp is ready for your 1-click approval.';

  @override
  void dispose() {
    AudioService.stop();
    super.dispose();
  }

  void _playEmergencyCall() {
    AudioService.playRingtone();
    setState(() {
      _isPlaying = true;
      _statusMessage = 'Call Connected • Copilot speaking out loud...';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      AudioService.speak(_callNarrative);
    });
  }

  void _stopCall() {
    AudioService.stop();
    setState(() {
      _isPlaying = false;
      _statusMessage = 'Call Disconnected';
    });
  }

  void _triggerDelaySimulation(int days) async {
    setState(() => _statusMessage = 'Triggering $days-day income delay in Postgres CTE graph...');
    final res = await ApiService.triggerDelayedIncome(delayDays: days);
    if (res != null && res['insight'] != null) {
      final ins = res['insight'];
      setState(() {
        _callNarrative = ins['explanation'] ?? _callNarrative;
        _statusMessage = 'Cascade Deficit Detected • Connecting Emergency Call...';
      });
      _playEmergencyCall();
    }
  }

  void _executeCounterAction(String title) async {
    setState(() => _statusMessage = 'Executing $title...');
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _statusMessage = 'Success: $title applied to causal state');
    AudioService.speak('$title executed successfully.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Voice Alert & Simulator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Call Interface Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF1FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1548DC), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Origin Copilot Alert',
                              style: TextStyle(color: Color(0xFF1C2434), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Voice Briefing Channel',
                              style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isPlaying ? const Color(0xFF1548DC) : const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isPlaying ? 'SPEAKING' : 'STANDBY',
                        style: TextStyle(
                          color: _isPlaying ? Colors.white : const Color(0xFF8A99AD),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Spoken Transcript Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NARRATIVE BRIEFING (ELEVENLABS / SPEECH SYNTHESIS):',
                        style: TextStyle(color: Color(0xFF5A6E85), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _callNarrative,
                        style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Audio Trigger Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _playEmergencyCall,
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Play Voice Audio'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _stopCall,
                        icon: const Icon(Icons.call_end_rounded, size: 16),
                        label: const Text('Hang Up'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF1548DC), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_statusMessage, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1-Click Counter Actions on Call Screen
          const Text(
            'DIRECT 1-CLICK INTERVENTIONS',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          _buildActionItem('Send Client Payment Reminder', 'Auto-draft polite payment notice to TechCorp Accounts', () => _executeCounterAction('TechCorp Invoice Reminder')),
          _buildActionItem('Pause Parag Parikh Flexi Cap SIP', 'Avoid ₹500 bounce fee and preserve ₹5,000 checking buffer', () => _executeCounterAction('Mutual Fund SIP Auto-Pause')),
          _buildActionItem('Activate 7-Day Discretionary Freeze', 'Cap everyday dining under ₹450 until retainer settles', () => _executeCounterAction('Discretionary Spend Freeze')),
          const SizedBox(height: 16),

          // Trigger Scenarios for Judges
          const Text(
            'TRIGGER SCENARIOS (FOR JUDGE DEMO)',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _triggerDelaySimulation(5),
                  child: const Text('Simulate 5-Day Delay'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _triggerDelaySimulation(10),
                  child: const Text('Simulate 10-Day Delay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, VoidCallback onApprove) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1548DC),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('EXECUTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

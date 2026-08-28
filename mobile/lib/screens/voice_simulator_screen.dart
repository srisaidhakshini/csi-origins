import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class VoiceSimulatorScreen extends StatefulWidget {
  const VoiceSimulatorScreen({super.key});

  @override
  State<VoiceSimulatorScreen> createState() => _VoiceSimulatorScreenState();
}

class _VoiceSimulatorScreenState extends State<VoiceSimulatorScreen> {
  bool _isPlaying = false;
  bool _isLoading = true;
  String _statusMessage = 'Checking live database insights...';
  String _callNarrative = 'Your checking buffer is healthy and all scheduled obligations are covered.';
  List<Insight> _insights = [];
  double _bufferBalance = 0;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadLiveInsights();
  }

  @override
  void dispose() {
    AudioService.stop();
    super.dispose();
  }

  Future<void> _loadLiveInsights() async {
    setState(() => _isLoading = true);

    try {
      final userSummary = await ApiService.fetchUserSummary();
      final insights = await ApiService.asyncFetchSurfacedInsights();

      if (mounted) {
        setState(() {
          _insights = insights;
          if (userSummary != null) {
            _bufferBalance = userSummary['bufferBalance'] != null ? (double.tryParse(userSummary['bufferBalance'].toString()) ?? 0.0) : 0.0;
          }

          if (_insights.isNotEmpty) {
            _callNarrative = 'Finova Copilot Voice Alert: ${_insights.first.explanation}';
            _statusMessage = 'Active insight detected • Ready to play voice alert';
          } else {
            _callNarrative = 'Finova Copilot Report: Your checking buffer is ${_currencyFormatter.format(_bufferBalance)}. All scheduled obligations are currently covered.';
            _statusMessage = 'Database clean • Buffer healthy';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading voice insights: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playEmergencyCall() {
    AudioService.playRingtone();
    setState(() {
      _isPlaying = true;
      _statusMessage = 'Voice Alert Connected • Speaking live database report...';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      AudioService.speak(_callNarrative);
    });
  }

  void _stopCall() {
    AudioService.stop();
    setState(() {
      _isPlaying = false;
      _statusMessage = 'Voice Alert Stopped';
    });
  }

  void _executeAction(Insight ins, ActionItem action) async {
    setState(() => _statusMessage = 'Executing ${action.title}...');
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
          _statusMessage = 'Success: ${res['message'] ?? 'Action Applied'}';
        });
        AudioService.speak('${action.title} executed successfully.');
        _loadLiveInsights();
      } else {
        setState(() => _statusMessage = 'Execution Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Voice Alert & Briefing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadLiveInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1548DC)))
          : RefreshIndicator(
              onRefresh: _loadLiveInsights,
              child: ListView(
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
                              Text('Autonomous Voice Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Live Database Synthesis', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 10.5)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isPlaying ? const Color(0xFFE8F5E9) : const Color(0xFFF1F3F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isPlaying ? 'SPEAKING' : 'IDLE',
                          style: TextStyle(
                            color: _isPlaying ? const Color(0xFF2E7D32) : const Color(0xFF5A6E85),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Call Transcript / Narrative Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFF1548DC)),
                            SizedBox(width: 6),
                            Text('LIVE SPOKEN BRIEFING', style: TextStyle(color: Color(0xFF1548DC), fontWeight: FontWeight.bold, fontSize: 9.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _callNarrative,
                          style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 14),

                  // Play / Stop Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPlaying ? null : _playEmergencyCall,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Play Voice Briefing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1548DC),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_isPlaying) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _stopCall,
                          icon: const Icon(Icons.stop_rounded, size: 18),
                          label: const Text('Stop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Database Insights & Action Hub
            if (_insights.isNotEmpty) ...[
              const Text(
                'ACTIVE SHORTFALL INSIGHTS FROM POSTGRES',
                style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              for (final ins in _insights)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1548DC).withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ins.explanation,
                        style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12.5, height: 1.35),
                      ),
                      if (ins.actions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (final action in ins.actions)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: action.status == 'executed' ? null : () => _executeAction(ins, action),
                              icon: Icon(action.status == 'executed' ? Icons.check_circle : Icons.flash_on_rounded, size: 14),
                              label: Text(action.status == 'executed' ? 'Executed' : action.title),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}


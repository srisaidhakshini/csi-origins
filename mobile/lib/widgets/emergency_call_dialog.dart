import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class EmergencyCallDialog extends StatefulWidget {
  final Insight insight;
  final VoidCallback onActionExecuted;

  const EmergencyCallDialog({
    super.key,
    required this.insight,
    required this.onActionExecuted,
  });

  @override
  State<EmergencyCallDialog> createState() => _EmergencyCallDialogState();
}

class _EmergencyCallDialogState extends State<EmergencyCallDialog>
    with SingleTickerProviderStateMixin {
  bool _isPlayingAudio = true;
  String _statusMessage = 'COPILOT AGENT SPEAKING...';
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Trigger ring chime and speak voice briefing out loud
    AudioService.playRingtone();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        AudioService.speak(
          'Origin Emergency Copilot Warning. ${widget.insight.explanation}',
        );
      }
    });
  }

  @override
  void dispose() {
    AudioService.stop();
    _waveController.dispose();
    super.dispose();
  }

  void _toggleSpeech() {
    if (_isPlayingAudio) {
      AudioService.stop();
      setState(() {
        _isPlayingAudio = false;
        _statusMessage = 'AUDIO PAUSED';
      });
    } else {
      AudioService.speak(
        'Origin Emergency Copilot Warning. ${widget.insight.explanation}',
      );
      setState(() {
        _isPlayingAudio = true;
        _statusMessage = 'COPILOT AGENT SPEAKING...';
      });
    }
  }

  void _executeAction(ActionItem action) async {
    setState(() => _statusMessage = 'EXECUTING ${action.title.toUpperCase()}...');
    final res = await ApiService.executeAction(
      insightId: widget.insight.id,
      actionId: action.id,
      actionType: action.actionType,
      payload: action.payload,
    );

    if (mounted) {
      if (res != null && res['success'] == true) {
        setState(() {
          action.status = 'executed';
          _statusMessage = 'SUCCESS: ${res['message'] ?? 'ACTION APPLIED'}';
        });
        widget.onActionExecuted();
      } else {
        setState(() => _statusMessage = 'EXECUTION FAILED');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ins = widget.insight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top White Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_in_talk, color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'CRITICAL ALERT // AUDIO CALL',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      AudioService.stop();
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.close, color: Colors.black, size: 18),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Call Status Bar
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        color: _isPlayingAudio ? Colors.white : Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleSpeech,
                        icon: Icon(
                          _isPlayingAudio ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Plain Text Spoken Briefing
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FINOVA COPILOT // NARRATIVE BRIEFING:',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ins.explanation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actions Section
                  if (ins.actions.isNotEmpty) ...[
                    const Text(
                      'RECOMMENDED INTERVENTIONS:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final action in ins.actions.take(2))
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    action.description,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            action.status == 'executed'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: const Color(0xFF333333),
                                    child: const Text(
                                      'APPLIED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _executeAction(action),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                                    ),
                                    child: const Text('APPROVE'),
                                  ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 10),

                  // End Call Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AudioService.stop();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.call_end, color: Colors.white, size: 16),
                      label: const Text('END VOICE CALL'),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
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
}


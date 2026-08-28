import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SimulatorDialog extends StatefulWidget {
  final VoidCallback onEventTriggered;

  const SimulatorDialog({super.key, required this.onEventTriggered});

  @override
  State<SimulatorDialog> createState() => _SimulatorDialogState();
}

class _SimulatorDialogState extends State<SimulatorDialog> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _triggerDelay(int days) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Simulating $days-day payout delay...';
    });

    final res = await ApiService.triggerDelayedIncome(delayDays: days);
    setState(() {
      _isLoading = false;
      _statusMessage = res != null ? '✅ Cascade calculated! Insight generated.' : '❌ Simulation failed.';
    });

    widget.onEventTriggered();
  }

  Future<void> _injectSMS(String sender, String body) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Injecting SMS transaction...';
    });

    final res = await ApiService.ingestSimulatedSMS(sender: sender, body: body);
    setState(() {
      _isLoading = false;
      _statusMessage = res != null ? '✅ SMS Ingested & Evaluated by Gate!' : '❌ SMS Ingestion failed.';
    });

    widget.onEventTriggered();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF161A26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text(
                    'Live Event Simulator',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Inject synthetic signals into the ingestion pipeline to test real-time graph updates and gate scoring.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_statusMessage.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigoAccent.withOpacity(0.5)),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 14),
          ],
          const Text(
            '1. Cascade Risk Simulation',
            style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _triggerDelay(5),
                  icon: const Icon(Icons.alarm_on, size: 16),
                  label: const Text('Delay Retainer by 5 Days', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '2. Ingestion & Anomaly Simulation',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _injectSMS(
                            'VM-HDFCBK',
                            'Dear Customer, Rs 3,400.00 spent on your Card at Swiggy on 28-Aug-26.',
                          ),
                  icon: const Icon(Icons.fastfood_outlined, size: 16),
                  label: const Text('Swiggy ₹3,400 (Spike)', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _injectSMS(
                            'AD-UPWORK',
                            'Payout of Rs 25,000.00 processed by Upwork Global on 28-Aug-26.',
                          ),
                  icon: const Icon(Icons.work_outline, size: 16),
                  label: const Text('Gig ₹25,000 (Income)', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.greenAccent,
                    side: const BorderSide(color: Colors.greenAccent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/insight.dart';
import 'emergency_call_dialog.dart';

class SimulatorDialog extends StatefulWidget {
  final VoidCallback onEventTriggered;

  const SimulatorDialog({super.key, required this.onEventTriggered});

  @override
  State<SimulatorDialog> createState() => _SimulatorDialogState();
}

class _SimulatorDialogState extends State<SimulatorDialog> {
  bool _isLoading = false;
  String _statusMessage = '';

  // Manual entry controllers
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  String _manualType = 'debit';
  String _manualCategory = 'food_dining';

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _triggerDelay(int days) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'SIMULATING $days-DAY PAYOUT DELAY...';
    });

    final res = await ApiService.triggerDelayedIncome(delayDays: days);
    setState(() {
      _isLoading = false;
      _statusMessage = res != null ? 'CASCADE CALCULATED // COUNCIL CONVENED' : 'SIMULATION FAILED';
    });

    widget.onEventTriggered();

    if (res != null && res['insight'] != null && mounted) {
      final ins = Insight.fromJson(res['insight']);
      showDialog(
        context: context,
        builder: (_) => EmergencyCallDialog(
          insight: ins,
          onActionExecuted: () => widget.onEventTriggered(),
        ),
      );
    }
  }

  Future<void> _triggerEmergencyVoiceCall() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'CONNECTING COPILOT VOICE AGENT...';
    });

    final res = await ApiService.triggerEmergencyCall();
    setState(() {
      _isLoading = false;
      _statusMessage = res != null ? 'VOICE CALL CONNECTED' : 'CALL FAILED';
    });

    if (res != null && res['insight'] != null && mounted) {
      final ins = Insight.fromJson(res['insight']);
      showDialog(
        context: context,
        builder: (_) => EmergencyCallDialog(
          insight: ins,
          onActionExecuted: () => widget.onEventTriggered(),
        ),
      );
    }
  }

  Future<void> _injectSMS(String sender, String body) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'INJECTING SMS EVENT...';
    });

    final res = await ApiService.ingestSimulatedSMS(sender: sender, body: body);
    setState(() {
      _isLoading = false;
      _statusMessage = res != null ? 'INGESTED & SCORED BY GATE' : 'INJECTION FAILED';
    });

    widget.onEventTriggered();
  }

  Future<void> _submitManualTransaction() async {
    final amount = double.tryParse(_amountController.text.trim());
    final merchant = _merchantController.text.trim();

    if (amount == null || amount <= 0 || merchant.isEmpty) {
      setState(() => _statusMessage = 'ENTER VALID AMOUNT AND MERCHANT');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'PROCESSING TRANSACTION...';
    });

    final res = await ApiService.ingestManualTransaction(
      amount: amount,
      merchant: merchant,
      type: _manualType,
      category: _manualCategory,
    );

    setState(() {
      _isLoading = false;
      _statusMessage = res != null ? 'CUSTOM EVENT INGESTED' : 'ENTRY FAILED';
      _amountController.clear();
      _merchantController.clear();
    });

    widget.onEventTriggered();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white24, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '// LIVE EVENT SIMULATOR',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Inject live cash flow disruptions or spend anomalies to observe deterministic graph traversal and agent consensus.',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: const Color(0xFF222222),
                child: Text(
                  '>> $_statusMessage',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
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
                color: Colors.indigo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 14),

            // Section 2: Ingestion Presets
            const Text(
              '2. TRANSACTION PRESETS:',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _injectSMS(
                              'VM-HDFCBK',
                              'Rs 3,400.00 spent on your Card at Swiggy on 28-Aug-26.',
                            ),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('SWIGGY ₹3,400 SPIKE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _injectSMS(
                              'AD-UPWORK',
                              'Payout of Rs 25,000.00 processed by Upwork Global on 28-Aug-26.',
                            ),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('GIG ₹25,000 INFLOW'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 3: Custom Manual Entry for Judges
            const Text(
              '3. CUSTOM TRANSACTION INJECTOR (FOR JUDGES):',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _merchantController,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'MERCHANT / PAYER',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white24, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white24, width: 1)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'AMOUNT (₹)',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white24, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white24, width: 1)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _manualType,
                    dropdownColor: const Color(0xFF222222),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white24, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.white24, width: 1)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'debit', child: Text('DEBIT (EXPENSE)')),
                      DropdownMenuItem(value: 'credit', child: Text('CREDIT (INCOME)')),
                    ],
                    onChanged: (val) => setState(() => _manualType = val ?? 'debit'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitManualTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('INJECT EVENT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

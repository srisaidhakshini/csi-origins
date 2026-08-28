import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanLaserController;
  bool _isScanning = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _scanResult;

  // Extracted fields
  final _merchantController = TextEditingController(text: 'BESCOM Karnataka Power');
  final _amountController = TextEditingController(text: '2450');
  final _dueDateController = TextEditingController(text: '08-Sep-2026');
  final _invoiceNoController = TextEditingController(text: 'INV-BLR-88392');
  String _selectedCategory = 'utilities';
  bool _isRecurringObligation = true;

  @override
  void initState() {
    super.initState();
    _scanLaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLaserController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _invoiceNoController.dispose();
    super.dispose();
  }

  void _loadPreset(String name, String amount, String due, String inv, String cat, bool isObligation) {
    setState(() {
      _merchantController.text = name;
      _amountController.text = amount;
      _dueDateController.text = due;
      _invoiceNoController.text = inv;
      _selectedCategory = cat;
      _isRecurringObligation = isObligation;
      _statusMessage = 'Loaded sample: $name';
      _scanResult = null;
    });
  }

  void _performOcrScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Performing Neural OCR & Line Item Extraction...';
    });

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _isScanning = false;
      _statusMessage = 'OCR Extraction Complete • Confidence: 98.4%';
    });
  }

  void _commitBillToCausalGraph() async {
    final amount = double.tryParse(_amountController.text.trim());
    final merchant = _merchantController.text.trim();

    if (amount == null || amount <= 0 || merchant.isEmpty) {
      setState(() => _statusMessage = 'Please enter a valid merchant and amount.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Committing bill to PostgreSQL causal graph...';
    });

    final res = await ApiService.processOcrScan(
      merchant: merchant,
      amount: amount,
      category: _selectedCategory,
      dueDate: _dueDateController.text.trim(),
      invoiceNumber: _invoiceNoController.text.trim(),
      isRecurringObligation: _isRecurringObligation,
    );

    setState(() {
      _isProcessing = false;
      if (res != null && res['success'] == true) {
        _scanResult = res;
        _statusMessage = 'Success: Bill Registered & Causal Graph Updated!';
        AudioService.speak('OCR bill from $merchant for ₹$amount successfully registered into causal graph.');
      } else {
        _statusMessage = 'Commit Failed';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('OCR Bill & Receipt Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Simulated OCR Camera Viewfinder
            _buildOcrViewfinder(),
          const SizedBox(height: 16),

          // Section 2: Sample Bill Presets
          const Text(
            'SAMPLE BILL PRESETS (ONE-TAP LOAD):',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('⚡ BESCOM Power (₹2,450)', () => _loadPreset('BESCOM Karnataka Power', '2450', '08-Sep-2026', 'INV-BES-9021', 'utilities', true)),
              _buildPresetChip('🌐 ACT Broadband (₹1,199)', () => _loadPreset('ACT Fibernet Broadband', '1199', '12-Sep-2026', 'INV-ACT-3321', 'utilities', true)),
              _buildPresetChip('🏢 WeWork HotDesk (₹8,500)', () => _loadPreset('WeWork India Co-working', '8500', '01-Sep-2026', 'INV-WW-5541', 'workspace_rent', true)),
              _buildPresetChip('☕ Third Wave (₹420)', () => _loadPreset('Third Wave Coffee', '420', 'N/A', 'RCPT-TWC-102', 'food_dining', false)),
            ],
          ),
          const SizedBox(height: 16),

          // Status message box
          if (_statusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF1548DC), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_statusMessage, style: const TextStyle(color: Color(0xFF1548DC), fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Section 3: Extracted Entity Review Form
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                const Text(
                  'EXTRACTED BILL ENTITIES (VERIFICATION):',
                  style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFormField('MERCHANT / ISSUER', _merchantController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _buildFormField('TOTAL AMOUNT (₹)', _amountController, isNumber: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildFormField('DUE DATE', _dueDateController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFormField('INVOICE / RECEIPT #', _invoiceNoController),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CATEGORY', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 10.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF4F7FC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'utilities', child: Text('UTILITIES')),
                              DropdownMenuItem(value: 'workspace_rent', child: Text('WORKSPACE RENT')),
                              DropdownMenuItem(value: 'food_dining', child: Text('FOOD / DINING')),
                              DropdownMenuItem(value: 'software_saas', child: Text('SOFTWARE / SAAS')),
                            ],
                            onChanged: (val) => setState(() => _selectedCategory = val ?? 'utilities'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CAUSAL OBLIGATION', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 10.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('RECURRING', style: TextStyle(color: Color(0xFF1C2434), fontSize: 11, fontWeight: FontWeight.bold)),
                                Checkbox(
                                  value: _isRecurringObligation,
                                  activeColor: const Color(0xFF1548DC),
                                  onChanged: (val) => setState(() => _isRecurringObligation = val ?? true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _commitBillToCausalGraph,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('CONFIRM & COMMIT TO CAUSAL GRAPH'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 4: Live Deduplication & Causal State Verification
          if (_scanResult != null) _buildCommitSummaryCard(),
        ],
      ),
    ),
  );
}

  Widget _buildOcrViewfinder() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Illustration Background
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Opacity(
                opacity: 0.35,
                child: SvgPicture.asset(
                  'assets/illustrations/undraw_receipt_oemh.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Center Viewport Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isScanning ? Icons.document_scanner_rounded : Icons.camera_alt_rounded,
                  color: const Color(0xFF1548DC),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  _isScanning ? 'EXTRACTING TEXT & LINE ITEMS...' : 'ALIGN BILL / INVOICE IN CAMERA',
                  style: const TextStyle(color: Color(0xFF1C2434), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isScanning ? null : _performOcrScan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(_isScanning ? 'Scanning...' : 'TRIGGER NEURAL OCR SCAN'),
                ),
              ],
            ),
          ),

          // Animated Scanning Laser Bar
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanLaserController,
              builder: (context, child) {
                return Positioned(
                  top: _scanLaserController.value * 155,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1548DC),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1548DC).withOpacity(0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1548DC).withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF1548DC), fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommitSummaryCard() {
    final ent = _scanResult!['extractedEntities'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00A86B).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withOpacity(0.08),
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
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF00A86B), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'CAUSAL STATE COMMIT VERIFIED',
                    style: TextStyle(color: Color(0xFF1C2434), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF1FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ent['confidence']?.toString().toUpperCase() ?? 'CONFIRMED',
                  style: const TextStyle(color: Color(0xFF1548DC), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Issuer: ${ent['merchant']} (Invoice #${ent['invoiceNumber']})',
            style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            '• Amount: ₹${ent['amount']} (GST: ₹${ent['taxAmount']}) • Due: ${ent['dueDate']}',
            style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11),
          ),
          Text(
            '• Deduplication: ${ent['isMerged'] == true ? 'Merged with corresponding bank SMS' : 'New adjacency obligation node registered'}',
            style: const TextStyle(color: Color(0xFF1548DC), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

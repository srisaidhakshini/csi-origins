import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../main.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _scanLaserController;
  bool _isScanning = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _scanResult;
  double _ocrConfidence = 0.984;

  // Extracted fields
  final _merchantController = TextEditingController(text: 'BESCOM Karnataka Power');
  final _amountController = TextEditingController(text: '3500');
  final _dueDateController = TextEditingController(text: '05-Sep-2026');
  final _invoiceNoController = TextEditingController(text: 'BES-KA-2026-9812');
  String _selectedCategory = 'utilities';
  bool _isRecurringObligation = true;

  // Camera integration
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLaserController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _invoiceNoController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _loadPreset(String name, String amount, String due, String inv, String cat, bool isObligation) {
    setState(() {
      _merchantController.text = name;
      _amountController.text = amount;
      _dueDateController.text = due;
      _invoiceNoController.text = inv;
      _selectedCategory = cat;
      _isRecurringObligation = isObligation;
      _statusMessage = 'Loaded receipt preset: $name (₹$amount)';
      _scanResult = null;
    });
  }

  void _performOcrScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Uploading and scanning image with Neural Vision OCR...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final extracted = await ApiService.extractOcrFromImage(
        imageBase64: base64Image,
        mimeType: image.mimeType ?? 'image/jpeg',
      );

      setState(() {
        _isScanning = false;
        if (extracted != null) {
          _merchantController.text = extracted['merchant'] ?? _merchantController.text;
          _amountController.text = (extracted['amount'] ?? _amountController.text).toString();
          _dueDateController.text = extracted['dueDate'] ?? _dueDateController.text;
          _invoiceNoController.text = extracted['invoiceNumber'] ?? _invoiceNoController.text;
          _selectedCategory = extracted['category'] ?? _selectedCategory;
          _isRecurringObligation = extracted['isRecurring'] ?? _isRecurringObligation;
          _ocrConfidence = extracted['confidence'] != null ? (double.tryParse(extracted['confidence'].toString()) ?? 0.986) : 0.986;
          _statusMessage = 'OCR Extraction Successful • (${(_ocrConfidence * 100).toStringAsFixed(1)}% Confidence)';
        } else {
          _statusMessage = 'OCR Extraction Failed. Could not parse image.';
        }
        AudioService.speak('Bill scanned. Detected ${_merchantController.text} for ₹${_amountController.text}.');
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Camera error: $e';
      });
    }
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
      userId: AppSession.userId ?? ApiService.demoUserId,
    );

    setState(() {
      _isProcessing = false;
      if (res != null && res['success'] == true) {
        _scanResult = res;
        final isMerged = res['dedupResult']?['isMerged'] == true;
        _statusMessage = isMerged
            ? 'Success: Bill Matched with Bank Alert (Merged without double-counting)!'
            : 'Success: Bill Registered & Causal Graph Updated!';
        AudioService.speak(
          isMerged
              ? 'OCR bill matched with existing transaction. Merged into graph without double counting.'
              : 'OCR bill from $merchant for ₹$amount successfully registered as causal obligation.',
        );
      } else {
        _statusMessage = 'Commit Failed. Please try again.';
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
            // Section 1: Simulated OCR Camera Viewfinder with Laser
            _buildOcrViewfinder(),
            const SizedBox(height: 16),

            // Section 2: Sample Bill Presets
            const Text(
              'ONE-TAP SAMPLE BILL PRESETS:',
              style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('⚡ BESCOM Power (₹3,500)', () => _loadPreset('BESCOM Karnataka Power', '3500', '05-Sep-2026', 'INV-BES-9021', 'utilities', true)),
                _buildPresetChip('🏠 Skyline Rent (₹28,000)', () => _loadPreset('Skyline Properties Rent', '28000', '05-Sep-2026', 'RENT-2026-09', 'housing', true)),
                _buildPresetChip('🌐 ACT Fibernet (₹1,199)', () => _loadPreset('ACT Fibernet Broadband', '1199', '12-Sep-2026', 'INV-ACT-3321', 'utilities', true)),
                _buildPresetChip('🍲 Swiggy Dining (₹920)', () => _loadPreset('Swiggy Gourmet Feast', '920', 'N/A', 'RCPT-SWG-441', 'dining', false)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EXTRACTED BILL ENTITIES:',
                        style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF1FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(_ocrConfidence * 100).toStringAsFixed(1)}% CONFIDENCE',
                          style: const TextStyle(color: Color(0xFF1548DC), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
                        child: _buildFormField('AMOUNT (₹)', _amountController, isNumber: true),
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
                        child: _buildFormField('INVOICE / BILL #', _invoiceNoController),
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
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F7FC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'utilities', child: Text('Utilities', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'housing', child: Text('Housing / Rent', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'dining', child: Text('Dining', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'workspace_rent', child: Text('Co-working', style: TextStyle(fontSize: 12))),
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
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black87,
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
        fit: StackFit.expand,
        children: [
          // Live Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Laser Scanning Overlay Animation
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanLaserController,
              builder: (context, child) {
                return Positioned(
                  top: 20 + (_scanLaserController.value * 210),
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1548DC),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1548DC).withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Center Viewport Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isCameraInitialized)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('INITIALIZING CAMERA...', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                if (_isCameraInitialized)
                  Opacity(
                    opacity: _isScanning ? 1.0 : 0.8,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _performOcrScan,
                      icon: const Icon(Icons.camera_rounded, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isScanning ? Colors.grey : const Color(0xFF1548DC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      label: Text(_isScanning ? 'EXTRACTING...' : 'CAPTURE & SCAN'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1548DC))),
      backgroundColor: const Color(0xFFEBF1FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 10.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12.5, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F7FC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildCommitSummaryCard() {
    final dedup = _scanResult!['dedupResult'] ?? {};
    final isMerged = dedup['isMerged'] == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMerged ? const Color(0xFF1548DC) : Colors.green.shade400,
          width: 1.5,
        ),
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
          Row(
            children: [
              Icon(
                isMerged ? Icons.link_rounded : Icons.check_circle_rounded,
                color: isMerged ? const Color(0xFF1548DC) : Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isMerged ? 'CROSS-SOURCE DEDUPLICATION MERGE' : 'CAUSAL STATE COMMITTED',
                style: TextStyle(
                  color: isMerged ? const Color(0xFF1548DC) : Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isMerged
                ? 'Matched identical bank debit notification from SMS/Gmail. Confidence upgraded to CONFIRMED without double-counting liquid buffer.'
                : 'Registered as upcoming obligation node in PostgreSQL. Buffer cushion & cascade runway recomputed.',
            style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

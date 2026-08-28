import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'ocr_scanner_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = false;
  String _syncStatus = '';

  void _syncGmail() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing Gmail messages & matching SMS fingerprints...';
    });

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _isSyncing = false;
      _syncStatus = 'Gmail Synced • 4 financial receipts processed & deduplicated';
      AudioService.speak('Gmail synced. 4 financial receipts processed and merged with bank alerts.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Data Ingestion & Sync'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gmail Integration Card
          _buildGmailSyncCard(),
          const SizedBox(height: 16),

          // OCR Bill Scanner Direct Access Card
          _buildOcrAccessCard(context),
          const SizedBox(height: 20),

          // Parsed Financial Emails Stream
          const Text(
            'PARSED FINANCIAL EMAILS (GMAIL STREAM)',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          _buildEmailItem(
            'BSE Star MF',
            'SIP Installment Confirmation (₹5,000.00)',
            'Parag Parikh Flexi Cap Fund • Ingested & Fingerprint Merged',
            'CONFIRMED',
            true,
          ),
          _buildEmailItem(
            'TechCorp Accounts',
            'Invoice #TC-889 Payment Schedule Notice (₹35,000.00)',
            'Payout delayed 5 days past due cycle • Cascade Triggered',
            'DELAYED',
            false,
          ),
          _buildEmailItem(
            'Upwork Escrow',
            'Fixed-Price Milestone Release (₹25,000.00)',
            'Deposited into HDFC Primary • Inflow Confirmed',
            'CONFIRMED',
            true,
          ),
          _buildEmailItem(
            'ACT Fibernet Billing',
            'E-Receipt for Account #883921 (₹1,199.00)',
            'Monthly Broadband Bill Paid',
            'CONFIRMED',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildGmailSyncCard() {
    return Container(
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
              const Row(
                children: [
                  Icon(Icons.mail_rounded, color: Color(0xFF1548DC), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Google / Gmail OAuth Sync',
                    style: TextStyle(color: Color(0xFF1C2434), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CONNECTED',
                  style: TextStyle(color: Color(0xFF1548DC), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Connected: gowreesh@gmail.com\nContinuously extracts electronic payment receipts and client invoices to corroborate bank SMS notifications without double-counting.',
            style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (_syncStatus.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_syncStatus, style: const TextStyle(color: Color(0xFF1548DC), fontSize: 10.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _syncGmail,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: Text(_isSyncing ? 'Syncing...' : 'Sync Gmail Ingestion Stream'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrAccessCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1548DC).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1548DC).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF1548DC), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OCR Bill & Receipt Scanner',
                  style: TextStyle(color: Color(0xFF1C2434), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Scan paper utility bills, rent receipts, and dining invoices into Postgres.',
                  style: TextStyle(color: Color(0xFF5A6E85), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1548DC),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SCAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailItem(String sender, String subject, String details, String tag, bool isConfirmed) {
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
                Row(
                  children: [
                    Text(sender, style: const TextStyle(color: Color(0xFF1C2434), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(subject, style: const TextStyle(color: Color(0xFF5A6E85), fontSize: 11), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(details, style: const TextStyle(color: Color(0xFF8A99AD), fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isConfirmed ? const Color(0xFFEBF1FF) : const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(color: isConfirmed ? const Color(0xFF1548DC) : const Color(0xFF8A99AD), fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

/// Service that binds to the native Android Telephony SMS broadcast stream
/// and queries historical inbox SMS to relay into the ingestion pipeline.
class SmsListenerService {
  static const EventChannel _smsEventChannel =
      EventChannel('com.csiorigin.financialagent/sms_stream');
  static const MethodChannel _smsReaderChannel =
      MethodChannel('com.csiorigin.financialagent/sms_reader');

  static StreamSubscription? _subscription;
  static bool _isListening = false;

  static bool get isListening => _isListening;

  /// Starts listening to real-time SMS events from the native Android telephony stack
  static void startListening({Function(Map<String, dynamic> result)? onEventIngested}) {
    if (_isListening) return;

    try {
      _subscription = _smsEventChannel.receiveBroadcastStream().listen(
        (dynamic event) async {
          if (event is Map) {
            final sender = event['sender']?.toString() ?? 'Unknown';
            final body = event['body']?.toString() ?? '';

            debugPrint('📱 [SmsListenerService] Live SMS Intercepted: $sender -> $body');

            // Send to CSI Origins Ingestion & Causal Pipeline
            final result = await ApiService.ingestSimulatedSMS(
              sender: sender,
              body: body,
            );

            if (result != null && result['success'] == true) {
              debugPrint('✅ [SmsListenerService] SMS successfully ingested into causal graph');
              if (onEventIngested != null) {
                onEventIngested(result);
              }
            } else {
              debugPrint('ℹ️ [SmsListenerService] Non-transactional / filtered SMS or parse skipped');
            }
          }
        },
        onError: (dynamic error) {
          debugPrint('❌ [SmsListenerService] Stream error: $error');
        },
      );

      _isListening = true;
      debugPrint('🚀 [SmsListenerService] Native SMS Broadcast Receiver active');
    } catch (e) {
      debugPrint('⚠️ [SmsListenerService] Could not initialize SMS channel (non-Android or permission missing): $e');
    }
  }

  /// Stops listening to SMS stream
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    debugPrint('🛑 [SmsListenerService] SMS stream cancelled');
  }

  /// Scans historical SMS inbox messages from the Android content provider and ingests financial transactions
  static Future<Map<String, int>> syncHistoricalInboxSms({int limit = 250}) async {
    int scanned = 0;
    int ingested = 0;

    try {
      final List<dynamic>? rawMessages = await _smsReaderChannel
          .invokeMethod('readInboxSms', {'limit': limit});

      if (rawMessages != null && rawMessages.isNotEmpty) {
        scanned = rawMessages.length;
        debugPrint('📥 [SmsListenerService] Fetched $scanned past SMS messages from inbox');

        for (final raw in rawMessages) {
          if (raw is Map) {
            final sender = raw['sender']?.toString() ?? '';
            final body = raw['body']?.toString() ?? '';

            if (body.isNotEmpty) {
              final res = await ApiService.ingestSimulatedSMS(
                sender: sender,
                body: body,
              );
              if (res != null && res['success'] == true) {
                ingested++;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SmsListenerService] Error reading historical inbox SMS: $e');
    }

    return {'scanned': scanned, 'ingested': ingested};
  }
}

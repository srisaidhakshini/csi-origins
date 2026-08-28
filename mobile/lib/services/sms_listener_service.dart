import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

/// Service that binds to the native Android Telephony SMS broadcast stream
/// and queries historical inbox SMS to relay into the ingestion pipeline.
/// On web or non-Android platforms, all methods are no-ops.
class SmsListenerService {
  static const EventChannel _smsEventChannel =
      EventChannel('com.csiorigin.financialagent/sms_stream');
  static const MethodChannel _smsReaderChannel =
      MethodChannel('com.csiorigin.financialagent/sms_reader');

  static StreamSubscription? _subscription;
  static bool _isListening = false;

  static bool get isListening => _isListening;

  /// Starts listening to real-time SMS events from the native Android telephony stack.
  /// No-op on web or non-Android platforms.
  static void startListening({Function(Map<String, dynamic> result)? onEventIngested}) {
    // SMS is only available on native Android — skip silently on web
    if (kIsWeb) {
      debugPrint('🌐 [SmsListenerService] Web platform detected — SMS channel skipped.');
      return;
    }
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
          _isListening = false;
        },
      );

      _isListening = true;
      debugPrint('🚀 [SmsListenerService] Native SMS Broadcast Receiver active');
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [SmsListenerService] Plugin not available on this platform: $e');
      _isListening = false;
    } catch (e) {
      debugPrint('⚠️ [SmsListenerService] Could not initialize SMS channel: $e');
      _isListening = false;
    }
  }

  /// Stops listening to SMS stream
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    debugPrint('🛑 [SmsListenerService] SMS stream cancelled');
  }

  /// Scans historical SMS inbox messages from the Android content provider and ingests financial transactions.
  /// Returns empty result on web.
  static Future<Map<String, int>> syncHistoricalInboxSms({int limit = 250}) async {
    if (kIsWeb) {
      debugPrint('🌐 [SmsListenerService] Web platform — historical inbox scan skipped.');
      return {'scanned': 0, 'ingested': 0};
    }

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
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [SmsListenerService] Plugin not available on this platform: $e');
    } catch (e) {
      debugPrint('⚠️ [SmsListenerService] Error reading historical inbox SMS: $e');
    }

    return {'scanned': scanned, 'ingested': ingested};
  }
}


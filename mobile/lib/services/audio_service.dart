import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class AudioService {
  /// Play an incoming phone call chime sound
  static void playRingtone() {
    if (kIsWeb) {
      try {
        js.context.callMethod('playRingtoneChime');
      } catch (e) {
        debugPrint('Ringtone playback error: $e');
      }
    }
  }

  /// Speak copilot voice text out loud through browser audio
  static void speak(String text) {
    if (kIsWeb) {
      try {
        js.context.callMethod('speakCopilotAlert', [text]);
      } catch (e) {
        debugPrint('Web speech error: $e');
      }
    }
  }

  /// Stop speech playback
  static void stop() {
    if (kIsWeb) {
      try {
        js.context.callMethod('stopCopilotAlert');
      } catch (e) {
        debugPrint('Web speech stop error: $e');
      }
    }
  }
}

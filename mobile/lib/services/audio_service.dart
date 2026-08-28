import 'package:flutter/foundation.dart';
import 'audio_service_stub.dart'
    if (dart.library.js) 'audio_service_web.dart'
    if (dart.library.html) 'audio_service_web.dart';

class AudioService {
  /// Play an incoming phone call chime sound
  static void playRingtone() {
    if (kIsWeb) {
      playWebRingtone();
    }
  }

  /// Speak copilot voice text out loud through browser audio
  static void speak(String text) {
    if (kIsWeb) {
      speakWebCopilotAlert(text);
    }
  }

  /// Stop speech playback
  static void stop() {
    if (kIsWeb) {
      stopWebCopilotAlert();
    }
  }
}

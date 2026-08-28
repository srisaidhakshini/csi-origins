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

  /// Speak copilot voice text out loud through browser audio or ElevenLabs
  static void speak(String text, {String? elevenLabsAudioBase64}) {
    if (kIsWeb) {
      if (elevenLabsAudioBase64 != null && elevenLabsAudioBase64.isNotEmpty) {
        playWebBase64Audio(elevenLabsAudioBase64);
      } else {
        speakWebCopilotAlert(text);
      }
    }
  }

  /// Stop speech playback
  static void stop() {
    if (kIsWeb) {
      stopWebBase64Audio();
      stopWebCopilotAlert();
      stopWebSpeechRecognition();
    }
  }

  /// Start speech recognition / voice-to-text input
  static void listenToSpeech(Function(String text) onResult) {
    if (kIsWeb) {
      startWebSpeechRecognition(onResult);
    }
  }

  /// Stop listening to speech
  static void stopListening() {
    if (kIsWeb) {
      stopWebSpeechRecognition();
    }
  }

  /// Open external URL (e.g. Google OAuth consent screen)
  static void openUrl(String url, {bool usePopup = false}) {
    if (kIsWeb) {
      openWebUrl(url, usePopup: usePopup);
    }
  }
}


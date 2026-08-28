// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playWebRingtone() {
  try {
    js.context.callMethod('playRingtoneChime');
  } catch (e) {
    // ignore
  }
}

void speakWebCopilotAlert(String text) {
  try {
    js.context.callMethod('speakCopilotAlert', [text]);
  } catch (e) {
    // ignore
  }
}

void stopWebCopilotAlert() {
  try {
    js.context.callMethod('stopCopilotAlert');
  } catch (e) {
    // ignore
  }
}

void openWebUrl(String url, {bool usePopup = false}) {
  try {
    js.context.callMethod('openGoogleOAuth', [url, usePopup]);
  } catch (e) {
    // ignore
  }
}

void playWebBase64Audio(String base64Audio) {
  try {
    js.context.callMethod('playBase64Audio', [base64Audio]);
  } catch (e) {
    // ignore
  }
}

void stopWebBase64Audio() {
  try {
    js.context.callMethod('stopBase64Audio');
  } catch (e) {
    // ignore
  }
}

void startWebSpeechRecognition(Function(String text) onResult) {
  try {
    js.context['__onSpeechResult'] = (dynamic text) {
      if (text != null) {
        onResult(text.toString());
      }
    };
    js.context.callMethod('startSpeechRecognition', ['__onSpeechResult']);
  } catch (e) {
    // ignore
  }
}

void stopWebSpeechRecognition() {
  try {
    js.context.callMethod('stopSpeechRecognition');
  } catch (e) {
    // ignore
  }
}


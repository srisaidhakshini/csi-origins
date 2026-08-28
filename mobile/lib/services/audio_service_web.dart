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

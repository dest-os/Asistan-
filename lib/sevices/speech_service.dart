import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _isAvailable = await _speech.initialize(
        onError: (val) => print('STT Error: $val'),
        onStatus: (val) => print('STT Status: $val'),
      );
    }
    return _isAvailable;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({required Function(String text) onResult}) async {
    if (!_isAvailable) {
      bool available = await initSpeech();
      if (!available) return;
    }

    await _speech.listen(
      localeId: "tr_TR",
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}

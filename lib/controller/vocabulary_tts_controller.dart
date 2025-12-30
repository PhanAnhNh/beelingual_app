import 'package:flutter_tts/flutter_tts.dart';
class VocabularyTTSController {
  final FlutterTts _flutterTts = FlutterTts();
  bool isPlaying = false;

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    if (isPlaying) {
      await _flutterTts.stop();
      isPlaying = false;
      return;
    }

    isPlaying = true;
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.speak(text);

    _flutterTts.setCompletionHandler(() {
      isPlaying = false;
    });
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    isPlaying = false;
  }

  void dispose() {
    _flutterTts.stop();
  }
}

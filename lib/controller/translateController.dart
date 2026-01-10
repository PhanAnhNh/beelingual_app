import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TranslateController extends ChangeNotifier {
  final TextEditingController inputController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  TranslateController() {
    inputController.addListener(() {
      _debounceTranslate();
    });
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.awaitSpeakCompletion(true);

    if (Platform.isIOS) {
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
      );
    }
  }

  String result = "";
  String fromLang = "English";
  String toLang = "Vietnamese";

  Timer? _debounceTimer;
  String _lastRequestedText = "";

  List<String> languages = [
    'English',
    'Vietnamese',
    'Chinese (Simplified)',
    'Chinese (Traditional)',
    'Japanese',
    'Korean',
    'French',
    'German',
    'Spanish',
    'Italian',
    'Portuguese',
    'Russian',
    'Thai',
    'Indonesian',
    'Hindi',
    'Arabic',
    'Turkish',
    'Dutch',
    'Polish',
    'Ukrainian'
  ];


  final FlutterTts flutterTtsInput = FlutterTts();
  final FlutterTts flutterTtsOutput = FlutterTts();

  void _debounceTranslate() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      translate();
    });
  }

  String code(String lang) {
    switch (lang) {
      case 'English': return 'en';
      case 'Vietnamese': return 'vi';
      case 'Chinese (Simplified)': return 'zh-CN';
      case 'Chinese (Traditional)': return 'zh-TW';
      case 'Japanese': return 'ja';
      case 'Korean': return 'ko';
      case 'French': return 'fr';
      case 'German': return 'de';
      case 'Spanish': return 'es';
      case 'Portuguese': return 'pt';
      case 'Russian': return 'ru';
      case 'Italian': return 'it';
      case 'Thai': return 'th';
      case 'Indonesian': return 'id';
      case 'Hindi': return 'hi';
      case 'Arabic': return 'ar';
      case 'Turkish': return 'tr';
      case 'Dutch': return 'nl';
      case 'Polish': return 'pl';
      case 'Ukrainian': return 'uk';
    }
    return 'en';
  }


  void swapLanguages() {
    final oldFrom = fromLang;
    fromLang = toLang;
    toLang = oldFrom;
    if (result.isNotEmpty) {
      inputController.text = result;
    }
    result = "";
    notifyListeners();
    translate();
  }

  Future<void> translate() async {
    final text = inputController.text.trim();

    if (text.isEmpty) {
      result = "";
      notifyListeners();
      return;
    }

    _lastRequestedText = text;

    final url =
        "https://translate.googleapis.com/translate_a/single"
        "?client=gtx&sl=${code(fromLang)}&tl=${code(toLang)}"
        "&dt=t&q=${Uri.encodeComponent(text)}";

    try {
      final res = await http.get(Uri.parse(url));

      if (_lastRequestedText != text) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        result = data[0][0][0] ?? "";
      } else {
        result = "Error: ${res.statusCode}";
      }
    } catch (e) {
      result = "Network error!";
    }

    notifyListeners();
  }

  Future<void> _speak(String text, String langCode) async {
    if (text.isEmpty) return;
    await flutterTts.stop();

    await flutterTts.setLanguage(langCode);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    var isAvailable = await flutterTts.isLanguageAvailable(langCode);
    if (isAvailable) {
      await flutterTts.speak(text);
    } else {
      print("TTS Engine chưa hỗ trợ ngôn ngữ: $langCode");
    }
  }

  Future<void> speakInput() async {
    String text = inputController.text.trim();
    if (text.isEmpty) return;

    await flutterTtsInput.setLanguage(code(fromLang));
    await flutterTtsInput.setPitch(1.0);
    await flutterTtsInput.setSpeechRate(0.5);
    await flutterTtsInput.speak(text);
  }

  Future<void> speakResult() async {
    await _speak(result, code(toLang));
  }
  Future<void> stopSpeech() async {
    await flutterTts.stop();
  }

  Future<void> pauseInp() => stopSpeech();
  Future<void> pauseOut() => stopSpeech();
}

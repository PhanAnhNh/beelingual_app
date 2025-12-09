import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TranslateController extends ChangeNotifier {
  final TextEditingController inputController = TextEditingController();

  TranslateController() {
    inputController.addListener(() {
      _debounceTranslate();
    });
  }

  String result = "";
  String fromLang = "English";
  String toLang = "Vietnamese";

  Timer? _debounceTimer;
  String _lastRequestedText = "";

  final List<String> languages = [
    'English',
    'Vietnamese',
    'Japanese',
    'Korean',
    'Chinese',
    'French',
  ];

  // --- Thêm FlutterTts ---
  final FlutterTts flutterTts = FlutterTts();

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
      case 'Japanese': return 'ja';
      case 'Korean': return 'ko';
      case 'Chinese': return 'zh-CN';
      case 'French': return 'fr';
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

  Future<void> speakResult() async {
    if (result.isEmpty) return;

    String locale = "en-US";
    switch (toLang) {
      case "Vietnamese":
        locale = "vi-VN";
        break;
      case "Japanese":
        locale = "ja-JP";
        break;
      case "Korean":
        locale = "ko-KR";
        break;
      case "Chinese":
        locale = "zh-CN";
        break;
      case "French":
        locale = "fr-FR";
        break;
    }

    await flutterTts.setLanguage(locale);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(result);
  }

  Future<void> pause() async {
    try {
      await flutterTts.pause();
    } catch (e) {
      await flutterTts.stop();
    }
  }

}

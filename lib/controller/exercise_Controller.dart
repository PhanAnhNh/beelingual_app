import 'dart:convert';
import 'package:beelingual/app_UI/Exe_UI/SummaryExeList.dart';
import 'package:beelingual/model/model_exercise.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../component/messDialog.dart';
import '../connect_api/url.dart';

class ExerciseController {
  List<Exercises> exercises = [];
  Map<String, String> userAnswers = {};
  int currentIndex = 0;

  Future<void> fetchExercisesByTopicId(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    final url = Uri.parse(
      '$urlAPI/api/exercises?topicId=$topicId&limit=10&random=true',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không lấy được dữ liệu (${response.statusCode})');
    }

    final decoded = json.decode(response.body);
    final List<dynamic> dataList = decoded['data'];

    exercises = dataList
        .map((item) => Exercises.fromJson(item))
        .toList();

    currentIndex = 0;
    userAnswers.clear();
  }


  Future<void> fetchExercisesByLevelAndSkill({
    required String level,
    required String skill,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    final url = Uri.parse('$urlAPI/api/exercises?level=$level&skill=$skill&topicId=null&limit=10&random=true');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Không lấy được dữ liệu (${response.statusCode})');
    }

    final decoded = json.decode(response.body);
    final List<dynamic> dataList = decoded['data'];

    exercises = dataList
        .map((item) => Exercises.fromJson(item))
        .toList();

    currentIndex = 0;
    userAnswers.clear();
  }


  Future<void> answerQuestion({
    required BuildContext context,
    required String userAnswer,
  }) async {
    final ex = exercises[currentIndex];
    if (userAnswers.containsKey(ex.id)) return;
    await stopSpeaking();
    userAnswers[ex.id] = userAnswer;
    final bool isCorrect = userAnswer.trim().toLowerCase() ==
        ex.correctAnswer.trim().toLowerCase();

    if (isCorrect) {
      await showSuccessDialog(context, "Thông báo","Bạn đã trả lời đúng!");
    } else {
      await showErrorDialog(context, "Thông báo","Sai rồi!");
    }

    goToNextQuestion(context);
  }

  void goToNextQuestion(BuildContext context) {
    if (currentIndex < exercises.length - 1) {
      currentIndex++;
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          exercises: exercises,
          userAnswers: userAnswers,
        ),
      ),
    );
  }

  bool isAnswered() {
    final ex = exercises[currentIndex];
    return userAnswers.containsKey(ex.id);
  }

  final FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;
  VoidCallback? onAudioStateChange;

  double _getSpeechRateByLevel(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
      case 'A2':
        return 0.2;

      case 'B1':
      case 'B2':
        return 0.3;

      case 'C1':
      case 'C2':
        return 0.5;

      default:
        return 0.4;
    }
  }

  Future<void> speakLisExercises({
    required String audioUrl,
    required String level,
  }) async {
    if (audioUrl.isEmpty) return;

    if (isPlaying) {
      await flutterTts.stop();
      isPlaying = false;
      onAudioStateChange?.call();
      return;
    }

    isPlaying = true;
    onAudioStateChange?.call();

    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(
      _getSpeechRateByLevel(level),
    );

    await flutterTts.speak(audioUrl);

    flutterTts.setCompletionHandler(() {
      isPlaying = false;
      onAudioStateChange?.call();
    });
  }


  Future<void> speakExercises(String audioUrl) async {
    if (audioUrl.isEmpty) return;

    if (isPlaying) {
      await flutterTts.stop();
      isPlaying = false;
      onAudioStateChange?.call();
      return;
    }

    isPlaying = true;
    onAudioStateChange?.call();

    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.2);

    await flutterTts.speak(audioUrl);

    flutterTts.setCompletionHandler(() {
      isPlaying = false;
      onAudioStateChange?.call();
    });
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();
    isPlaying = false;
  }
}

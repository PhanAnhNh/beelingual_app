import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../exercises/summaryExercises.dart';
import '../model/exercises.dart';
import '../component/messDialog.dart';

final String urlAPI = 'https://english-app-mupk.onrender.com';

class ExerciseController {
  List<Exercises> exercises = [];
  Map<String, String> userAnswers = {};
  int currentIndex = 0;

  Future<void> fetchExercisesByTopicRef(String topicRef) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    int page = 1;
    int totalPages = 1;
    List<Exercises> allExercises = [];

    do {
      final url = Uri.parse('$urlAPI/api/exercises?page=$page&limit=10');
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
      totalPages = decoded['totalPages'] ?? 1;

      final List<dynamic> dataList = decoded['data'];
      allExercises.addAll(
        dataList.map((item) => Exercises.fromJson(item)).toList(),
      );

      page++;
    } while (page <= totalPages);

    exercises = allExercises.where((e) => e.topicRef == topicRef).toList();

    // Hoán đổi vị trí các câu hỏi
    exercises.shuffle();
  }

  Future<void> answerQuestion({
    required BuildContext context,
    required String userAnswer,
  }) async {
    final ex = exercises[currentIndex];
    if (userAnswers.containsKey(ex.id)) return;
    userAnswers[ex.id] = userAnswer;
    final bool isCorrect = userAnswer.trim().toLowerCase() ==
        ex.correctAnswer.trim().toLowerCase();

    if (isCorrect) {
      await showSuccessDialog(context, "Bạn đã trả lời đúng!");
    } else {
      await showErrorDialog(context, "Sai rồi!");
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
  Future<void> speakExercises(String audioUrl ) async {
    if (audioUrl.isEmpty) return;

    String locale = "en-US";

    await flutterTts.setLanguage(locale);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.3);
    await flutterTts.speak(audioUrl);
  }
}

import 'dart:convert';
import 'package:beelingual_app/app_UI/grammar_UI/summaryExercisesGrm.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/exercisesGrm.dart';
import '../component/messDialog.dart';


final String urlAPI = 'https://english-app-mupk.onrender.com';

class ExerciseGrmController {
  List<ExercisesGrm> exercisesGrm = [];
  Map<String, String> userAnswers = {};
  int currentIndex = 0;

  Future<void> fetchExercisesByTopicRef(String grammarId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    int page = 1;
    int totalPages = 1;
    List<ExercisesGrm> allExercises = [];

    do {
      final url = Uri.parse('$urlAPI/api/grammar-exercises?page=$page&limit=10');
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
        dataList.map((item) => ExercisesGrm.fromJson(item)).toList(),
      );

      page++;
    } while (page <= totalPages);

    currentIndex = 0;
    userAnswers.clear();
    final filtered = allExercises.where((e) {
      return e.grammarId == grammarId;
    }).toList();
    filtered.shuffle();

    exercisesGrm = filtered.length > 10
        ? filtered.take(10).toList()
        : filtered;
  }

  Future<void> answerQuestion({
    required BuildContext context,
    required String userAnswer,
  }) async {
    final ex = exercisesGrm[currentIndex];

    if (userAnswers.containsKey(ex.id)) return;

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
    if (currentIndex < exercisesGrm.length - 1) {
      currentIndex++;
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultGrmPage(
          exercisesGrm: exercisesGrm,
          userAnswers: userAnswers,
        ),
      ),
    );
  }

  bool isAnswered() {
    final ex = exercisesGrm[currentIndex];
    return userAnswers.containsKey(ex.id);
  }

  void setExercises(List<ExercisesGrm> exercises) {
    exercisesGrm = exercises;
    userAnswers = {};
    currentIndex = 0;
  }
}

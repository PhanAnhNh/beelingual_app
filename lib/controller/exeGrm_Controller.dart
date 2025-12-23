import 'dart:convert';
import 'package:beelingual/app_UI/grammar_UI/summaryExercisesGrm.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../connect_api/url.dart';
import '../model/exercisesGrm.dart';
import '../component/messDialog.dart';

class ExerciseGrmController {
  List<ExercisesGrm> exercisesGrm = [];
  Map<String, String> userAnswers = {};
  int currentIndex = 0;

  Future<void> fetchExercisesByGrammarId(String grammarId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Token không tồn tại. Vui lòng đăng nhập.');
    }

    final url = Uri.parse(
      '$urlAPI/api/grammar-exercises'
          '?grammarId=$grammarId'
          '&limit=10'
          '&random=true',
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
    final List<dynamic> dataList = decoded['data'] ?? [];

    currentIndex = 0;
    userAnswers.clear();

    exercisesGrm = dataList
        .map((item) => ExercisesGrm.fromJson(item))
        .toList();
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

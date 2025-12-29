import 'package:beelingual/model/model_exercise.dart';
import 'package:flutter/material.dart';


class ResultPage extends StatelessWidget {
  final List<Exercises> exercises;
  final Map<String, String> userAnswers;

  const ResultPage({super.key, required this.exercises, required this.userAnswers});

  @override
  Widget build(BuildContext context) {
    int correct = exercises.where((e) {
      String? u = userAnswers[e.id];
      return u != null &&
          u.trim().toLowerCase() == e.correctAnswer.trim().toLowerCase();
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        backgroundColor: const Color(0xFFFFF176),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Bạn trả lời đúng $correct/${exercises.length} câu",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...exercises.map((e) {
            String? ua = userAnswers[e.id];
            bool ok = ua != null &&
                ua.trim().toLowerCase() ==
                    e.correctAnswer.trim().toLowerCase();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(e.questionText),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• Đáp án của bạn: ${ua ?? "(Không trả lời)"}"),
                    Text("• Đáp án đúng: ${e.correctAnswer}"),
                    Text("• Giải thích: ${e.explanation}"),
                  ],
                ),
                trailing: Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  color: ok ? Colors.green : Colors.red,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

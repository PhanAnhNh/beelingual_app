import 'package:beelingual/model/exercisesGrm.dart';
import 'package:flutter/material.dart';

class ResultGrmPage extends StatelessWidget {
  final List<ExercisesGrm> exercisesGrm;
  final Map<String, String> userAnswers;

  const ResultGrmPage({super.key, required this.exercisesGrm, required this.userAnswers});

  @override
  Widget build(BuildContext context) {
    int correct = exercisesGrm.where((e) {
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
            "Bạn trả lời đúng $correct/${exercisesGrm.length} câu",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 4),

          ...exercisesGrm.map((e) {
            String? ua = userAnswers[e.id];
            bool ok = ua != null &&
                ua.trim().toLowerCase() ==
                    e.correctAnswer.trim().toLowerCase();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(e.question),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• Bạn chọn: ${ua ?? "(Không trả lời)"}"),
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

class ExercisesGrm {
  final String id;
  final String grammarId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  ExercisesGrm({
    required this.id,
    required this.grammarId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory ExercisesGrm.fromJson(Map<String, dynamic> json) {
    final optionList = json['options'] as List<dynamic>? ?? [];

    return ExercisesGrm(
      id: json['_id'] ?? '',
      grammarId: json['grammarId'] is Map
          ? json['grammarId']['_id'] ?? ''
          : json['grammarId'] ?? '',
      question: json['question'] ?? '',
      options: optionList.map((e) => e.toString()).toList(),
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}

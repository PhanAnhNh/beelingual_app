class Option {
  final String id;
  final String text;
  final bool isCorrect;

  Option({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['_id'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class Exercises {
  final String id;
  final String skill;
  final String type;
  final String questionText;
  final List<Option> options;
  final String correctAnswer;
  final String explanation;
  final String level;
  final String topicId;
  final String audioUrl;

  Exercises({
    required this.id,
    required this.skill,
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.level,
    required this.topicId,
    required this.audioUrl,
  });

  factory Exercises.fromJson(Map<String, dynamic> json) {
    final optionList = json['options'] as List<dynamic>? ?? [];
    final options = optionList.map((e) => Option.fromJson(e)).toList();

    String parsedTopicId = '';
    if (json['topicId'] is String) {
      parsedTopicId = json['topicId'];
    } else if (json['topicId'] is Map) {
      parsedTopicId = json['topicId']['_id'] ?? '';
    }

    return Exercises(
      id: json['_id'] ?? '',
      skill: json['skill'] ?? '',
      type: json['type'] ?? '',
      questionText: json['questionText'] ?? '',
      options: options,
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
      level: json['level'] ?? '',
      topicId: parsedTopicId,
      audioUrl: json['audioUrl'] ?? '',
    );
  }
}

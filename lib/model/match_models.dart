class Question {
  final String id;
  final String content;
  final Map<String, dynamic> options; // { "A": "...", "B": "..." }
  final String correctAnswer;

  Question({
    required this.id,
    required this.content,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      options: Map<String, dynamic>.from(json['options']),
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }
}

class PlayerInfo {
  final String userId;
  final String username;
  final String avatarUrl;
  int score;

  PlayerInfo({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    this.score = 0
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}
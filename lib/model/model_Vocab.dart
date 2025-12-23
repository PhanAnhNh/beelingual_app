class Vocabulary {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String type;
  final String topic;
  final String example;
  final String level;
  final String audioUrl;
  final String imageUrl;

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.type,
    required this.topic,
    required this.level,
    required this.example,
    required this.audioUrl,
    required this.imageUrl,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      id: json['_id'] ?? '',
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      type: json['type'] ?? '',
      topic: json['topic']?.toString() ?? json['topicId']?.toString() ?? '',
      level: json['level'] ?? '',
      example: json['example'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
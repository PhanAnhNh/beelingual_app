class Topic {
  final String id;
  final String title;
  final String imageUrl;
  final int points;
  final String status;


  final int order;
  final int progress;      // % tiến độ (0-100)
  final int totalWords;    // Tổng số từ
  final int learnedWords;  // Số từ đã thuộc

  Topic({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.points = 0,
    this.status = 'To do',
    required this.order,
    this.progress = 0,
    this.totalWords = 0,
    this.learnedWords = 0,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['_id'] ?? '',
      title: json['name'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? '',
      points: 0, // Backend chưa có points thì để 0

      // Logic Status: Nếu 100% thì là Completed, ngược lại là Learning
      status: (json['progress'] != null && json['progress'] == 100)
          ? 'Completed'
          : 'Learning',
      order: json['order'],
      progress: json['progress'] ?? 0,
      totalWords: json['totalWords'] ?? 0,
      learnedWords: json['learnedWords'] ?? 0,
    );
  }
}
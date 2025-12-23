class Topic {
  final String id;
  final String name;
  final String description;
  final String level;
  final String imageUrl;
  final int order;
  final DateTime createdAt;

  Topic({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.imageUrl,
    required this.order,
    required this.createdAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      order: json['order'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String icon;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class Grammar {
  final String id;
  final String title;
  final String level;
  final String structure;
  final String content;
  final String example;
  final String categoryId;
  final DateTime? createdAt;

  Grammar({
    required this.id,
    required this.title,
    required this.level,
    required this.structure,
    required this.content,
    required this.example,
    required this.categoryId,
    this.createdAt,
  });

  factory Grammar.fromJson(Map<String, dynamic> json) {
    return Grammar(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? '',
      structure: json['structure'] ?? '',
      content: json['content'] ?? '',
      example: json['example'] ?? '',
      categoryId: json['categoryId'] is Map
          ? json['categoryId']['_id'] ?? ''
          : json['categoryId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

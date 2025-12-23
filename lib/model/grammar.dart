class Category {
  final String id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
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
  final String category;

  Grammar({
    required this.id,
    required this.title,
    required this.level,
    required this.structure,
    required this.content,
    required this.example,
    required this.category,
  });

  factory Grammar.fromJson(Map<String, dynamic> json) {
    return Grammar(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? '',
      structure: json['structure'] ?? '',
      content: json['content'] ?? '',
      example: json['example'] ?? '',
      category: json['categoryId'],
    );
  }
}

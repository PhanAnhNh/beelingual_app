class User {
  final String id;
  final String username;
  final String fullname;
  final String role;
  final String email;
  final String level;
  final int xp;
  final int gems;
  final String createdAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.fullname,
    required this.role,
    required this.email,
    required this.level,
    required this.xp,
    required this.gems,
    required this.createdAt,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      fullname: json['fullname'],
      role: json['role'],
      email: json['email'],
      level: json['level'],
      xp: json['xp'],
      gems: json['gems'],
      createdAt: json['createdAt'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

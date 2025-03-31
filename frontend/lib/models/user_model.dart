class User {
  final String id;
  final String email;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] ?? json['_id'],
      email: json['email'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

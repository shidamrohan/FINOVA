class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastSignIn;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    this.lastSignIn,
  });

  // From Supabase JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSignIn: json['last_sign_in'] != null
          ? DateTime.parse(json['last_sign_in'] as String)
          : null,
    );
  }

  // To Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in': lastSignIn?.toIso8601String(),
    };
  }

  // Get initials for avatar
  String get initials {
    if (name == null || name!.isEmpty) {
      return email[0].toUpperCase();
    }
    final parts = name!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
}

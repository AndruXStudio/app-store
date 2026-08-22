class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? json['user_metadata']?['username'] ?? 'User',
      email: json['email'],
      avatarUrl: json['avatar_url'] ?? json['user_metadata']?['avatar_url'],
    );
  }
}

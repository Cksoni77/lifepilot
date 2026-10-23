class User {
  User({required this.id, required this.name, required this.email, this.avatarPath});

  final String id;
  String name;
  String email;
  String? avatarPath;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'avatarPath': avatarPath};

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarPath: json['avatarPath'] as String?,
      );
}

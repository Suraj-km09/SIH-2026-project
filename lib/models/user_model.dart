/// Authenticated User model matching backend MongoDB user schema.
class UserModel {
  final String id;
  final String username;
  final String? email;
  final String role;
  final String? department;
  final String? status;
  final String? lastLogin;
  final String? createdAt;
  final String? token;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.department,
    this.status,
    this.lastLogin,
    this.createdAt,
    this.token,
  });

  bool get isAdmin => role == 'admin';
  bool get isReviewer => role == 'reviewer' || role == 'admin';

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? department,
    String? status,
    String? lastLogin,
    String? createdAt,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'user',
      department: json['department'] as String?,
      status: json['status'] as String? ?? 'active',
      lastLogin: json['lastLogin'] as String?,
      createdAt: json['createdAt'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'email': email,
        'role': role,
        'department': department,
        'status': status,
        'lastLogin': lastLogin,
        'createdAt': createdAt,
        if (token != null) 'token': token,
      };
}

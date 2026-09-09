import 'user_model.dart';

/// Authentication payload returned by login and register endpoints.
class AuthResultModel {
  final UserModel user;
  final String token;

  const AuthResultModel({
    required this.user,
    required this.token,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    return AuthResultModel(
      user: UserModel.fromJson(userMap),
      token: json['token'] as String? ??
          (json['user'] is Map ? json['user']['token'] as String? ?? '' : ''),
    );
  }

  Map<String, dynamic> toJson() => {
        ...user.toJson(),
        'token': token,
      };
}

/// Token Refresh response payload.
class RefreshTokenResultModel {
  final String token;
  final UserModel? user;

  const RefreshTokenResultModel({
    required this.token,
    this.user,
  });

  factory RefreshTokenResultModel.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResultModel(
      token: json['token'] as String? ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

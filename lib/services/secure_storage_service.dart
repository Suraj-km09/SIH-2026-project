import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cross-platform secure token & preference storage.
/// Uses Android Keystore (AES-GCM), iOS Keychain,
/// and Windows Credential Manager / DPAPI.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage;

  SecureStorageService._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            resetOnError: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // Storage Keys
  static const String _keyJwtToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyUserRole = 'user_role';
  static const String _keyCustomBaseUrl = 'custom_base_url';
  static const String _keyUseMockData = 'use_mock_data';

  // JWT Token Management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyJwtToken);
  }

  // User Identity
  Future<void> saveUserSession({
    required String id,
    required String username,
    required String role,
  }) async {
    await _storage.write(key: _keyUserId, value: id);
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<Map<String, String?>> getUserSession() async {
    final id = await _storage.read(key: _keyUserId);
    final username = await _storage.read(key: _keyUsername);
    final role = await _storage.read(key: _keyUserRole);
    return {'id': id, 'username': username, 'role': role};
  }

  Future<void> clearUserSession() async {
    await _storage.delete(key: _keyJwtToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyUserRole);
  }

  // Config Overrides
  Future<void> saveBaseUrlOverride(String url) async {
    await _storage.write(key: _keyCustomBaseUrl, value: url);
  }

  Future<String?> getBaseUrlOverride() async {
    return await _storage.read(key: _keyCustomBaseUrl);
  }

  Future<void> saveMockDataToggle(bool enabled) async {
    await _storage.write(key: _keyUseMockData, value: enabled.toString());
  }

  Future<bool> getMockDataToggle() async {
    final val = await _storage.read(key: _keyUseMockData);
    return val == 'true';
  }
}

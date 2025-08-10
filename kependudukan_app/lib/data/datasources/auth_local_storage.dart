import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_kependudukan/data/models/penduduk_model.dart';

class AuthLocalStorage {
  final FlutterSecureStorage _secureStorage;
  static const String _userKey = 'user_credentials';
  static const String _tokenUpdatedKey = 'token_updated_timestamp';

  AuthLocalStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveUserCredentials({
    required String nik,
    required String password,
    String? noHp,
    String? name,
    String? accessToken,
    String? tokenType,
  }) async {
    final userData = {
      'nik': nik,
      'password': password,
      'no_hp': noHp ?? '',
      'name': name ?? '',
      'access_token': accessToken,
      'token_type': tokenType ?? 'Bearer',
    };

    await _secureStorage.write(key: _userKey, value: json.encode(userData));

    // Store a timestamp when the token was updated
    await _secureStorage.write(
        key: _tokenUpdatedKey,
        value: DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<Map<String, dynamic>?> getUserCredentials() async {
    final userDataString = await _secureStorage.read(key: _userKey);
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearUserCredentials() async {
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _tokenUpdatedKey);
  }

  Future<bool> hasUserCredentials() async {
    final userDataString = await _secureStorage.read(key: _userKey);
    return userDataString != null;
  }

  Future<PendudukModel?> getStoredPenduduk() async {
    final userData = await getUserCredentials();
    if (userData != null) {
      return PendudukModel(
        nik: userData['nik'],
        noHp: userData['no_hp'] ?? '',
        name: userData['name'] ?? '',
        accessToken: userData['access_token'],
        tokenType: userData['token_type'],
      );
    }
    return null;
  }

  Future<String?> getStoredToken() async {
    final userCreds = await getUserCredentials();
    if (userCreds != null && userCreds['access_token'] != null) {
      return userCreds['access_token'];
    }
    return null;
  }

  Future<DateTime?> getTokenUpdatedTimestamp() async {
    final timestampStr = await _secureStorage.read(key: _tokenUpdatedKey);
    if (timestampStr != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
    }
    return null;
  }
}

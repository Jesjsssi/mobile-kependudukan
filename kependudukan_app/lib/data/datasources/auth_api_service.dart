import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_kependudukan/core/constants/app_constants.dart';
import 'package:flutter_kependudukan/core/errors/exception.dart';
import 'package:flutter_kependudukan/data/models/penduduk_model.dart';

class AuthApiService {
  final http.Client client;

  AuthApiService({required this.client});

 Future<PendudukModel> login(String nik, String password) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.authApiUrl}${AppConstants.endpointLogin}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Key': AppConstants.apiKey,
        },
        body: json.encode({
          'nik': nik,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return PendudukModel.fromAuthResponse(jsonResponse);
        } else {
          throw AuthException(
              message: jsonResponse['message'] ?? AppConstants.errorAuthFailed);
        }
      } else if (response.statusCode == 401 || response.statusCode == 422) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        throw AuthException(
            message: jsonResponse['message'] ?? AppConstants.errorAuthFailed);
      } else {
        throw ServerException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  Future<PendudukModel> register(
      String nik, String password, String noHp) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.authApiUrl}${AppConstants.endpointRegister}'),
        headers: {
          'X-API-Key': AppConstants.apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nik': nik,
          'no_hp': noHp,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return PendudukModel.fromAuthResponse(jsonResponse);
        } else {
          throw AuthException(
              message: jsonResponse['message'] ?? 'Registration failed');
        }
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final String errorMessage = jsonResponse['message'] ??
            (jsonResponse['errors'] != null
                ? _formatValidationErrors(jsonResponse['errors'])
                : 'Validation error');
        throw ValidationException(message: errorMessage);
      } else {
        throw ServerException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException ||
          e is ServerException ||
          e is ValidationException) {
        rethrow;
      }
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  String _formatValidationErrors(Map<String, dynamic> errors) {
    final List<String> errorMessages = [];

    errors.forEach((key, value) {
      if (value is List) {
        errorMessages.add(value.first.toString());
      } else {
        errorMessages.add(value.toString());
      }
    });

    return errorMessages.join(', ');
  }

  Future<PendudukModel> getUserFromResponse(
      Map<String, dynamic> responseData) async {
    try {
      // Extract user data from the response
      final userData = responseData['data'] ?? responseData;

      // Create and return a PendudukModel instance
      return PendudukModel(
        nik: userData['nik'] ?? '',
        noHp: userData['no_hp'] ?? '',
        name: userData['full_name'] ?? userData['name'] ?? '',
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to parse user data: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> verifyCredentials(
      String nik, String password) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.apiUrl}${AppConstants.endpointLogin}'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
        body: json.encode({
          'nik': nik,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw AuthException(message: 'Invalid credentials');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(
          message: 'Error verifying credentials: ${e.toString()}');
    }
  }

  Future<bool> registerUser(String nik, String password, String noHp) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.apiUrl}${AppConstants.endpointRegister}'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
        body: json.encode({
          'nik': nik,
          'password': password,
          'no_hp': noHp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          message: errorData['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
          message: 'Error during registration: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> loginPenduduk(
      String nik, String password) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.apiUrl}${AppConstants.endpointLogin}'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
        body: json.encode({'nik': nik, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw AuthException(message: AppConstants.errorAuthFailed);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Login error: ${e.toString()}');
    }
  }

  Future<bool> registerPenduduk(
    String nik,
    String password,
    String noHp,
  ) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.apiUrl}${AppConstants.endpointRegister}'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
        body: json.encode({
          'nik': nik,
          'password': password,
          'no_hp': noHp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw ServerException(
            message: 'Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Registration error: ${e.toString()}');
    }
  }
}

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/berita_desa_model.dart';
import '../../core/constants/app_constants.dart';
import 'auth_local_storage.dart';
import '../../core/error/exceptions.dart';

class BeritaDesaApiService {
  final http.Client client;
  final AuthLocalStorage authLocalStorage;

  BeritaDesaApiService({
    required this.client,
    required this.authLocalStorage,
  });

  Future<String> _getAuthToken() async {
    final token = await authLocalStorage.getStoredToken();
    if (token == null || token.isEmpty) {
      throw AuthException(message: 'Anda belum login atau sesi telah berakhir');
    }

    if (token.contains('|')) {
      final parts = token.split('|');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }

    return token.trim();
  }

  Future<List<BeritaDesaModel>> getBeritaDesa() async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('${AppConstants.authApiUrl}/user/berita-desa'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-Key': AppConstants.apiKey,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] is List) {
          final List<dynamic> beritaData = jsonResponse['data'];
          return beritaData
              .map((data) => BeritaDesaModel.fromJson(data))
              .toList();
        } else {
          throw ServerException(
              message: jsonResponse['message'] ??
                  'Gagal mendapatkan data berita desa');
        }
      } else if (response.statusCode == 401) {
        throw AuthException(message: 'Tidak diizinkan: Token tidak valid');
      } else if (response.statusCode == 404) {
        throw ServerException(message: 'Data berita desa tidak ditemukan');
      } else if (response.statusCode >= 500) {
        throw ServerException(
            message: 'Server sedang bermasalah. Silakan coba lagi nanti');
      } else {
        throw ServerException(
            message:
                'Gagal mendapatkan data berita desa: ${response.statusCode}');
      }
    } on TimeoutException {
      rethrow;
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Gagal mendapatkan data berita desa: ${e.toString()}');
    }
  }
}

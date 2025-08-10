import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/riwayat_surat_model.dart';
import '../../core/constants/app_constants.dart';
import 'auth_local_storage.dart';
import '../../core/error/exceptions.dart';

class RiwayatSuratApiService {
  final http.Client client;
  final AuthLocalStorage authLocalStorage;

  RiwayatSuratApiService({
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
        return parts[1];
      }
    }

    return token;
  }

  Future<List<RiwayatSuratModel>> getRiwayatSurat() async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('${AppConstants.authApiUrl}/user/riwayat-surat'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-Key': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] is Map) {
          final Map<String, dynamic> riwayatData = jsonResponse['data'];
          return riwayatData.values
              .map((data) => RiwayatSuratModel.fromJson(data))
              .toList();
        } else {
          throw ServerException(
              message: jsonResponse['message'] ??
                  'Gagal mendapatkan data riwayat surat');
        }
      } else if (response.statusCode == 401) {
        throw AuthException(message: 'Tidak diizinkan: Token tidak valid');
      } else {
        throw ServerException(
            message:
                'Gagal mendapatkan data riwayat surat: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
      throw ServerException(
          message: 'Gagal mendapatkan data riwayat surat: ${e.toString()}');
    }
  }
}

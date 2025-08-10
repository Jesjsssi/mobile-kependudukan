import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_kependudukan/core/constants/app_constants.dart';
import 'package:flutter_kependudukan/core/errors/exception.dart';
import 'package:flutter_kependudukan/data/datasources/auth_local_storage.dart';
import 'package:flutter_kependudukan/data/models/laporan_model.dart';

class RuangLingkupData {
  final int id;
  final String ruangLingkup;
  final String bidang;
  final String keterangan;

  RuangLingkupData({
    required this.id,
    required this.ruangLingkup,
    required this.bidang,
    required this.keterangan,
  });

  factory RuangLingkupData.fromJson(Map<String, dynamic> json) {
    // Robust ID conversion
    int id;
    final rawId = json['id'];

    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0;
    } else if (rawId is double) {
      id = rawId.toInt();
    } else {
      id = 0;
    }

    return RuangLingkupData(
      id: id,
      ruangLingkup: json['ruang_lingkup'] ?? '',
      bidang: json['bidang'] ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }
}

class VillageReportApiService {
  final http.Client client;
  final AuthLocalStorage authLocalStorage;

  VillageReportApiService({
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

  Future<List<RuangLingkupData>> getLaporDesaOptions() async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.authApiUrl}/lapor-desa'),
        headers: {
          'Accept': 'application/json',
          'X-API-Key': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] is List) {
          final List<dynamic> optionsData = jsonResponse['data'];
          return optionsData
              .map((data) => RuangLingkupData.fromJson(data))
              .toList();
        } else {
          throw ServerException(
              message: jsonResponse['message'] ??
                  'Gagal mendapatkan data ruang lingkup');
        }
      } else if (response.statusCode == 401) {
        throw AuthException(message: 'Tidak diizinkan: Api key tidak valid');
      } else {
        throw ServerException(
            message:
                'Gagal mendapatkan data ruang lingkup: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
      throw ServerException(
          message: 'Gagal mendapatkan data ruang lingkup: ${e.toString()}');
    }
  }

  Future<List<VillageReportModel>> getVillageReports() async {
    try {
      final token = await _getAuthToken();

      final response = await client.get(
        Uri.parse('${AppConstants.authApiUrl}/user/laporan-desa'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] is List) {
          final List<dynamic> reportsData = jsonResponse['data'];
          return reportsData
              .map((report) => VillageReportModel.fromJson(report))
              .toList();
        } else {
          throw ServerException(
              message:
                  jsonResponse['message'] ?? 'Gagal mendapatkan data laporan');
        }
      } else if (response.statusCode == 401) {
        throw AuthException(message: 'Tidak diizinkan: Token tidak valid');
      } else {
        throw ServerException(
            message: 'Gagal mendapatkan data laporan: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
      throw ServerException(
          message: 'Gagal mendapatkan data laporan: ${e.toString()}');
    }
  }

  Future<VillageReportModel> createVillageReport({
    required String judulLaporan,
    required String deskripsiLaporan,
    required String tagLokasi,
    required File gambar,
    required int ruangLingkupId,
  }) async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('${AppConstants.authApiUrl}/user/laporan-desa');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['judul_laporan'] = judulLaporan;
      request.fields['deskripsi_laporan'] = deskripsiLaporan;
      request.fields['tag_lokasi'] = tagLokasi;

      // Fix for the int conversion issue
      if (ruangLingkupId <= 0) {
        throw ServerException(message: 'ID ruang lingkup tidak valid');
      }

      // Make sure we send a string representation of the integer
      request.fields['lapor_desa_id'] = ruangLingkupId.toString();

     

      // Add image file
      final imageFile =
          await http.MultipartFile.fromPath('gambar', gambar.path);
      request.files.add(imageFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          print(
              "Response data: ${jsonResponse['data']}"); // Debug print for response data
          return VillageReportModel.fromJson(jsonResponse['data']);
        } else {
          throw ServerException(
              message: jsonResponse['message'] ?? 'Gagal membuat laporan');
        }
      } else {
        final errorResponse = json.decode(response.body);
        
        throw ServerException(
            message:
                'Gagal membuat laporan: ${response.statusCode} - ${errorResponse['message'] ?? "Unknown error"}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
     
      if (e
          .toString()
          .contains("type 'String' is not a subtype of type 'int'")) {
        throw ServerException(
            message:
                'Gagal membuat laporan: Format ID tidak sesuai. Pastikan ID berupa angka.');
      }
      throw ServerException(message: 'Gagal membuat laporan: ${e.toString()}');
    }
  }
}

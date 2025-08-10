import 'dart:convert';
import 'dart:io';
import 'package:flutter_kependudukan/data/datasources/auth_local_storage.dart';
import 'package:flutter_kependudukan/data/models/document_model.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_kependudukan/core/constants/app_constants.dart';
import 'package:flutter_kependudukan/core/errors/exception.dart';
import 'package:flutter_kependudukan/domain/entities/penduduk.dart';
import 'package:flutter_kependudukan/data/models/penduduk_model.dart';
import 'package:flutter_kependudukan/core/services/wilayah_service.dart';
import 'package:flutter_kependudukan/data/models/family_member_model.dart';

class PendudukApiService {
  final http.Client client;
  final WilayahService _wilayahService = WilayahService();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  final Duration _cacheDuration = const Duration(minutes: 15);

  PendudukApiService({required this.client});

  Future<Penduduk> verifyLogin(String nik, String password) async {
    throw ServerException(
      message: 'Login now uses local database instead of API',
    );
  }

  Future<bool> registerPenduduk(
    String nik,
    String password,
    String noHp,
  ) async {
    throw ServerException(
      message: 'Registration now uses local database instead of API',
    );
  }

  Future<bool> checkNikExists(String nik) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.apiUrl}/all-citizens'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = json.decode(response.body);

          if (responseData is List) {
            return responseData.any(
              (citizen) =>
                  citizen is Map<String, dynamic> &&
                  citizen['nik'] != null &&
                  citizen['nik'].toString() == nik,
            );
          } else if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('data') &&
                responseData['data'] is List) {
              List<dynamic> citizens = responseData['data'];
              return citizens.any(
                (citizen) =>
                    citizen is Map<String, dynamic> &&
                    citizen['nik'] != null &&
                    citizen['nik'].toString() == nik,
              );
            }

            if (responseData.containsKey('exists')) {
              return responseData['exists'] == true;
            }
          }

          throw ServerException(
            message: 'Unable to determine if NIK exists from response',
          );
        } catch (e) {
          if (e is ServerException) {
            rethrow;
          }
          throw ServerException(
            message: 'Error parsing NIK check response: ${e.toString()}',
          );
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          throw ServerException(
            message: errorData['message'] ??
                'Check NIK failed: ${response.statusCode}',
          );
        } catch (e) {
          throw ServerException(
            message:
                'Failed to check NIK: ${response.statusCode} - ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}',
          );
        }
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Error checking NIK: ${e.toString()}');
    }
  }

  Future<PendudukModel?> getPendudukByNik(String nik) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.apiUrl}/all-citizens'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> citizens = [];
        if (responseData is List) {
          citizens = responseData;
        } else if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data') &&
            responseData['data'] is List) {
          citizens = responseData['data'];
        }

        for (var citizen in citizens) {
          if (citizen['nik'].toString() == nik) {
            return PendudukModel(
              nik: nik,
              noHp: citizen['no_hp'] ?? '',
              name: citizen['full_name'] ?? '',
            );
          }
        }

        return null;
      } else {
        throw ServerException(
          message: 'Failed to fetch data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error fetching penduduk data: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getPendudukDetailByNik(String nik) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.apiUrl}/all-citizens'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> citizens = [];
        if (responseData is List) {
          citizens = responseData;
        } else if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data') &&
            responseData['data'] is List) {
          citizens = responseData['data'];
        }

        for (var citizen in citizens) {
          if (citizen['nik'].toString() == nik) {
            final provinceId = citizen['province_id'] ?? 0;
            final districtId = citizen['district_id'] ?? 0;
            final subDistrictId = citizen['sub_district_id'] ?? 0;
            final villageId = citizen['village_id'] ?? 0;

            final locationNames = await _getLocationNames(
              provinceId,
              districtId,
              subDistrictId,
              villageId,
            );

            return {
              'nik': citizen['nik']?.toString() ?? '',
              'kk': citizen['kk']?.toString() ?? '',
              'full_name': citizen['full_name'] ?? '',
              'gender': citizen['gender'] ?? '',
              'birth_date': citizen['birth_date'] ?? '',
              'age': citizen['age'] ?? 0,
              'birth_place': citizen['birth_place'] ?? '',
              'address': citizen['address'] ?? '',
              'province_id': provinceId,
              'district_id': districtId,
              'sub_district_id': subDistrictId,
              'village_id': villageId,
              'rt': citizen['rt'] ?? '',
              'rw': citizen['rw'] ?? '',
              'province_name': locationNames['province_name'],
              'district_name': locationNames['district_name'],
              'sub_district_name': locationNames['sub_district_name'],
              'village_name': locationNames['village_name'],
            };
          }
        }

        throw ServerException(
          message: 'Data penduduk dengan NIK $nik tidak ditemukan',
        );
      } else {
        throw ServerException(
          message: 'Failed to fetch data: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Error fetching penduduk data: ${e.toString()}',
      );
    }
  }

  Future<Map<String, String>> _getLocationNames(
    int provinceId,
    int districtId,
    int subDistrictId,
    int villageId,
  ) async {
    try {
      final provinceIdStr = provinceId.toString();
      final districtIdStr = districtId.toString();
      final subDistrictIdStr = subDistrictId.toString();
      final villageIdStr = villageId.toString();

      String provinceName = 'Provinsi';
      String districtName = 'Kabupaten/Kota';
      String subDistrictName = 'Kecamatan';
      String villageName = 'Desa/Kelurahan';

      try {
        final province = await _wilayahService.getProvince(provinceIdStr);
        if (province != null) {
          provinceName = province['name'] ?? provinceName;
        }

        final district = await _wilayahService.getDistrict(districtIdStr);
        if (district != null) {
          districtName = district['name'] ?? districtName;
        }

        final subDistrict = await _wilayahService.getSubDistrict(
          subDistrictIdStr,
          districtIdStr,
        );
        if (subDistrict != null) {
          subDistrictName = subDistrict['name'] ?? subDistrictName;
        }

        final village = await _wilayahService.getVillage(
          villageIdStr,
          subDistrictIdStr,
          districtIdStr,
        );
        if (village != null) {
          villageName = village['name'] ?? villageName;
        }
      } catch (e) {
        print('Error fetching location names: $e');
      }

      return {
        'province_name': provinceName,
        'district_name': districtName,
        'sub_district_name': subDistrictName,
        'village_name': villageName,
      };
    } catch (e) {
      return {
        'province_name': 'Provinsi',
        'district_name': 'Kabupaten/Kota',
        'sub_district_name': 'Kecamatan',
        'village_name': 'Desa/Kelurahan',
      };
    }
  }

  Future<List<FamilyMemberModel>> getFamilyMembers(String kk) async {
    final cacheKey = 'family_$kk';

    if (_cache.containsKey(cacheKey) && _cacheTimestamp.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamp[cacheKey]!;
      final now = DateTime.now();
      if (now.difference(timestamp) < _cacheDuration) {
        return _cache[cacheKey] as List<FamilyMemberModel>;
      }
    }

    try {
      if (kk.isEmpty) {
        throw ValidationException(message: 'KK number cannot be empty');
      }

      final response = await client.get(
        Uri.parse('${AppConstants.apiUrl}/citizens-family/$kk'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> familyData = [];
        if (responseData is List) {
          familyData = responseData;
        } else if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data') &&
            responseData['data'] is List) {
          familyData = responseData['data'];
        }

        final members = familyData
            .map((member) => FamilyMemberModel.fromJson(member))
            .toList();

        _cache[cacheKey] = members;
        _cacheTimestamp[cacheKey] = DateTime.now();

        return members;
      } else {
        throw ServerException(
          message: 'Failed to fetch family data: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException || e is ValidationException) {
        rethrow;
      }

      throw ServerException(
        message: 'Error fetching family data: ${e.toString()}',
      );
    }
  }

  Future<bool> updateFamilyMemberCoordinate(
    String nik,
    String coordinate,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _updateCoordinateInCache(nik, coordinate);

      return true;
    } catch (e) {
      throw ServerException(
        message: 'Error updating coordinates: ${e.toString()}',
      );
    }
  }

  Future<FamilyMemberDocuments> getFamilyMemberDocuments(String nik,
      {bool forceRefresh = false}) async {
    final cacheKey = 'documents_$nik';

    // Check cache first unless forced refresh
    if (!forceRefresh &&
        _cache.containsKey(cacheKey) &&
        _cacheTimestamp.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamp[cacheKey]!;
      final now = DateTime.now();
      if (now.difference(timestamp) < _cacheDuration) {
        return _cache[cacheKey] as FamilyMemberDocuments;
      }
    }

    try {
      // Get auth token from storage
      final authLocalStorage = GetIt.instance<AuthLocalStorage>();
      final rawToken = await authLocalStorage.getStoredToken();

      if (rawToken == null || rawToken.isEmpty) {
        throw AuthException(
            message: 'Anda belum login atau sesi telah berakhir');
      }

      // Extract the token part after the pipe character
      String token = rawToken;
      if (rawToken.contains('|')) {
        final parts = rawToken.split('|');
        if (parts.length > 1) {
          token = parts[1];
        }
      }

      final response = await client.get(
        Uri.parse(
            '${AppConstants.authApiUrl}/user/family-member/$nik/documents'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final documents =
              FamilyMemberDocuments.fromJson(jsonResponse['documents']);

          // Cache the result
          _cache[cacheKey] = documents;
          _cacheTimestamp[cacheKey] = DateTime.now();

          return documents;
        }

        throw ServerException(
            message: jsonResponse['message'] ?? 'Failed to fetch documents');
      } else if (response.statusCode == 401) {
        throw AuthException(message: 'Unauthorized: Invalid token');
      } else {
        throw ServerException(
            message: 'Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Document fetch error: ${e.toString()}');
    }
  }

  Future<DocumentModel> uploadFamilyMemberDocument(
      String nik, String documentType, File file) async {
    try {
      // Get auth token from storage
      final authLocalStorage = GetIt.instance<AuthLocalStorage>();
      final rawToken = await authLocalStorage.getStoredToken();

      if (rawToken == null || rawToken.isEmpty) {
        throw AuthException(
            message: 'Anda belum login atau sesi telah berakhir');
      }

      // Extract the token part after the pipe character
      String token = rawToken;
      if (rawToken.contains('|')) {
        final parts = rawToken.split('|');
        if (parts.length > 1) {
          token = parts[1];
        }
      }

      // Get file extension
      final String fileExtension = _getFileExtension(file.path);

      // Prepare the multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${AppConstants.authApiUrl}/user/family-member/$nik/upload-document'),
      );

      // Add the authorization header with Bearer prefix - matching the GET request format
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      // Add the document type
      request.fields['document_type'] = documentType;

      // Add the file
      var fileStream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: '$documentType.$fileExtension',
      );
      request.files.add(multipartFile);

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true &&
            jsonResponse['document'] != null) {
          final cacheKey = 'documents_$nik';
          _cache.remove(cacheKey);
          _cacheTimestamp.remove(cacheKey);

          return DocumentModel.fromJson(jsonResponse['document']);
        }

        throw ServerException(
            message: jsonResponse['message'] ?? 'Failed to upload document');
      } else if (response.statusCode == 401) {
        throw AuthException(message: 'Unauthorized: Invalid token');
      } else {
        throw ServerException(
            message: 'Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException || e is ServerException) {
        rethrow;
      }
      throw ServerException(
          message: 'Failed to upload document: ${e.toString()}');
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.contains('.') ? fileName.split('.').last : '';
  }

  Future<bool> deleteFamilyMemberDocument(
      String nik, String documentType) async {
    try {
      // Get auth token from storage
      final authLocalStorage = GetIt.instance<AuthLocalStorage>();
      final rawToken = await authLocalStorage.getStoredToken();

      if (rawToken == null || rawToken.isEmpty) {
        throw ServerException(message: 'Unauthorized: No token available');
      }

      // Extract the token part after the pipe character
      String token = rawToken;
      if (rawToken.contains('|')) {
        final parts = rawToken.split('|');
        if (parts.length > 1) {
          token = parts[1];
        }
      }

      final response = await client.delete(
        Uri.parse(
            '${AppConstants.authApiUrl}/user/family-member/$nik/delete-document/$documentType'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-Key': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from cache
        final cacheKey = 'documents_$nik';
        if (_cache.containsKey(cacheKey)) {
          _cache.remove(cacheKey);
          _cacheTimestamp.remove(cacheKey);
        }
        return true;
      } else if (response.statusCode == 401) {
        throw ServerException(message: 'Unauthorized: Invalid token');
      } else {
        throw ServerException(
            message: 'Failed to delete document: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
          message: 'Failed to delete document: ${e.toString()}');
    }
  }

  void _updateCoordinateInCache(String nik, String coordinate) {
    _cache.forEach((key, value) {
      if (key.startsWith('family_') && value is List<FamilyMemberModel>) {
        for (int i = 0; i < value.length; i++) {
          if (value[i].nik == nik) {
            (value)[i] = value[i].copyWith(coordinate: coordinate);
          }
        }
      }
    });
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamp.clear();
  }
}

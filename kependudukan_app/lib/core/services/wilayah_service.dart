import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_kependudukan/core/constants/app_constants.dart';

class WilayahService {
  static final WilayahService _instance = WilayahService._internal();
  factory WilayahService() => _instance;
  WilayahService._internal();

  final Map<String, dynamic> _cache = {};

  Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-Key': AppConstants.apiKey,
  };

  Future<List<dynamic>> _request(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
    } catch (e) {
      print('Error fetching: $url -> $e');
    }
    return [];
  }

  dynamic _getCache(String type, String id) => _cache['${type}_$id'];
  void _setCache(String type, String id, dynamic data) =>
      _cache['${type}_$id'] = data;

  Future<Map<String, dynamic>?> getProvince(String id) async {
    if (_getCache('province', id) != null) return _getCache('province', id);
    final provinces = await _request('${AppConstants.apiUrl}/provinces');

   
    Map<String, dynamic>? province;
    try {
      province = provinces.firstWhere((p) => '${p['id']}' == id);
      _setCache('province', id, province);
    } catch (e) {
    
      province = null;
    }

    return province;
  }

  Future<Map<String, dynamic>?> getDistrict(String id) async {
    if (_getCache('district', id) != null) return _getCache('district', id);
    final provinces = await _request('${AppConstants.apiUrl}/provinces');
    for (final province in provinces) {
      final districts = await _request(
        '${AppConstants.apiUrl}/districts/${province['code']}',
      );

    
      try {
        final district = districts.firstWhere((d) => '${d['id']}' == id);
        district['province'] = province;
        _setCache('district', id, district);
        return district;
      } catch (_) {
       
        continue;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSubDistrict(
    String id,
    String? parentDistrictId,
  ) async {
  
    if (_getCache('subdistrict', id) != null)
      return _getCache('subdistrict', id);

   
    if (parentDistrictId != null) {
      final result = await _getSubDistrictWithParent(id, parentDistrictId);
      if (result != null) return result;
    }

  
    return await _searchSubDistrictInAllProvinces(id);
  }

 
  Future<Map<String, dynamic>?> _getSubDistrictWithParent(
    String id,
    String parentDistrictId,
  ) async {
    final district = await getDistrict(parentDistrictId);
    if (district == null) return null;

    final subs = await _request(
      '${AppConstants.apiUrl}/sub-districts/${district['code']}',
    );

    try {
      final sub = subs.firstWhere((s) => '${s['id']}' == id);
      sub['district'] = district;
      _setCache('subdistrict', id, sub);
      return sub;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _searchSubDistrictInAllProvinces(
    String id,
  ) async {
    final provinces = await _request('${AppConstants.apiUrl}/provinces');
    for (final province in provinces) {
      final districts = await _request(
        '${AppConstants.apiUrl}/districts/${province['code']}',
      );
      for (final district in districts) {
        final subs = await _request(
          '${AppConstants.apiUrl}/sub-districts/${district['code']}',
        );

     
        try {
          final sub = subs.firstWhere((s) => '${s['id']}' == id);
          sub['district'] = district;
          _setCache('subdistrict', id, sub);
          return sub;
        } catch (_) {
         
          continue;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getVillage(
    String id,
    String? subdistrictId,
    String? districtId,
  ) async {
    if (_getCache('village', id) != null) return _getCache('village', id);

    if (subdistrictId != null) {
      final subdistrict = await getSubDistrict(subdistrictId, districtId);
      if (subdistrict != null) {
        final villages = await _request(
          '${AppConstants.apiUrl}/villages/${subdistrict['code']}',
        );

    
        try {
          final village = villages.firstWhere((v) => '${v['id']}' == id);
          village['subdistrict'] = subdistrict;
          _setCache('village', id, village);
          return village;
        } catch (_) {
       
        }
      }
    }

    final provinces = await _request('${AppConstants.apiUrl}/provinces');
    for (final province in provinces) {
      final districts = await _request(
        '${AppConstants.apiUrl}/districts/${province['code']}',
      );
      for (final district in districts) {
        final subs = await _request(
          '${AppConstants.apiUrl}/sub-districts/${district['code']}',
        );
        for (final subdistrict in subs) {
          final villages = await _request(
            '${AppConstants.apiUrl}/villages/${subdistrict['code']}',
          );

      
          try {
            final village = villages.firstWhere((v) => '${v['id']}' == id);
            village['subdistrict'] = subdistrict;
            _setCache('village', id, village);
            return village;
          } catch (_) {
         
            continue;
          }
        }
      }
    }

    return null;
  }
}

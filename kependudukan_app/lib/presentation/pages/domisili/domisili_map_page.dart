import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_kependudukan/core/theme/app_theme.dart';
import 'package:flutter_kependudukan/core/services/message_service.dart';
import 'package:flutter_kependudukan/presentation/cubits/domisili/domisili_cubit.dart';
import 'package:flutter_kependudukan/presentation/widgets/common/location_map_component.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_kependudukan/core/constants/app_constants.dart';

class DomisiliMapPage extends StatefulWidget {
  final String nik;
  final String kk;

  const DomisiliMapPage({super.key, required this.nik, required this.kk});

  @override
  State<DomisiliMapPage> createState() => _DomisiliMapPageState();
}

class _DomisiliMapPageState extends State<DomisiliMapPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  late final DomisiliCubit _domisiliCubit;
  final MapController _mapController = MapController();
  bool _isSaving = false;

  LatLng _currentPosition = const LatLng(
    -7.310000,
    110.290000,
  );

  @override
  void initState() {
    super.initState();
    _domisiliCubit = GetIt.instance<DomisiliCubit>();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    await _domisiliCubit.loadFamilyMember(widget.kk, widget.nik,
        forceRefresh: forceRefresh);
  }

  Future<Map<String, dynamic>?> _getCitizenData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/citizens/${widget.nik}'),
        headers: {
          'X-API-Key': AppConstants.apiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching citizen data: $e');
      return null;
    }
  }

  Map<String, dynamic> _convertDataToApiFormat(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convert gender
    if (result['gender'] == 'Laki-Laki')
      result['gender'] = 1;
    else if (result['gender'] == 'Perempuan') result['gender'] = 2;

    // Convert citizen status
    if (result['citizen_status'] == 'WNI')
      result['citizen_status'] = 1;
    else if (result['citizen_status'] == 'WNA') result['citizen_status'] = 2;

    // Convert family status
    final familyStatusMap = {
      'ANAK': 1,
      'Anak': 1,
      'KEPALA KELUARGA': 2,
      'Kepala Keluarga': 2,
      'ISTRI': 3,
      'Istri': 3,
      'ORANG TUA': 4,
      'Orang Tua': 4,
      'MERTUA': 5,
      'Mertua': 5,
      'CUCU': 6,
      'Cucu': 6,
      'FAMILI LAIN': 7,
      'Famili Lain': 7
    };
    if (result['family_status'] is String &&
        familyStatusMap[result['family_status']] != null) {
      result['family_status'] = familyStatusMap[result['family_status']];
    }

    // Convert blood type
    final bloodTypeMap = {
      'A': 1,
      'B': 2,
      'AB': 3,
      'O': 4,
      'A+': 5,
      'A-': 6,
      'B+': 7,
      'B-': 8,
      'AB+': 9,
      'AB-': 10,
      'O+': 11,
      'O-': 12,
      'Tidak Tahu': 13
    };
    if (bloodTypeMap[result['blood_type']] != null) {
      result['blood_type'] = bloodTypeMap[result['blood_type']];
    }

    // Convert religion
    final religionMap = {
      'Islam': 1,
      'Kristen': 2,
      'Katolik': 3,
      'Katholik': 3,
      'Hindu': 4,
      'Buddha': 5,
      'Budha': 5,
      'Kong Hu Cu': 6,
      'Konghucu': 6,
      'Lainnya': 7
    };
    if (religionMap[result['religion']] != null) {
      result['religion'] = religionMap[result['religion']];
    }

    // Convert marital status
    final maritalMap = {
      'Belum Kawin': 1,
      'Kawin Tercatat': 2,
      'Kawin Belum Tercatat': 3,
      'Cerai Hidup Tercatat': 4,
      'Cerai Hidup Belum Tercatat': 5,
      'Cerai Mati': 6
    };
    if (maritalMap[result['marital_status']] != null) {
      result['marital_status'] = maritalMap[result['marital_status']];
    }

    // Convert certificate statuses
    if (result['birth_certificate'] == 'Ada')
      result['birth_certificate'] = 1;
    else if (result['birth_certificate'] == 'Tidak Ada')
      result['birth_certificate'] = 2;

    if (result['marital_certificate'] == 'Ada')
      result['marital_certificate'] = 1;
    else if (result['marital_certificate'] == 'Tidak Ada')
      result['marital_certificate'] = 2;

    if (result['divorce_certificate'] == 'Ada')
      result['divorce_certificate'] = 1;
    else if (result['divorce_certificate'] == 'Tidak Ada')
      result['divorce_certificate'] = 2;

    if (result['mental_disorders'] == 'Ada')
      result['mental_disorders'] = 1;
    else if (result['mental_disorders'] == 'Tidak Ada')
      result['mental_disorders'] = 2;

    // Convert disabilities
    final disabilitiesMap = {
      'Fisik': 1,
      'Netra/Buta': 2,
      'Rungu/Wicara': 3,
      'Mental/Jiwa': 4,
      'Fisik dan Mental': 5,
      'Lainnya': 6
    };
    if (result['disabilities'] is String) {
      if (result['disabilities'].isEmpty || result['disabilities'] == ' ') {
        result['disabilities'] = null;
      } else if (disabilitiesMap[result['disabilities']] != null) {
        result['disabilities'] = disabilitiesMap[result['disabilities']];
      }
    }

    // Convert education status
    final educationMap = {
      'Tidak/Belum Sekolah': 1,
      'Belum tamat SD/Sederajat': 2,
      'Tamat SD': 3,
      'SLTP/SMP/Sederajat': 4,
      'SLTA/SMA/Sederajat': 5,
      'Diploma I/II': 6,
      'Akademi/Diploma III/ Sarjana Muda': 7,
      'Diploma IV/ Strata I/ Strata II': 8,
      'Strata III': 9,
      'Lainnya': 10
    };
    if (educationMap[result['education_status']] != null) {
      result['education_status'] = educationMap[result['education_status']];
    }

    // Convert dates
    if (result['birth_date'] != null &&
        result['birth_date'].toString().contains('/')) {
      final parts = result['birth_date'].split('/');
      if (parts.length == 3) {
        result['birth_date'] = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }

    // Handle empty values
    if (result['marriage_date'] == '') result['marriage_date'] = ' ';
    if (result['divorce_certificate_date'] == '')
      result['divorce_certificate_date'] = ' ';
    if (result['birth_certificate_no'] == '')
      result['birth_certificate_no'] = ' ';
    if (result['marital_certificate_no'] == '')
      result['marital_certificate_no'] = ' ';
    if (result['divorce_certificate_no'] == '')
      result['divorce_certificate_no'] = ' ';

    return result;
  }

  Future<void> _saveLocation() async {
    if (_isSaving) return;

    final lat = _latitudeController.text;
    final lng = _longitudeController.text;

    if (lat.isEmpty || lng.isEmpty) {
      MessageService.showErrorSnackBar(
        context,
        'Pilih lokasi pada peta terlebih dahulu',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get current citizen data
      final citizenData = await _getCitizenData();
      if (citizenData == null) {
        throw Exception('Data penduduk tidak ditemukan');
      }

      // Convert data to API format
      final apiData = _convertDataToApiFormat(citizenData);

      // Add coordinate
      apiData['coordinate'] = '${lat},${lng}';

      // Update the citizen data
      final response = await http.put(
        Uri.parse('${AppConstants.apiUrl}/citizens/${widget.nik}'),
        headers: {
          'X-API-Key': AppConstants.apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(apiData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'OK') {
          // Update the coordinate in the cubit
          await _domisiliCubit.updateCoordinate(
            widget.nik,
            LatLng(double.parse(lat), double.parse(lng)),
          );

          MessageService.showSuccessSnackBar(
            context,
            'Lokasi berhasil disimpan',
          );

          // Force refresh the data
          await _loadData(forceRefresh: true);
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menyimpan lokasi');
        }
      } else {
        throw Exception('Gagal menyimpan lokasi: ${response.statusCode}');
      }
    } catch (e) {
      MessageService.showErrorSnackBar(
        context,
        'Gagal menyimpan lokasi: ${e.toString()}',
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _onLocationSelected(LatLng position) {
    setState(() {
      _currentPosition = position;
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lokasi Domisili',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(forceRefresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<DomisiliCubit, DomisiliState>(
        bloc: _domisiliCubit,
        listener: (context, state) {
          if (state is DomisiliLoaded) {
            if (state.member.coordinate != null &&
                state.member.coordinate!.isNotEmpty) {
              final coords = state.member.coordinate!.split(',');
              if (coords.length == 2) {
                try {
                  double lat = double.parse(coords[0]);
                  double lng = double.parse(coords[1]);
                  _currentPosition = LatLng(lat, lng);
                  _latitudeController.text = lat.toStringAsFixed(6);
                  _longitudeController.text = lng.toStringAsFixed(6);
                } catch (e) {
                  print('Error parsing coordinates: $e');
                }
              }
            }
          } else if (state is DomisiliError) {
            MessageService.showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is DomisiliInitial || state is DomisiliLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is DomisiliError && !(state is DomisiliLoaded)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _loadData(forceRefresh: true),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Get member data if available
          final member = state is DomisiliLoaded ? state.member : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info card
                if (member != null)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.primaryColor,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'NIK: ${member.nik}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Map title
                const Text(
                  'Pilih Lokasi pada Peta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: 10),

                // Map component
                LocationMapComponent(
                  initialPosition: _currentPosition,
                  mode: MapMode.select,
                  onLocationSelected: _onLocationSelected,
                  mapController: _mapController,
                ),

                const SizedBox(height: 16),

                // Latitude & Longitude
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitudeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _longitudeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SIMPAN LOKASI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_kependudukan/core/theme/app_theme.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:flutter_kependudukan/core/services/message_service.dart';
import 'package:flutter_kependudukan/presentation/widgets/profile/profile_header.dart';
import 'package:flutter_kependudukan/presentation/widgets/profile/info_section.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({Key? key, required this.nik}) : super(key: key);
  final String nik;

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = GetIt.instance<AuthRepository>();
      final result = await repository.getPendudukDetail(widget.nik);

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (data) {
          setState(() {
            _profileData = data;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = MessageService.getErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Data Diri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(
            name: _profileData?['full_name'] ?? 'Tidak ada nama',
            nik: _profileData?['nik']?.toString() ?? '-',
          ),
          const SizedBox(height: 24),

          InfoSection(
            title: 'Informasi Pribadi',
            items: [
              {
                'label': 'NIK',
                'value': _profileData?['nik']?.toString() ?? '-',
              },
              {
                'label': 'No. KK',
                'value': _profileData?['kk']?.toString() ?? '-',
              },
              {
                'label': 'Jenis Kelamin',
                'value': _profileData?['gender'] ?? '-',
              },
              {
                'label': 'Umur',
                'value': '${_profileData?['age']?.toString() ?? '-'} Tahun',
              },
              {
                'label': 'Tempat Lahir',
                'value': _profileData?['birth_place'] ?? '-',
              },
              {
                'label': 'Tanggal Lahir',
                'value': _formatDate(_profileData?['birth_date']),
              },
            ],
          ),

          const SizedBox(height: 24),

          InfoSection(
            title: 'Informasi Alamat',
            items: [
              {'label': 'Alamat', 'value': _profileData?['address'] ?? '-'},
              {
                'label': 'RT/RW',
                'value':
                    '${_profileData?['rt'] ?? '-'}/${_profileData?['rw'] ?? '-'}',
              },
              {
                'label': 'Provinsi',
                'value': _profileData?['province_name'] ?? '-',
              },
              {
                'label': 'Kabupaten/Kota',
                'value': _profileData?['district_name'] ?? '-',
              },
              {
                'label': 'Kecamatan',
                'value': _profileData?['sub_district_name'] ?? '-',
              },
              {
                'label': 'Desa/Kelurahan',
                'value': _profileData?['village_name'] ?? '-',
              },
            ],
          ),
        ],
      ),
    );
  }
}

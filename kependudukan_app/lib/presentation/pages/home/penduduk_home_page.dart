import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_kependudukan/core/services/message_service.dart';
import 'package:flutter_kependudukan/domain/entities/penduduk.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';
import 'package:flutter_kependudukan/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_kependudukan/presentation/blocs/auth/auth_event.dart';
import 'package:flutter_kependudukan/presentation/blocs/auth/auth_state.dart';
import 'package:flutter_kependudukan/presentation/pages/asset/asset_list_page.dart';
import 'package:flutter_kependudukan/presentation/pages/auth/login_page.dart';
import 'package:flutter_kependudukan/presentation/pages/domisili/domisili_map_page.dart';
import 'package:flutter_kependudukan/presentation/pages/family/family_list_page.dart';
import 'package:flutter_kependudukan/presentation/pages/profile/profile_details_page.dart';
import 'package:flutter_kependudukan/presentation/pages/webview/document_services_webview_page.dart';
import 'package:flutter_kependudukan/presentation/widgets/menu_item.dart';
import 'package:flutter_kependudukan/presentation/widgets/notification_item.dart';
import 'package:flutter_kependudukan/presentation/widgets/profile_card.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_kependudukan/core/constants/app_constants.dart';
import 'package:flutter_kependudukan/presentation/pages/village_report/laporan_page.dart';
import 'package:flutter_kependudukan/presentation/pages/riwayat-surat/riwayat_surat_page.dart';
import 'package:flutter_kependudukan/presentation/pages/berita-desa/berita_desa_page.dart';
import 'package:flutter_kependudukan/data/datasources/berita_desa_api_service.dart';
import 'package:flutter_kependudukan/data/models/berita_desa_model.dart';
import 'package:flutter_kependudukan/data/datasources/auth_local_storage.dart';
import 'package:flutter_kependudukan/core/error/exceptions.dart';
import 'package:intl/intl.dart';

class PendudukHomePage extends StatefulWidget {
  final Penduduk penduduk;
  const PendudukHomePage({Key? key, required this.penduduk}) : super(key: key);

  @override
  State<PendudukHomePage> createState() => _PendudukHomePageState();
}

class _PendudukHomePageState extends State<PendudukHomePage> {
  bool _isProcessingNavigation = false;
  late final BeritaDesaApiService _beritaDesaApiService;
  List<BeritaDesaModel> _beritaDesa = [];
  bool _isLoadingBerita = true;

  @override
  void initState() {
    super.initState();
    _beritaDesaApiService = BeritaDesaApiService(
      client: http.Client(),
      authLocalStorage: AuthLocalStorage(),
    );
    _loadBeritaDesa();
  }

  Future<void> _loadBeritaDesa() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingBerita = true;
        _beritaDesa = [];
      });

      final berita = await _beritaDesaApiService.getBeritaDesa().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      if (mounted) {
        setState(() {
          _beritaDesa = berita;
          _isLoadingBerita = false;
        });
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBerita = false;
          _beritaDesa = [];
        });
        MessageService.showErrorSnackBar(
            context, e.message ?? 'Koneksi timeout');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBerita = false;
          _beritaDesa = [];
        });
        MessageService.showErrorSnackBar(context, e.message);
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBerita = false;
          _beritaDesa = [];
        });
        MessageService.showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBerita = false;
          _beritaDesa = [];
        });
        MessageService.showErrorSnackBar(
          context,
          'Gagal memuat berita desa: ${e.toString()}',
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _getPendudukDetailAndNavigate({
    required Function(String kk) onSuccess,
    required String errorPrefix,
    required String emptyKkMessage,
  }) async {
    if (_isProcessingNavigation) return;
    setState(() => _isProcessingNavigation = true);

    try {
      final repository = GetIt.instance<AuthRepository>();
      final result = await repository.getPendudukDetail(widget.penduduk.nik);

      if (!mounted) {
        _isProcessingNavigation = false;
        return;
      }

      result.fold(
        (failure) => MessageService.showErrorSnackBar(
            context, '$errorPrefix ${failure.message}'),
        (data) {
          final kk = data['kk']?.toString() ?? '';
          if (kk.isNotEmpty) {
            onSuccess(kk);
          } else {
            MessageService.showInfoSnackBar(context, emptyKkMessage);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        MessageService.showErrorSnackBar(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isProcessingNavigation = false);
    }
  }

  Future<void> _navigateToFamilyPage() async {
    await _getPendudukDetailAndNavigate(
      errorPrefix: 'Gagal mendapatkan data keluarga:',
      emptyKkMessage: 'Nomor KK tidak tersedia untuk melihat data keluarga',
      onSuccess: (kk) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FamilyListPage(
            kk: kk,
            nikPenduduk: widget.penduduk.nik,
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDomisiliPage() async {
    await _getPendudukDetailAndNavigate(
      errorPrefix: 'Gagal mendapatkan data:',
      emptyKkMessage: 'Nomor KK tidak tersedia untuk melihat data domisili',
      onSuccess: (kk) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DomisiliMapPage(
            nik: widget.penduduk.nik,
            kk: kk,
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToPage(Widget page) async {
    if (_isProcessingNavigation) return;
    setState(() => _isProcessingNavigation = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      if (mounted) {
        MessageService.showErrorSnackBar(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isProcessingNavigation = false);
    }
  }

  Future<void> _navigateToProfilePage() async {
    await _navigateToPage(ProfileDetailsPage(nik: widget.penduduk.nik));
  }

  Future<void> _navigateToAssetPage() async {
    await _navigateToPage(const AssetListPage());
  }

  Widget _buildProfileSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat datang di',
            style: TextStyle(fontSize: 16, color: Color(0xFF4A47DC)),
          ),
          const Text(
            'Layanan Kependudukan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A47DC),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>>(
            future: _getPendudukDetail(widget.penduduk.nik),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final fullName =
                  snapshot.data?['data']?['full_name'] ?? widget.penduduk.name;

              return ProfileCard(
                nim: widget.penduduk.nik,
                name: fullName.isNotEmpty ? fullName : "Penduduk",
                noHp: widget.penduduk.noHp,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      );

  Future<Map<String, dynamic>> _getPendudukDetail(String nik) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/citizens/$nik'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-Key': AppConstants.apiKey,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load citizen data');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Widget _buildMenuGrid() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              MenuItem(
                title: 'Data Diri',
                icon: Icons.person,
                color: const Color(0xFF4A47DC),
                onTap: _navigateToProfilePage,
              ),
              MenuItem(
                title: 'Keluarga',
                icon: Icons.family_restroom,
                color: Colors.green,
                onTap: _navigateToFamilyPage,
              ),
              MenuItem(
                title: 'Surat',
                icon: Icons.article_outlined,
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentServicesWebViewPage(),
                    ),
                  );
                },
              ),
              MenuItem(
                title: 'Riwayat',
                icon: Icons.history,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiwayatSuratPage(),
                    ),
                  );
                },
              ),
              MenuItem(
                title: 'Lapor Desa',
                icon: Icons.announcement,
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VillageReportPage(),
                  ),
                ),
              ),
              MenuItem(
                title: 'Kelola Aset',
                icon: Icons.inventory_2,
                color: Colors.teal,
                onTap: _navigateToAssetPage,
              ),
              MenuItem(
                title: 'Domisili',
                icon: Icons.location_on,
                color: Colors.blue,
                onTap: _navigateToDomisiliPage,
              ),
              MenuItem(
                title: 'Lainnya',
                icon: Icons.more_horiz,
                color: Colors.orange,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      );

  Widget _buildNotificationSection() => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengumuman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BeritaDesaPage(),
                    ),
                  );
                },
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(color: Color(0xFF4A47DC), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingBerita)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_beritaDesa.isEmpty)
            const Center(
              child: Text('Belum ada pengumuman'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _beritaDesa.length > 2 ? 2 : _beritaDesa.length,
              itemBuilder: (context, index) {
                final berita = _beritaDesa[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationItem(
                    title: berita.judul,
                    message: berita.deskripsi,
                    isNew: index == 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BeritaDesaPage(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      );

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Pengaturan',
          style:
              TextStyle(color: Color(0xFF4A47DC), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar'),
              onTap: () {
                Navigator.pop(ctx);
                _showLogoutDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF4A47DC)),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur Profil sedang dalam pengembangan'),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(12),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A47DC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('TUTUP',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi',
          style:
              TextStyle(color: Color(0xFF4A47DC), fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar?',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('BATAL',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('KELUAR',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  _buildMenuGrid(),
                  _buildNotificationSection(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: const Color(0xFF4A47DC),
          unselectedItemColor: Colors.grey,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(
                icon: Icon(Icons.newspaper), label: 'Berita'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Setting'),
          ],
          onTap: (index) {
            if (index == 2) {
              _showSettingsDialog(context);
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeritaDesaPage(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

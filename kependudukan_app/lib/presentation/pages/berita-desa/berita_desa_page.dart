import 'package:flutter/material.dart';
import '../../../data/datasources/berita_desa_api_service.dart';
import '../../../data/models/berita_desa_model.dart';
import '../../../core/error/exceptions.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../data/datasources/auth_local_storage.dart';

class BeritaDesaPage extends StatefulWidget {
  const BeritaDesaPage({Key? key}) : super(key: key);

  @override
  State<BeritaDesaPage> createState() => _BeritaDesaPageState();
}

class _BeritaDesaPageState extends State<BeritaDesaPage> {
  late final BeritaDesaApiService _beritaDesaApiService;
  List<BeritaDesaModel> _beritaDesa = [];
  bool _isLoading = true;
  String? _error;

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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final berita = await _beritaDesaApiService.getBeritaDesa();
      setState(() {
        _beritaDesa = berita;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on ServerException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Desa'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBeritaDesa,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _beritaDesa.isEmpty
                  ? const Center(
                      child: Text('Belum ada berita desa'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBeritaDesa,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _beritaDesa.length,
                        itemBuilder: (context, index) {
                          final berita = _beritaDesa[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (berita.gambarUrl.isNotEmpty)
                                  Image.network(
                                    berita.gambarUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.grey,
                                          size: 50,
                                        ),
                                      );
                                    },
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        berita.judul,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        berita.deskripsi,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      if (berita.komentar.isNotEmpty) ...[
                                        Text(
                                          'Komentar: ${berita.komentar}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      Text(
                                        'Tanggal: ${_formatDate(berita.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

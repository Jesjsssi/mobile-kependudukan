import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_kependudukan/core/theme/app_theme.dart';
import 'package:flutter_kependudukan/core/services/message_service.dart';
import 'package:flutter_kependudukan/data/datasources/laporan_api_service.dart';
import 'package:flutter_kependudukan/presentation/widgets/common/location_map_component.dart';
import 'package:flutter_kependudukan/presentation/widgets/custom_button.dart';
import 'package:flutter_kependudukan/presentation/widgets/loading_indicator.dart';

class LaporanFormPage extends StatefulWidget {
  const LaporanFormPage({Key? key}) : super(key: key);

  @override
  State<LaporanFormPage> createState() => _LaporanFormPageState();
}

class _LaporanFormPageState extends State<LaporanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  final VillageReportApiService _apiService =
      GetIt.instance<VillageReportApiService>();

  bool _isLoading = false;
  bool _isLoadingOptions = true;
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  List<RuangLingkupData> _ruangLingkupOptions = [];
  RuangLingkupData? _selectedOption;

  // Default location - can be customized to current user's village
  LatLng _selectedLocation = const LatLng(-7.310000, 110.290000);

  @override
  void initState() {
    super.initState();
    _loadRuangLingkupOptions();
  }

  Future<void> _loadRuangLingkupOptions() async {
    try {
      setState(() {
        _isLoadingOptions = true;
      });

      final options = await _apiService.getLaporDesaOptions();

      setState(() {
        _ruangLingkupOptions = options;
        _isLoadingOptions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOptions = false;
      });
      MessageService.showErrorSnackBar(
          context, 'Gagal memuat data ruang lingkup: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      MessageService.showErrorSnackBar(
          context, 'Gagal mengambil gambar: ${e.toString()}');
    }
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      MessageService.showErrorSnackBar(
          context, 'Mohon pilih gambar untuk laporan');
      return;
    }

    if (_selectedOption == null) {
      MessageService.showErrorSnackBar(
          context, 'Mohon pilih ruang lingkup laporan');
      return;
    }

    // Validate that the ID is a valid integer
    if (_selectedOption!.id <= 0) {
      MessageService.showErrorSnackBar(
          context, 'ID ruang lingkup tidak valid. Silakan pilih opsi lain.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Format coordinates with exactly 6 decimal places for consistency and accuracy
      final locationString =
          "${_selectedLocation.latitude.toStringAsFixed(6)},${_selectedLocation.longitude.toStringAsFixed(6)}";

      // Ensure we're using the integer ID
      final int ruangLingkupId = _selectedOption!.id;
      print(
          "Selected ruang lingkup ID: $ruangLingkupId (${ruangLingkupId.runtimeType})");

      await _apiService.createVillageReport(
        judulLaporan: _judulController.text,
        deskripsiLaporan: _deskripsiController.text,
        tagLokasi: locationString,
        gambar: _selectedImage!,
        ruangLingkupId: ruangLingkupId,
      );

      MessageService.showSuccessSnackBar(
          context, 'Laporan berhasil dikirim dan sedang menunggu diproses.');
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      MessageService.showErrorSnackBar(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Desa'),
        backgroundColor: const Color(0xFF4A47DC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading || _isLoadingOptions
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ruang Lingkup dan Bidang
                    const Text(
                      'Ruang Lingkup dan Bidang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RuangLingkupData>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Pilih Ruang Lingkup',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      value: _selectedOption,
                      items: _ruangLingkupOptions.map((option) {
                        return DropdownMenuItem<RuangLingkupData>(
                          value: option,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option.ruangLingkup,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                option.bidang,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Ruang lingkup harus dipilih';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Judul Laporan
                    const Text(
                      'Judul Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _judulController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan judul laporan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Judul laporan harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi Laporan
                    const Text(
                      'Deskripsi Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan deskripsi lengkap laporan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deskripsi laporan harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Location Map
                    const Text(
                      'Lokasi Kejadian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LocationMapComponent(
                      initialPosition: _selectedLocation,
                      mode: MapMode.select,
                      onLocationSelected: (position) {
                        setState(() {
                          _selectedLocation = position;
                        });
                        print(
                            "Selected location: ${position.latitude}, ${position.longitude}");
                      },
                      height: 250,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Koordinat Terpilih:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Latitude: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Longitude: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Picker
                    const Text(
                      'Foto Kejadian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Pilih Foto',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomButton(
                      text: 'Kirim Laporan',
                      onPressed: _submitLaporan,
                      backgroundColor: const Color(0xFF4A47DC),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

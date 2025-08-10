import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Aplikasi Kependudukan';
  static const String dbName = 'kependudukan.db';
  static const int dbVersion = 2;

  static String get apiUrl => dotenv.env['API_URL'] ?? '';
  static String get authApiUrl => dotenv.env['AUTH_API_URL'] ?? '';
  static String get storageUrl => dotenv.env['STORAGE_URL'] ?? '';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  static const String endpointCheckNik = '/all-citizens';
  static const String endpointRegister = '/register';
  static const String endpointLogin = '/login';

  static const String errorNetworkMessage =
      'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.';
  static const String errorRegistrationFailed = 'Registrasi gagal: ';
  static const String error404Message =
      'Endpoint tidak ditemukan. Hubungi administrator.';

  static const String errorAuthFailed = 'NIK atau password tidak valid.';
  static const String errorNikExists = 'NIK sudah terdaftar.';
  static const String successRegistration = 'Registrasi berhasil!';
  static const String errorServerMessage = 'Terjadi kesalahan pada server';

  static const bool isDebugMode = true;
}

// UI Related constants
class UiConstants {
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}

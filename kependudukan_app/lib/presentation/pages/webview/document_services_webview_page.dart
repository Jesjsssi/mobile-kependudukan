import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_kependudukan/data/datasources/auth_local_storage.dart';
import 'package:flutter_kependudukan/core/constants/app_constants.dart';
import 'package:get_it/get_it.dart';

class DocumentServicesWebViewPage extends StatefulWidget {
  const DocumentServicesWebViewPage({Key? key}) : super(key: key);

  @override
  State<DocumentServicesWebViewPage> createState() =>
      _DocumentServicesWebViewPageState();
}

class _DocumentServicesWebViewPageState
    extends State<DocumentServicesWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // Location IDs
  int? _provinceId;
  int? _districtId;
  int? _subDistrictId;
  int? _villageId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get auth storage instance
      final authLocalStorage = GetIt.instance<AuthLocalStorage>();

      // Get stored user data (NIK)
      final userData = await authLocalStorage.getUserCredentials();
      if (userData == null) {
        setState(() {
          _errorMessage = 'User data not found. Please login again.';
        });
        return;
      }

      final nik = userData['nik'];

      // Get user details including location data
      await _loadUserLocationData(nik);

      // Initialize WebView after data is loaded
      if (_provinceId != null &&
          _districtId != null &&
          _subDistrictId != null &&
          _villageId != null) {
        _initializeWebView();
      } else {
        setState(() {
          _errorMessage = 'Location data is incomplete. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: $e';
      });
    }
  }

  Future<void> _loadUserLocationData(String nik) async {
    try {
      // Get user data from the penduduk API
      final response = await GetIt.instance<http.Client>().get(
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

        // Find the citizen with the matching NIK
        for (var citizen in citizens) {
          if (citizen['nik'].toString() == nik) {
            setState(() {
              _provinceId = citizen['province_id'] ?? 0;
              _districtId = citizen['district_id'] ?? 0;
              _subDistrictId = citizen['sub_district_id'] ?? 0;
              _villageId = citizen['village_id'] ?? 0;
            });
            return;
          }
        }

        setState(() {
          _errorMessage = 'User with NIK $nik not found';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch user data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user location data: $e';
      });
    }
  }

  void _initializeWebView() {
    // Build the URL with location IDs
    final url =
        'https://pelayanan.desaverse.id/pelayanan/list/$_provinceId/$_districtId/$_subDistrictId/$_villageId';

    // Create WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar
            if (progress < 100) {
              setState(() {
                _isLoading = true;
              });
            } else {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Error loading page: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Surat'),
        elevation: 0,
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _loadUserData();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}

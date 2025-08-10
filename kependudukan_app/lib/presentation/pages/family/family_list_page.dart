import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_kependudukan/core/theme/app_theme.dart';
import 'package:flutter_kependudukan/presentation/cubits/family/family_cubit.dart';
import 'package:flutter_kependudukan/presentation/pages/family/family_member_document_page.dart';
import 'package:get_it/get_it.dart';

class FamilyListPage extends StatefulWidget {
  final String kk;
  final String nikPenduduk;

  const FamilyListPage({Key? key, required this.kk, required this.nikPenduduk})
      : super(key: key);

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  late final FamilyCubit _familyCubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _familyCubit = GetIt.instance<FamilyCubit>();
    _loadFamilyData();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _familyCubit.loadMoreMembers();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyData({bool forceRefresh = false}) async {
    await _familyCubit.loadFamilyMembers(widget.kk, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Data Keluarga',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFamilyData(forceRefresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<FamilyCubit, FamilyState>(
        bloc: _familyCubit,
        builder: (context, state) {
          if (state is FamilyInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is FamilyLoading && (state.currentMembers.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (state is FamilyError) {
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
                      onPressed: () => _loadFamilyData(forceRefresh: true),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is FamilyEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data anggota keluarga',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final members = state is FamilyLoaded ? state.members : [];
          final isLoadingMore = state is FamilyLoading;

          return RefreshIndicator(
            onRefresh: () => _loadFamilyData(forceRefresh: true),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: members.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= members.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final member = members[index];
                final bool isCurrentUser = member.nik == widget.nikPenduduk;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCurrentUser
                        ? const BorderSide(
                            color: AppTheme.primaryColor, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCurrentUser
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                color: isCurrentUser
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                  const SizedBox(height: 4),
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(member.familyStatus),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _formatFamilyStatus(member.familyStatus),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '(Anda)',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),

                        // Documents button
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FamilyMemberDocumentsPage(
                                        nik: member.nik,
                                        name: member.fullName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.file_copy, size: 18),
                                label: const Text('Dokumen'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('kepala keluarga')) return Colors.blue.shade700;
    if (status.contains('istri')) return Colors.pink.shade400;
    if (status.contains('anak')) return Colors.green.shade600;
    if (status.contains('cucu')) return Colors.orange.shade600;
    return Colors.purple.shade400;
  }

  String _formatFamilyStatus(String status) {
    if (status.isNotEmpty) {
      return status[0].toUpperCase() + status.substring(1);
    }
    return status;
  }
}

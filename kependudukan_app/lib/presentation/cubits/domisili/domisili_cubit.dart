import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_kependudukan/data/models/family_member_model.dart';
import 'package:flutter_kependudukan/domain/repositories/family_repository.dart';
import 'package:latlong2/latlong.dart';

part 'domisili_state.dart';

class DomisiliCubit extends Cubit<DomisiliState> {
  final FamilyRepository repository;

  final Map<String, FamilyMemberModel> _memberCache = {};
  final Map<String, DateTime> _memberCacheTimestamp = {};
  final Duration _cacheDuration = const Duration(minutes: 15);

  DomisiliCubit({required this.repository}) : super(DomisiliInitial());

  Future<void> loadFamilyMember(String kk, String nik,
      {bool forceRefresh = false}) async {
    if (state is DomisiliLoading) return;

    if (!forceRefresh) {
      final cachedMember = _getCachedMember(nik);
      if (cachedMember != null) {
        emit(DomisiliLoaded(member: cachedMember));
        return;
      }
    }

    emit(DomisiliLoading());

    final result =
        await repository.getFamilyMembers(kk, forceRefresh: forceRefresh);

    result.fold((failure) => emit(DomisiliError(message: failure.message)),
        (members) {
      try {
        final member = members.firstWhere((m) => m.nik == nik);

        _memberCache[nik] = member;
        _memberCacheTimestamp[nik] = DateTime.now();

        emit(DomisiliLoaded(member: member));
      } catch (e) {
        emit(const DomisiliError(message: 'Member not found'));
      }
    });
  }

  FamilyMemberModel? _getCachedMember(String nik) {
    if (_memberCache.containsKey(nik) &&
        _memberCacheTimestamp.containsKey(nik)) {
      final timestamp = _memberCacheTimestamp[nik]!;
      final now = DateTime.now();
      if (now.difference(timestamp) < _cacheDuration) {
        return _memberCache[nik];
      }
    }
    return null;
  }

  Future<void> updateCoordinate(String nik, LatLng position) async {
    if (state is DomisiliLoading) return;

    final coordinate = "${position.latitude},${position.longitude}";
    emit(DomisiliUpdating(
        member:
            state is DomisiliLoaded ? (state as DomisiliLoaded).member : null));

    final result =
        await repository.updateFamilyMemberCoordinate(nik, coordinate);

    result.fold((failure) => emit(DomisiliError(message: failure.message)),
        (success) {
      if (success && state is DomisiliLoaded) {
        final currentMember = (state as DomisiliLoaded).member;
        final updatedMember = currentMember.copyWith(coordinate: coordinate);

        _memberCache[nik] = updatedMember;
        _memberCacheTimestamp[nik] = DateTime.now();

        emit(DomisiliLoaded(member: updatedMember));
      }
    });
  }

  void clearCache() {
    _memberCache.clear();
    _memberCacheTimestamp.clear();
  }
}

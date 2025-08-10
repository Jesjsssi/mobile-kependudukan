import 'package:equatable/equatable.dart';

class FamilyMember extends Equatable {
  final String nik;
  final String fullName;
  final String familyStatus;
  final String? coordinate;

  const FamilyMember({
    required this.nik,
    required this.fullName,
    required this.familyStatus,
    this.coordinate,
  });

  @override
  List<Object?> get props => [nik, fullName, familyStatus, coordinate];
}

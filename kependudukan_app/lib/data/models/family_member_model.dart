import 'package:flutter_kependudukan/domain/entities/family_member.dart';

class FamilyMemberModel extends FamilyMember {
  const FamilyMemberModel({
    required super.nik,
    required super.fullName,
    required super.familyStatus,
    super.coordinate,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      nik: json['nik']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      familyStatus: json['family_status']?.toString() ?? '',
      coordinate: json['coordinate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'full_name': fullName,
      'family_status': familyStatus,
      'coordinate': coordinate,
    };
  }

  FamilyMemberModel copyWith({
    String? nik,
    String? fullName,
    String? familyStatus,
    String? coordinate,
  }) {
    return FamilyMemberModel(
      nik: nik ?? this.nik,
      fullName: fullName ?? this.fullName,
      familyStatus: familyStatus ?? this.familyStatus,
      coordinate: coordinate ?? this.coordinate,
    );
  }
}

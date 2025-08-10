import 'package:equatable/equatable.dart';

class DocumentModel extends Equatable {
  final bool exists;
  final String filePath;
  final String extension;
  final DateTime? updatedAt;
  final String previewUrl;

  const DocumentModel({
    required this.exists,
    required this.filePath,
    required this.extension,
    this.updatedAt,
    required this.previewUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      exists: json['exists'] ?? false,
      filePath: json['file_path'] ?? '',
      extension: json['extension'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      previewUrl: json['preview_url'] ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [exists, filePath, extension, updatedAt, previewUrl];
}

class FamilyMemberDocuments extends Equatable {
  final DocumentModel? fotoDiri;
  final DocumentModel? fotoKtp;
  final DocumentModel? fotoAkta;
  final DocumentModel? ijazah;
  final DocumentModel? fotoKk;
  final DocumentModel? fotoRumah;

  const FamilyMemberDocuments({
    this.fotoDiri,
    this.fotoKtp,
    this.fotoAkta,
    this.ijazah,
    this.fotoKk,
    this.fotoRumah,
  });

  factory FamilyMemberDocuments.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDocuments(
      fotoDiri: json['foto_diri'] != null
          ? DocumentModel.fromJson(json['foto_diri'])
          : null,
      fotoKtp: json['foto_ktp'] != null
          ? DocumentModel.fromJson(json['foto_ktp'])
          : null,
      fotoAkta: json['foto_akta'] != null
          ? DocumentModel.fromJson(json['foto_akta'])
          : null,
      ijazah: json['ijazah'] != null
          ? DocumentModel.fromJson(json['ijazah'])
          : null,
      fotoKk: json['foto_kk'] != null
          ? DocumentModel.fromJson(json['foto_kk'])
          : null,
      fotoRumah: json['foto_rumah'] != null
          ? DocumentModel.fromJson(json['foto_rumah'])
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [fotoDiri, fotoKtp, fotoAkta, ijazah, fotoKk, fotoRumah];
}

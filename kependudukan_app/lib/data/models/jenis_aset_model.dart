class JenisAsetModel {
  final String id;
  final String jenisAset;
  final String kode;
  final String keterangan;

  JenisAsetModel({
    required this.id,
    required this.jenisAset,
    required this.kode,
    required this.keterangan,
  });

  factory JenisAsetModel.fromJson(Map<String, dynamic> json) {
    return JenisAsetModel(
      id: json['id']?.toString() ?? '',
      jenisAset: json['jenis_aset'] ?? '',
      kode: json['kode']?.toString() ?? '',
      keterangan: json['keterangan'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenis_aset': jenisAset,
      'kode': kode,
      'keterangan': keterangan,
    };
  }
}

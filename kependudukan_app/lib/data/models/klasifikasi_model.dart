class KlasifikasiModel {
  final String id;
  final String jenisKlasifikasi;

  KlasifikasiModel({
    required this.id,
    required this.jenisKlasifikasi,
  });

  factory KlasifikasiModel.fromJson(Map<String, dynamic> json) {
    return KlasifikasiModel(
      id: json['id']?.toString() ?? '',
      jenisKlasifikasi: json['jenis_klasifikasi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenis_klasifikasi': jenisKlasifikasi,
    };
  }
}

class BeritaDesaModel {
  final int id;
  final String judul;
  final String deskripsi;
  final String komentar;
  final String gambar;
  final String gambarUrl;
  final int userId;
  final String createdAt;
  final String updatedAt;

  BeritaDesaModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.komentar,
    required this.gambar,
    required this.gambarUrl,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BeritaDesaModel.fromJson(Map<String, dynamic> json) {
    return BeritaDesaModel(
      id: json['id'] as int,
      judul: json['judul'] as String,
      deskripsi: json['deskripsi'] as String,
      komentar: json['komentar'] as String,
      gambar: json['gambar'] as String,
      gambarUrl: json['gambar_url'] as String,
      userId: json['user_id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'komentar': komentar,
      'gambar': gambar,
      'gambar_url': gambarUrl,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class RiwayatSuratModel {
  final int id;
  final String? letter_number;
  final String? purpose;
  final String letter_type;
  final String created_at;
  final int is_accepted;

  RiwayatSuratModel({
    required this.id,
    this.letter_number,
    this.purpose,
    required this.letter_type,
    required this.created_at,
    required this.is_accepted,
  });

  factory RiwayatSuratModel.fromJson(Map<String, dynamic> json) {
    return RiwayatSuratModel(
      id: json['id'] as int,
      letter_number: json['letter_number'] as String?,
      purpose: json['purpose'] as String?,
      letter_type: json['letter_type'] as String,
      created_at: json['created_at'] as String,
      is_accepted: json['is_accepted'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'letter_number': letter_number,
      'purpose': purpose,
      'letter_type': letter_type,
      'created_at': created_at,
      'is_accepted': is_accepted,
    };
  }
}

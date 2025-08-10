import 'package:equatable/equatable.dart';

class Penduduk extends Equatable {
  final String nik;
  final String noHp;
  final String name;
  final String token;

  const Penduduk({
    required this.nik,
    required this.noHp,
    this.name = '',
    required this.token,
  });

  @override
  List<Object?> get props => [nik, noHp, name, token];
}

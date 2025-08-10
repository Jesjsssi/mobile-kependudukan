import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';

class RegisterPendudukUseCase {
  final AuthRepository repository;

  RegisterPendudukUseCase(this.repository);

  Future<Either<Failure, bool>> call(RegisterPendudukParams params) async {
    return await repository.registerPenduduk(
      params.nik,
      params.password,
      params.noHp,
    );
  }
}

class RegisterPendudukParams extends Equatable {
  final String nik;
  final String password;
  final String noHp;

  const RegisterPendudukParams({
    required this.nik,
    required this.password,
    required this.noHp,
  });

  @override
  List<Object?> get props => [nik, password, noHp];
}

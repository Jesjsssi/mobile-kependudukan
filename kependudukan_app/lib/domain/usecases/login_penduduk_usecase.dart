import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/domain/entities/penduduk.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';

class LoginPendudukUseCase {
  final AuthRepository repository;

  LoginPendudukUseCase(this.repository);

  Future<Either<Failure, Penduduk>> call(LoginPendudukParams params) async {
    return await repository.loginPenduduk(params.nik, params.password);
  }
}

class LoginPendudukParams extends Equatable {
  final String nik;
  final String password;

  const LoginPendudukParams({required this.nik, required this.password});

  @override
  List<Object?> get props => [nik, password];
}

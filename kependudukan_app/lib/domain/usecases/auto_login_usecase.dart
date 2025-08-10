import 'package:dartz/dartz.dart';
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/domain/entities/penduduk.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';

class AutoLoginUseCase {
  final AuthRepository repository;

  AutoLoginUseCase(this.repository);

  Future<Either<Failure, Penduduk>> call() async {
    return await repository.autoLogin();
  }
}

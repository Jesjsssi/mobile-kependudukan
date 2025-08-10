import 'package:dartz/dartz.dart';
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';
import 'package:flutter_kependudukan/presentation/blocs/auth/auth_bloc.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.logout();
  }
}

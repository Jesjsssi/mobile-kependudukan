import 'package:dartz/dartz.dart';
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/domain/entities/penduduk.dart';


abstract class AuthRepository {
  
  Future<Either<Failure, Penduduk>> loginPenduduk(String nik, String password);

  Future<Either<Failure, bool>> registerPenduduk(
    String nik,
    String password,
    String noHp,
  );

  Future<Either<Failure, bool>> checkNikExists(String nik);

  Future<Either<Failure, void>> logout();
  
  Future<Either<Failure, Penduduk>> autoLogin();

  Future<Either<Failure, Map<String, dynamic>>> getPendudukDetail(String nik);
}

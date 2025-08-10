import 'package:dartz/dartz.dart';
import 'package:flutter_kependudukan/core/constants/app_constants.dart';
import 'package:flutter_kependudukan/core/errors/exception.dart' as exc;
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/core/network/network_info.dart';
import 'package:flutter_kependudukan/data/datasources/asset_api_service.dart';
import 'package:flutter_kependudukan/data/datasources/auth_api_service.dart';
import 'package:flutter_kependudukan/data/datasources/auth_local_storage.dart';
import 'package:flutter_kependudukan/data/datasources/penduduk_api_service.dart';
import 'package:flutter_kependudukan/domain/entities/penduduk.dart';
import 'package:flutter_kependudukan/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';

class AuthRepositoryImpl implements AuthRepository {
  final PendudukApiService pendudukApiService;
  final AuthApiService authApiService;
  final NetworkInfo networkInfo;
  final AuthLocalStorage authLocalStorage;

  AuthRepositoryImpl({
    required this.pendudukApiService,
    required this.authApiService,
    required this.networkInfo,
    required this.authLocalStorage,
  });

  @override
  Future<Either<Failure, bool>> checkNikExists(String nik) async {
    if (await networkInfo.isConnected) {
      try {
        return const Right(false);
      } on exc.ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(
            ServerFailure(message: 'Error checking NIK: ${e.toString()}'));
      }
    } else {
      return Left(ServerFailure(message: AppConstants.errorNetworkMessage));
    }
  }

  @override
  Future<Either<Failure, Penduduk>> loginPenduduk(
      String nik, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final penduduk = await authApiService.login(nik, password);

        await authLocalStorage.saveUserCredentials(
          nik: penduduk.nik,
          password: password,
          noHp: penduduk.noHp,
          name: penduduk.name,
          accessToken: penduduk.accessToken,
          tokenType: penduduk.tokenType,
        );

        GetIt.instance<AssetApiService>().clearCache();

        return Right(penduduk);
      } on exc.AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on exc.ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: AppConstants.errorNetworkMessage));
    }
  }

  @override
  Future<Either<Failure, bool>> registerPenduduk(
    String nik,
    String password,
    String noHp,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final penduduk = await authApiService.register(nik, password, noHp);

        await authLocalStorage.saveUserCredentials(
          nik: nik,
          password: password,
          noHp: noHp,
          accessToken: penduduk.accessToken,
          tokenType: penduduk.tokenType,
        );

        return const Right(true);
      } on exc.ValidationException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on exc.AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on exc.ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(
            ServerFailure(message: 'Registration error: ${e.toString()}'));
      }
    } else {
      return Left(ServerFailure(message: AppConstants.errorNetworkMessage));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await authLocalStorage.clearUserCredentials();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Penduduk>> autoLogin() async {
    try {
      final hasCredentials = await authLocalStorage.hasUserCredentials();
      if (!hasCredentials) {
        return Left(AuthFailure(message: 'No stored credentials'));
      }

      final penduduk = await authLocalStorage.getStoredPenduduk();
      if (penduduk == null) {
        return Left(AuthFailure(message: 'Failed to get stored user data'));
      }

      if (penduduk.accessToken != null && penduduk.accessToken!.isNotEmpty) {
        return Right(penduduk);
      }

      final credentials = await authLocalStorage.getUserCredentials();
      if (credentials == null) {
        await authLocalStorage.clearUserCredentials();
        return Left(AuthFailure(message: 'Stored credentials are invalid'));
      }

      if (await networkInfo.isConnected) {
        try {
          return await loginPenduduk(
              credentials['nik'], credentials['password']);
        } catch (e) {
          return Left(
              AuthFailure(message: 'Failed to login with stored credentials'));
        }
      }

      return Left(ServerFailure(message: AppConstants.errorNetworkMessage));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPendudukDetail(
      String nik) async {
    if (await networkInfo.isConnected) {
      try {
        final detail = await pendudukApiService.getPendudukDetailByNik(nik);
        return Right(detail);
      } on exc.ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }
}

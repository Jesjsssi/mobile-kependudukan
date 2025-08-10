import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_kependudukan/core/errors/failures.dart';
import 'package:flutter_kependudukan/domain/usecases/auto_login_usecase.dart';
import 'package:flutter_kependudukan/domain/usecases/check_nik_exists_usecase.dart';
import 'package:flutter_kependudukan/domain/usecases/login_penduduk_usecase.dart';
import 'package:flutter_kependudukan/domain/usecases/logout_usecase.dart';
import 'package:flutter_kependudukan/domain/usecases/register_penduduk_usecase.dart';
import 'package:flutter_kependudukan/presentation/blocs/auth/auth_event.dart';
import 'package:flutter_kependudukan/presentation/blocs/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginPendudukUseCase loginPendudukUseCase;
  final RegisterPendudukUseCase registerPendudukUseCase;
  final CheckNikExistsUseCase checkNikExistsUseCase;
  final LogoutUseCase logoutUseCase;
  final AutoLoginUseCase autoLoginUseCase;

  AuthBloc({
    required this.loginPendudukUseCase,
    required this.registerPendudukUseCase,
    required this.checkNikExistsUseCase,
    required this.logoutUseCase,
    required this.autoLoginUseCase,
  }) : super(AuthInitial()) {
    on<LoginPendudukEvent>(_onLoginPenduduk);
    on<RegisterPendudukEvent>(_onRegisterPenduduk);
    on<CheckNikEvent>(_onCheckNik);
    on<LogoutEvent>(_onLogout);
    on<AutoLoginEvent>(_onAutoLogin);
  }

  Future<void> _onLoginPenduduk(
    LoginPendudukEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    await logoutUseCase(NoParams());

    final result = await loginPendudukUseCase(
      LoginPendudukParams(nik: event.nik, password: event.password),
    );

    result.fold(
      (failure) => emit(_mapFailureToAuthError(failure)),
      (penduduk) => emit(PendudukAuthenticated(penduduk: penduduk)),
    );
  }



  Future<void> _onRegisterPenduduk(
    RegisterPendudukEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Validate password length
    if (event.password.length < 6) {
      emit(const AuthError(message: 'Password minimal 6 karakter'));
      return;
    }

    // Validate passwords match
    if (event.password != event.confirmPassword) {
      emit(const AuthError(message: 'Konfirmasi password tidak cocok'));
      return;
    }

    // Validate NIK length
    if (event.nik.length != 16) {
      emit(const AuthError(message: 'NIK harus 16 digit'));
      return;
    }

    // Validate phone number
    if (event.noHp.length < 10 || !event.noHp.startsWith('08')) {
      emit(const AuthError(message: 'Nomor HP tidak valid'));
      return;
    }

    final result = await registerPendudukUseCase(
      RegisterPendudukParams(
        nik: event.nik,
        password: event.password,
        noHp: event.noHp,
      ),
    );

    emit(
      result.fold(
        (failure) => _mapFailureToAuthError(failure),
        (_) => RegisterSuccess(),
      ),
    );
  }

  Future<void> _onCheckNik(CheckNikEvent event, Emitter<AuthState> emit) async {
    emit(NikCheckLoading());

    try {
      final result = await checkNikExistsUseCase(
        CheckNikParams(nik: event.nik),
      );

      emit(
        result.fold(
          (failure) => _mapFailureToAuthError(failure),
          (exists) => NikExists(exists: exists),
        ),
      );
    } catch (e) {
      emit(AuthError(message: 'Error checking NIK: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await logoutUseCase(NoParams());

    emit(
      result.fold(
        (failure) => _mapFailureToAuthError(failure),
        (_) => Unauthenticated(),
      ),
    );
  }

  Future<void> _onAutoLogin(
    AutoLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await autoLoginUseCase();

    emit(
      result.fold(
        (_) => Unauthenticated(),
        (penduduk) => PendudukAuthenticated(penduduk: penduduk),
      ),
    );
  }

  // Helper method to map failures to appropriate AuthError states
  AuthError _mapFailureToAuthError(Failure failure) {
    return AuthError(message: failure.message);
  }
}

class NoParams {}

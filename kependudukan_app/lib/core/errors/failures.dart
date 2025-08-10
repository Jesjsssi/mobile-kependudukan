import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final List properties;

  String get message;

  const Failure([this.properties = const <dynamic>[]]);

  @override
  List<Object> get props => [properties];
}

class ServerFailure extends Failure {
  final String message;

  ServerFailure({required this.message}) : super([message]);

  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  CacheFailure({required this.message}) : super([message]);

  @override
  List<Object> get props => [message];
}

class AuthFailure extends Failure {
  final String message;

  AuthFailure({required this.message}) : super([message]);

  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  final String message;

  DatabaseFailure({required this.message}) : super([message]);

  @override
  List<Object> get props => [message];
}

class AuthenticationFailure extends Failure {
  final String message;

  AuthenticationFailure({required this.message}) : super([message]);

  @override
  List<Object> get props => [message];
}

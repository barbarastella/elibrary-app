import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequestedEvent extends AuthEvent {
  const AuthCheckRequestedEvent(); // verifica se há token ativo
}

class AuthGoogleLoginRequestedEvent extends AuthEvent {
  const AuthGoogleLoginRequestedEvent();
}

class AuthLogoutRequestedEvent extends AuthEvent {
  const AuthLogoutRequestedEvent();
}


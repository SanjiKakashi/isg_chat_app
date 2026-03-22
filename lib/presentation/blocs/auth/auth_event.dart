part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}

class AuthSignInWithGoogle extends AuthEvent {
  const AuthSignInWithGoogle();
}

class AuthSignInWithApple extends AuthEvent {
  const AuthSignInWithApple();
}

class AuthSignInAnonymously extends AuthEvent {
  const AuthSignInAnonymously();
}

class AuthLinkWithGoogle extends AuthEvent {
  const AuthLinkWithGoogle();
}

class AuthLinkWithApple extends AuthEvent {
  const AuthLinkWithApple();
}

class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}


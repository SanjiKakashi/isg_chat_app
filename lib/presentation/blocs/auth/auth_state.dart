part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Before session check runs.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Sign-in or session-check in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Account-linking operation in progress.
class AuthLinkInProgress extends AuthState {
  const AuthLinkInProgress(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user.uid];
}

/// Authenticated — carries the signed-in user.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user.uid];
}

/// No authenticated session.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Sign-in failed.
class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Account linked successfully — transient before [AuthAuthenticated].
class AuthLinkSuccess extends AuthState {
  const AuthLinkSuccess(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user.uid];
}

/// Account linking failed — transient before reverting to [AuthAuthenticated].
class AuthLinkFailure extends AuthState {
  const AuthLinkFailure(this.message, this.user);

  final String message;
  final UserProfile user;

  @override
  List<Object?> get props => [message, user.uid];
}


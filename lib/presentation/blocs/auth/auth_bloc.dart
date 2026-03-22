import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/repositories/auth_repository_impl.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/usecases/get_current_user_usecase.dart';
import 'package:isg_chat_app/domain/usecases/link_with_apple_usecase.dart';
import 'package:isg_chat_app/domain/usecases/link_with_google_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_with_google_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives authentication flow; navigation is handled by UI BlocListeners.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SignInAnonymouslyUseCase signInAnonymouslyUseCase,
    required LinkWithGoogleUseCase linkWithGoogleUseCase,
    required LinkWithAppleUseCase linkWithAppleUseCase,
    required AuthRepositoryImpl authRepository,
  })  : _signInWithGoogle = signInWithGoogleUseCase,
        _signInWithApple = signInWithAppleUseCase,
        _getCurrentUser = getCurrentUserUseCase,
        _signInAnonymously = signInAnonymouslyUseCase,
        _linkWithGoogle = linkWithGoogleUseCase,
        _linkWithApple = linkWithAppleUseCase,
        _authRepo = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithApple>(_onSignInWithApple);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthLinkWithGoogle>(_onLinkWithGoogle);
    on<AuthLinkWithApple>(_onLinkWithApple);
    on<AuthSignOut>(_onSignOut);
  }

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;
  final GetCurrentUserUseCase _getCurrentUser;
  final SignInAnonymouslyUseCase _signInAnonymously;
  final LinkWithGoogleUseCase _linkWithGoogle;
  final LinkWithAppleUseCase _linkWithApple;
  final AuthRepositoryImpl _authRepo;

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _getCurrentUser.execute();
      if (user != null) {
        AppLogger.instance.i('Session found: ${user.uid}');
        emit(AuthAuthenticated(user));
      } else {
        AppLogger.instance.i('No session found');
        emit(const AuthUnauthenticated());
      }
    } on Exception catch (e) {
      AppLogger.instance.e('Session check error', error: e);
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async =>
      _performSignIn(_signInWithGoogle.execute, emit);

  Future<void> _onSignInWithApple(
    AuthSignInWithApple event,
    Emitter<AuthState> emit,
  ) async =>
      _performSignIn(_signInWithApple.execute, emit);

  Future<void> _onSignInAnonymously(
    AuthSignInAnonymously event,
    Emitter<AuthState> emit,
  ) async =>
      _performSignIn(_signInAnonymously.execute, emit);

  Future<void> _onLinkWithGoogle(
    AuthLinkWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    final user = _currentUser();
    if (user == null) return;
    await _performLink(
      () => _linkWithGoogle.execute(guestUid: user.uid),
      user,
      emit,
    );
  }

  Future<void> _onLinkWithApple(
    AuthLinkWithApple event,
    Emitter<AuthState> emit,
  ) async {
    final user = _currentUser();
    if (user == null) return;
    await _performLink(
      () => _linkWithApple.execute(guestUid: user.uid),
      user,
      emit,
    );
  }

  Future<void> _onSignOut(
    AuthSignOut event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepo.signOut();
    } on Exception catch (e) {
      AppLogger.instance.e('Sign out failed', error: e);
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _performSignIn(
    Future<({UserProfile? profile, Failure? failure})> Function() signIn,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await signIn();

      if (result.failure is CancelledFailure) {
        emit(const AuthUnauthenticated());
        return;
      }
      if (result.profile == null) {
        emit(AuthError(result.failure?.message ?? 'Sign-in failed.'));
        return;
      }
      if (result.failure is FirestoreFailure) {
        AppLogger.instance.w('Firestore save failed; proceeding.');
      }

      AppLogger.instance.i('Sign-in success: ${result.profile!.uid}');
      emit(AuthAuthenticated(result.profile!));
    } on Exception catch (e) {
      AppLogger.instance.e('_performSignIn error', error: e);
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _performLink(
    Future<({UserProfile? profile, Failure? failure})> Function() link,
    UserProfile currentUser,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLinkInProgress(currentUser));
    try {
      final result = await link();

      if (result.failure is CancelledFailure) {
        emit(AuthAuthenticated(currentUser));
        return;
      }
      if (result.profile == null) {
        emit(AuthLinkFailure(
          result.failure?.message ?? 'Linking failed.',
          currentUser,
        ));
        emit(AuthAuthenticated(currentUser));
        return;
      }

      emit(AuthLinkSuccess(result.profile!));
      emit(AuthAuthenticated(result.profile!));
    } on Exception catch (e) {
      AppLogger.instance.e('_performLink error', error: e);
      emit(AuthLinkFailure('Something went wrong. Please try again.', currentUser));
      emit(AuthAuthenticated(currentUser));
    }
  }

  /// Returns the current user from whichever auth state carries one.
  UserProfile? _currentUser() {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    if (s is AuthLinkInProgress) return s.user;
    if (s is AuthLinkFailure) return s.user;
    return null;
  }
}


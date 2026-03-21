import 'dart:async';

import 'package:get/get.dart';
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
import 'package:isg_chat_app/routes/app_routes.dart';

/// Manages auth UI state and drives navigation after sign-in/sign-out.
class AuthController extends GetxController {
  AuthController({
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SignInAnonymouslyUseCase signInAnonymouslyUseCase,
    required LinkWithGoogleUseCase linkWithGoogleUseCase,
    required LinkWithAppleUseCase linkWithAppleUseCase,
  })  : _signInWithGoogle = signInWithGoogleUseCase,
        _signInWithApple = signInWithAppleUseCase,
        _getCurrentUser = getCurrentUserUseCase,
        _signInAnonymously = signInAnonymouslyUseCase,
        _linkWithGoogle = linkWithGoogleUseCase,
        _linkWithApple = linkWithAppleUseCase;

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;
  final GetCurrentUserUseCase _getCurrentUser;
  final SignInAnonymouslyUseCase _signInAnonymously;
  final LinkWithGoogleUseCase _linkWithGoogle;
  final LinkWithAppleUseCase _linkWithApple;

  final RxBool isLoading = false.obs;
  final RxBool isLinking = false.obs;
  final Rxn<UserProfile> currentUser = Rxn<UserProfile>();

  /// Ensures [_checkSession] runs only once per app lifecycle.
  bool _sessionChecked = false;

  @override
  Future<void> onReady() async {
    super.onReady();
    if (_sessionChecked) return;
    _sessionChecked = true;
    await _checkSession();
  }

  Future<void> signInWithGoogle() async => _performSignIn(() => _signInWithGoogle.execute());

  Future<void> signInWithApple() async => _performSignIn(() => _signInWithApple.execute());

  Future<void> signInAnonymously() async => _performSignIn(() => _signInAnonymously.execute());

  Future<void> linkWithGoogle() async {
    final guestUid = currentUser.value!.uid;
    await _performLink(() => _linkWithGoogle.execute(guestUid: guestUid));
  }

  Future<void> linkWithApple() async {
    final guestUid = currentUser.value!.uid;
    await _performLink(() => _linkWithApple.execute(guestUid: guestUid));
  }

  /// Signs out and returns to the login screen.
  Future<void> signOut() async {
    try {
      await Get.find<AuthRepositoryImpl>().signOut();
    } on Exception catch (e) {
      AppLogger.instance.e('signOut failed', error: e);
    } finally {
      currentUser.value = null;
      unawaited(Get.offAllNamed(AppRoutes.login));
    }
  }

  Future<void> _checkSession() async {
    isLoading.value = true;
    try {
      final user = await _getCurrentUser.execute();
      if (user != null) {
        currentUser.value = user;
        AppLogger.instance.i('Session found — routing to chat.');
        unawaited(Get.offAllNamed(AppRoutes.chat));
      } else {
        AppLogger.instance.i('No session — routing to login.');
        unawaited(Get.offAllNamed(AppRoutes.login));
      }
    } on Exception catch (e) {
      AppLogger.instance.e('Session check error', error: e);
      unawaited(Get.offAllNamed(AppRoutes.login));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _performSignIn(
    Future<({UserProfile? profile, Failure? failure})> Function() signIn,
  ) async {
    isLoading.value = true;
    try {
      final result = await signIn();

      if (result.failure is CancelledFailure) return;

      if (result.profile == null) {
        _showError(result.failure?.message ?? 'Sign-in failed.');
        return;
      }

      if (result.failure is FirestoreFailure) {
        AppLogger.instance.w('Firestore save failed; proceeding to chat.');
      }

      currentUser.value = result.profile;
      AppLogger.instance.i('Sign-in success: ${result.profile!.uid}');
      unawaited(Get.offAllNamed(AppRoutes.chat));
    } on Exception catch (e) {
      AppLogger.instance.e('_performSignIn error', error: e);
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _performLink(
    Future<({UserProfile? profile, Failure? failure})> Function() link,
  ) async {
    isLinking.value = true;
    try {
      final result = await link();

      if (result.failure is CancelledFailure) return;

      if (result.profile == null) {
        _showError(result.failure?.message ?? 'Linking failed.');
        return;
      }

      currentUser.value = result.profile;
      Get.back<void>();
      Get.snackbar(
        'Account linked',
        'Your chat history has been transferred.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } on Exception catch (e) {
      AppLogger.instance.e('_performLink error', error: e);
      _showError('Something went wrong. Please try again.');
    } finally {
      isLinking.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Sign-in error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}

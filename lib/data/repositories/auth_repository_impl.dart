import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/sources/remote/guest_migration_service.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/auth_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required GuestMigrationService migrationService,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _migrationService = migrationService;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final GuestMigrationService _migrationService;

  @override
  Future<({UserProfile? profile, Failure? failure})> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return (profile: null, failure: const CancelledFailure());
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final profile = _profileFromCredential(userCredential, AppConstants.providerGoogle);

      AppLogger.instance.i('Google sign-in success: ${profile.uid}');
      return (profile: profile, failure: null);
    } on FirebaseAuthException catch (e) {
      AppLogger.instance.e('Google sign-in error', error: e);
      return (profile: null, failure: AuthFailure(_friendlyAuthMessage(e.code)));
    } on Exception catch (e) {
      AppLogger.instance.e('Google sign-in unexpected error', error: e);
      return (profile: null, failure: const AuthFailure('Something went wrong. Please try again.'));
    }
  }

  @override
  Future<({UserProfile? profile, Failure? failure})> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      final appleDisplayName = [appleCredential.givenName, appleCredential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      final firebaseUser = userCredential.user!;
      if (appleDisplayName.isNotEmpty &&
          (firebaseUser.displayName == null || firebaseUser.displayName!.isEmpty)) {
        await firebaseUser.updateDisplayName(appleDisplayName);
        await firebaseUser.reload();
      }

      final profile = _profileFromCredential(
        userCredential,
        AppConstants.providerApple,
        overrideDisplayName: appleDisplayName.isNotEmpty ? appleDisplayName : null,
      );

      AppLogger.instance.i('Apple sign-in success: ${profile.uid}');
      return (profile: profile, failure: null);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return (profile: null, failure: const CancelledFailure());
      }
      AppLogger.instance.e('Apple sign-in error', error: e);
      return (profile: null, failure: const AuthFailure('Apple Sign-In failed. Please try again.'));
    } on FirebaseAuthException catch (e) {
      AppLogger.instance.e('Apple sign-in Firebase error', error: e);
      return (profile: null, failure: AuthFailure(_friendlyAuthMessage(e.code)));
    } on Exception catch (e) {
      AppLogger.instance.e('Apple sign-in unexpected error', error: e);
      return (profile: null, failure: const AuthFailure('Something went wrong. Please try again.'));
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    try {
      await user.reload();
      final refreshed = _firebaseAuth.currentUser;
      if (refreshed == null) return null;
      return UserProfile(
        uid: refreshed.uid,
        displayName: refreshed.displayName,
        email: refreshed.email,
        photoUrl: refreshed.photoURL,
        provider: _extractProvider(refreshed),
        createdAt: refreshed.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: refreshed.metadata.lastSignInTime ?? DateTime.now(),
      );
    } on Exception catch (e) {
      AppLogger.instance.w('Session check failed', error: e);
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  @override
  Future<({UserProfile? profile, Failure? failure})> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final profile = _profileFromCredential(
        userCredential,
        AppConstants.providerAnonymous,
      );
      AppLogger.instance.i('Anonymous sign-in: ${profile.uid}');
      return (profile: profile, failure: null);
    } on FirebaseAuthException catch (e) {
      AppLogger.instance.e('Anonymous sign-in error', error: e);
      return (profile: null, failure: AuthFailure(_friendlyAuthMessage(e.code)));
    } on Exception catch (e) {
      AppLogger.instance.e('Anonymous sign-in unexpected error', error: e);
      return (
        profile: null,
        failure: const AuthFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<({UserProfile? profile, Failure? failure})> linkWithGoogle({
    required String guestUid,
  }) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return (profile: null, failure: const CancelledFailure());
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final guestData = await _migrationService.fetchGuestData(guestUid);

      UserCredential userCredential;
      try {
        userCredential =
            await _firebaseAuth.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          AppLogger.instance.i('Google credential in use — signing in to merge');
          userCredential =
              await _firebaseAuth.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }

      final newUid = userCredential.user!.uid;
      final profile =
          _profileFromCredential(userCredential, AppConstants.providerGoogle);

      await _migrationService.migrate(
        guestUid: guestUid,
        newUid: newUid,
        guestData: guestData,
      );

      AppLogger.instance.i('Google link success: $newUid');
      return (profile: profile, failure: null);
    } on FirebaseAuthException catch (e) {
      AppLogger.instance.e('Google link error', error: e);
      return (profile: null, failure: LinkFailure(_friendlyAuthMessage(e.code)));
    } on Exception catch (e) {
      AppLogger.instance.e('Google link unexpected error', error: e);
      return (
        profile: null,
        failure: const LinkFailure('Linking failed. Please try again.'),
      );
    }
  }

  @override
  Future<({UserProfile? profile, Failure? failure})> linkWithApple({
    required String guestUid,
  }) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final guestData = await _migrationService.fetchGuestData(guestUid);

      UserCredential userCredential;
      try {
        userCredential =
            await _firebaseAuth.currentUser!.linkWithCredential(oauthCredential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          AppLogger.instance.i('Apple credential in use — signing in to merge');
          userCredential =
              await _firebaseAuth.signInWithCredential(oauthCredential);
        } else {
          rethrow;
        }
      }

      final appleDisplayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      final firebaseUser = userCredential.user!;
      if (appleDisplayName.isNotEmpty &&
          (firebaseUser.displayName == null ||
              firebaseUser.displayName!.isEmpty)) {
        await firebaseUser.updateDisplayName(appleDisplayName);
        await firebaseUser.reload();
      }

      final profile = _profileFromCredential(
        userCredential,
        AppConstants.providerApple,
        overrideDisplayName:
            appleDisplayName.isNotEmpty ? appleDisplayName : null,
      );

      final newUid = userCredential.user!.uid;
      await _migrationService.migrate(
        guestUid: guestUid,
        newUid: newUid,
        guestData: guestData,
      );

      AppLogger.instance.i('Apple link success: $newUid');
      return (profile: profile, failure: null);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return (profile: null, failure: const CancelledFailure());
      }
      AppLogger.instance.e('Apple link error', error: e);
      return (
        profile: null,
        failure: const LinkFailure('Apple Sign-In failed. Please try again.'),
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.instance.e('Apple link Firebase error', error: e);
      return (profile: null, failure: LinkFailure(_friendlyAuthMessage(e.code)));
    } on Exception catch (e) {
      AppLogger.instance.e('Apple link unexpected error', error: e);
      return (
        profile: null,
        failure: const LinkFailure('Linking failed. Please try again.'),
      );
    }
  }

  UserProfile _profileFromCredential(
    UserCredential credential,
    String provider, {
    String? overrideDisplayName,
  }) {
    final user = credential.user!;
    final now = DateTime.now();
    return UserProfile(
      uid: user.uid,
      displayName: overrideDisplayName ?? user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      provider: provider,
      createdAt: user.metadata.creationTime ?? now,
      lastLoginAt: now,
    );
  }

  String _extractProvider(User user) {
    if (user.providerData.isEmpty) return AppConstants.providerGoogle;
    final providerId = user.providerData.first.providerId;
    return providerId.contains('apple') ? AppConstants.providerApple : AppConstants.providerGoogle;
  }

  String _friendlyAuthMessage(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'admin-restricted-operation':
        return 'Guest sign-in is not enabled for this app. Please sign in with Google or Apple.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  /// Generates a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = List<int>.generate(
      length,
      (_) => charset.codeUnitAt(DateTime.now().microsecondsSinceEpoch % charset.length),
    );
    return String.fromCharCodes(random);
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isg_chat_app/data/repositories/auth_repository_impl.dart';
import 'package:isg_chat_app/data/repositories/user_repository_impl.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';
import 'package:isg_chat_app/data/sources/remote/guest_migration_service.dart';
import 'package:isg_chat_app/data/sources/remote/user_remote_source.dart';
import 'package:isg_chat_app/domain/usecases/get_current_user_usecase.dart';
import 'package:isg_chat_app/domain/usecases/link_with_apple_usecase.dart';
import 'package:isg_chat_app/domain/usecases/link_with_google_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:isg_chat_app/presentation/controllers/auth_controller.dart';

/// App-level binding — registered once at startup in [main.dart].
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<FirestoreService>(
      FirestoreService.instance,
      permanent: true,
    );

    // Data sources
    Get.put<UserRemoteSource>(
      UserRemoteSource(firestoreService: Get.find<FirestoreService>()),
      permanent: true,
    );

    Get.put<GuestMigrationService>(
      GuestMigrationService(firestoreService: Get.find<FirestoreService>()),
      permanent: true,
    );

    // Repositories
    Get.put<AuthRepositoryImpl>(
      AuthRepositoryImpl(
        firebaseAuth: FirebaseAuth.instance,
        googleSignIn: GoogleSignIn(),
        migrationService: Get.find<GuestMigrationService>(),
      ),
      permanent: true,
    );

    Get.put<UserRepositoryImpl>(
      UserRepositoryImpl(remoteSource: Get.find<UserRemoteSource>()),
      permanent: true,
    );

    // Use-cases
    Get.put<SignInWithGoogleUseCase>(
      SignInWithGoogleUseCase(
        authRepository: Get.find<AuthRepositoryImpl>(),
        userRepository: Get.find<UserRepositoryImpl>(),
      ),
      permanent: true,
    );

    Get.put<SignInWithAppleUseCase>(
      SignInWithAppleUseCase(
        authRepository: Get.find<AuthRepositoryImpl>(),
        userRepository: Get.find<UserRepositoryImpl>(),
      ),
      permanent: true,
    );

    Get.put<SignInAnonymouslyUseCase>(
      SignInAnonymouslyUseCase(
        authRepository: Get.find<AuthRepositoryImpl>(),
        userRepository: Get.find<UserRepositoryImpl>(),
      ),
      permanent: true,
    );

    Get.put<LinkWithGoogleUseCase>(
      LinkWithGoogleUseCase(
        authRepository: Get.find<AuthRepositoryImpl>(),
        userRepository: Get.find<UserRepositoryImpl>(),
      ),
      permanent: true,
    );

    Get.put<LinkWithAppleUseCase>(
      LinkWithAppleUseCase(
        authRepository: Get.find<AuthRepositoryImpl>(),
        userRepository: Get.find<UserRepositoryImpl>(),
      ),
      permanent: true,
    );

    Get.put<GetCurrentUserUseCase>(
      GetCurrentUserUseCase(authRepository: Get.find<AuthRepositoryImpl>()),
      permanent: true,
    );

    Get.put<AuthController>(
      AuthController(
        signInWithGoogleUseCase: Get.find<SignInWithGoogleUseCase>(),
        signInWithAppleUseCase: Get.find<SignInWithAppleUseCase>(),
        getCurrentUserUseCase: Get.find<GetCurrentUserUseCase>(),
        signInAnonymouslyUseCase: Get.find<SignInAnonymouslyUseCase>(),
        linkWithGoogleUseCase: Get.find<LinkWithGoogleUseCase>(),
        linkWithAppleUseCase: Get.find<LinkWithAppleUseCase>(),
      ),
      permanent: true,
    );
  }
}

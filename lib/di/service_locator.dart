import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isg_chat_app/data/repositories/ai_repository_impl.dart';
import 'package:isg_chat_app/data/repositories/auth_repository_impl.dart';
import 'package:isg_chat_app/data/repositories/conversation_repository_impl.dart';
import 'package:isg_chat_app/data/repositories/user_repository_impl.dart';
import 'package:isg_chat_app/data/sources/remote/ai_config_service.dart';
import 'package:isg_chat_app/data/sources/remote/ai_remote_source.dart';
import 'package:isg_chat_app/data/sources/remote/conversation_remote_source.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';
import 'package:isg_chat_app/data/sources/remote/guest_migration_service.dart';
import 'package:isg_chat_app/data/sources/remote/user_remote_source.dart';
import 'package:isg_chat_app/domain/usecases/get_current_user_usecase.dart';
import 'package:isg_chat_app/domain/usecases/link_with_apple_usecase.dart';
import 'package:isg_chat_app/domain/usecases/link_with_google_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:isg_chat_app/domain/usecases/sign_in_with_google_usecase.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Registers all dependencies. Call once before [runApp].
Future<void> setupServiceLocator() async {
  sl.registerSingleton<FirestoreService>(FirestoreService.instance);

  sl.registerLazySingleton<UserRemoteSource>(
    () => UserRemoteSource(firestoreService: sl()),
  );
  sl.registerLazySingleton<GuestMigrationService>(
    () => GuestMigrationService(firestoreService: sl()),
  );
  sl.registerLazySingleton<ConversationRemoteSource>(
    () => ConversationRemoteSource(firestoreService: sl()),
  );
  sl.registerLazySingleton<AiConfigService>(
    () => AiConfigService(firestoreService: sl()),
  );
  sl.registerLazySingleton<AiRemoteSource>(
    () => AiRemoteSource(aiConfigService: sl()),
  );

  sl.registerLazySingleton<AuthRepositoryImpl>(
    () => AuthRepositoryImpl(
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(),
      migrationService: sl(),
    ),
  );
  sl.registerLazySingleton<UserRepositoryImpl>(
    () => UserRepositoryImpl(remoteSource: sl()),
  );
  sl.registerLazySingleton<ConversationRepositoryImpl>(
    () => ConversationRepositoryImpl(remoteSource: sl()),
  );
  sl.registerLazySingleton<AiRepositoryImpl>(
    () => AiRepositoryImpl(remoteSource: sl()),
  );

  sl.registerLazySingleton<SignInWithGoogleUseCase>(
    () => SignInWithGoogleUseCase(
      authRepository: sl<AuthRepositoryImpl>(),
      userRepository: sl<UserRepositoryImpl>(),
    ),
  );
  sl.registerLazySingleton<SignInWithAppleUseCase>(
    () => SignInWithAppleUseCase(
      authRepository: sl<AuthRepositoryImpl>(),
      userRepository: sl<UserRepositoryImpl>(),
    ),
  );
  sl.registerLazySingleton<SignInAnonymouslyUseCase>(
    () => SignInAnonymouslyUseCase(
      authRepository: sl<AuthRepositoryImpl>(),
      userRepository: sl<UserRepositoryImpl>(),
    ),
  );
  sl.registerLazySingleton<LinkWithGoogleUseCase>(
    () => LinkWithGoogleUseCase(
      authRepository: sl<AuthRepositoryImpl>(),
      userRepository: sl<UserRepositoryImpl>(),
    ),
  );
  sl.registerLazySingleton<LinkWithAppleUseCase>(
    () => LinkWithAppleUseCase(
      authRepository: sl<AuthRepositoryImpl>(),
      userRepository: sl<UserRepositoryImpl>(),
    ),
  );
  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(authRepository: sl<AuthRepositoryImpl>()),
  );
}

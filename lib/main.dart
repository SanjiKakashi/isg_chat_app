import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/di/service_locator.dart';
import 'package:isg_chat_app/firebase_options.dart';
import 'package:isg_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:isg_chat_app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a chat-focused experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupServiceLocator();

  runApp(const IsgChatApp());
}

class IsgChatApp extends StatelessWidget {
  const IsgChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        signInWithGoogleUseCase: sl(),
        signInWithAppleUseCase: sl(),
        getCurrentUserUseCase: sl(),
        signInAnonymouslyUseCase: sl(),
        linkWithGoogleUseCase: sl(),
        linkWithAppleUseCase: sl(),
        authRepository: sl(),
      )..add(const AuthCheckSession()),
      child: MaterialApp(
        title: 'ISG Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

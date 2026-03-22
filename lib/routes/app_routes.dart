import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/data/repositories/ai_repository_impl.dart';
import 'package:isg_chat_app/data/repositories/conversation_repository_impl.dart';
import 'package:isg_chat_app/di/service_locator.dart';
import 'package:isg_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:isg_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:isg_chat_app/presentation/pages/chat_page.dart';
import 'package:isg_chat_app/presentation/pages/login_page.dart';
import 'package:isg_chat_app/presentation/pages/splash_page.dart';

/// Named route constants.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String chat = '/chat';
}

/// Generates routes for the app's [MaterialApp].
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashPage());

      case AppRoutes.login:
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: _fade,
        );

      case AppRoutes.chat:
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, _, __) {
            final user =
                (context.read<AuthBloc>().state as AuthAuthenticated).user;
            return BlocProvider<ChatBloc>(
              create: (_) => ChatBloc(
                conversationRepository: sl<ConversationRepositoryImpl>(),
                aiRepository: sl<AiRepositoryImpl>(),
                user: user,
              )..add(const ChatInitialize()),
              child: const ChatPage(),
            );
          },
          transitionsBuilder: _slide,
        );

      default:
        return MaterialPageRoute<void>(builder: (_) => const SplashPage());
    }
  }

  static Widget _fade(BuildContext _, Animation<double> a, Animation<double> __, Widget child) =>
      FadeTransition(opacity: a, child: child);

  static Widget _slide(BuildContext _, Animation<double> a, Animation<double> __, Widget child) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(a),
        child: child,
      );

  static void pushReplaceAll(BuildContext context, String routeName) =>
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
}

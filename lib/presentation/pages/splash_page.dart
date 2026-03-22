import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:isg_chat_app/routes/app_routes.dart';

/// Branded splash shown while [AuthBloc] resolves the session.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          AppRouter.pushReplaceAll(context, AppRoutes.chat);
        } else if (state is AuthUnauthenticated) {
          AppRouter.pushReplaceAll(context, AppRoutes.login);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AppLogoMark(),
                SizedBox(height: 40),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline logo mark — shown on both Splash and Login screens.
class _AppLogoMark extends StatelessWidget {
  const _AppLogoMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing purple circle icon
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.accent],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ISG Chat',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Powered by ChatGPT',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}


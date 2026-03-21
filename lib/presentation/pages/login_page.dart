import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/presentation/controllers/auth_controller.dart';
import 'package:isg_chat_app/presentation/widgets/sign_in_button.dart';

/// Premium Login screen (FR-001, FR-002, FR-011).
///
/// Displays:
/// - Full-bleed dark gradient background
/// - Centred app branding (logo + tagline)
/// - "Continue with Google" button (always shown)
/// - "Sign in with Apple" button (iOS only — FR-002)
/// - No other inputs or navigation elements
///
/// All taps delegate to [AuthController]; zero Firebase references here.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final bool isIos = Platform.isIOS;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // ── Branding ──────────────────────────────────────────────
                _BrandingSection(),
                const Spacer(flex: 2),
                // ── Feature bullets ───────────────────────────────────────
                _FeatureHighlights(),
                const Spacer(flex: 3),
                // ── Sign-in buttons ───────────────────────────────────────
                _SignInSection(controller: controller, isIos: isIos),
                const SizedBox(height: 12),
                // ── Legal footer ──────────────────────────────────────────
                _LegalFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────

class _BrandingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo mark with glow
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.accent],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.45),
                blurRadius: 35,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ISG Chat',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your intelligent AI companion',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _FeatureHighlights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_rounded, 'Instant AI responses'),
      (Icons.history_rounded, 'Chat history synced'),
      (Icons.lock_rounded, 'Secure & private'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map(
            (item) => _FeaturePill(icon: item.$1, label: item.$2),
          )
          .toList(),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SignInSection extends StatelessWidget {
  const _SignInSection({
    required this.controller,
    required this.isIos,
  });

  final AuthController controller;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Apple Sign-In (iOS only — FR-002) ────────────────────────
          if (isIos) ...[
            AppleSignInButton(
              onPressed: loading ? null : controller.signInWithApple,
              isLoading: loading,
            ),
            const SizedBox(height: 14),
            const DividerWithLabel(),
            const SizedBox(height: 14),
          ],
          // ── Google Sign-In (always shown) ────────────────────────────
          GoogleSignInButton(
            onPressed: loading ? null : controller.signInWithGoogle,
            isLoading: loading,
          ),
          const SizedBox(height: 20),
          const DividerWithLabel(),
          const SizedBox(height: 16),
          SignInButton(
            label: 'Continue as Guest',
            onPressed: loading ? null : controller.signInAnonymously,
            isLoading: loading,
            icon: const Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: AppTheme.textSecondary,
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.textSecondary,
            borderColor: AppTheme.divider,
          ),
        ],
      );
    });
  }
}

class _LegalFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'By signing in, you agree to our Terms of Service\nand Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        height: 1.6,
      ),
    );
  }
}


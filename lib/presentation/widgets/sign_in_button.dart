import 'package:flutter/material.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';

/// A polished, branded sign-in button used on the Login screen.
///
/// Accepts an optional [icon] widget (SVG logo, etc.) and a [label].
/// Follows the Google/Apple brand guidelines for button appearance (FR-011).
class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black87,
    this.borderColor = Colors.transparent,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: borderColor == Colors.transparent
                  ? Colors.white.withValues(alpha: 0.15)
                  : borderColor,
              width: 1,
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Apple-branded sign-in button: black fill, white text/icon (HIG compliant).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SignInButton(
      label: 'Sign in with Apple',
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.apple, size: 22, color: Colors.black),
    );
  }
}

/// Google-branded sign-in button: white fill with coloured "G" logo.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SignInButton(
      label: 'Continue with Google',
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      icon: _GoogleLogo(),
    );
  }
}

/// Hand-drawn SVG-free Google "G" using [CustomPainter] — no asset required.
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white,
    );

    // Coloured arc segments approximating the Google "G"
    const double startAngle = -0.52; // ~-30°
    const double totalSweep = 5.76; // ~330°

    final segments = [
      (color: const Color(0xFF4285F4), start: startAngle, sweep: 1.57),
      (
        color: const Color(0xFF34A853),
        start: startAngle + 1.57,
        sweep: 1.57,
      ),
      (
        color: const Color(0xFFFBBC05),
        start: startAngle + 3.14,
        sweep: 1.05,
      ),
      (
        color: const Color(0xFFEA4335),
        start: startAngle + 4.19,
        sweep: totalSweep - 4.19 + startAngle,
      ),
    ];

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: r * 0.72,
    );

    for (final seg in segments) {
      strokePaint.color = seg.color;
      canvas.drawArc(rect, seg.start, seg.sweep, false, strokePaint);
    }

    // White horizontal bar for the crossbar of the "G"
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.22
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative divider line with optional centered text.
class DividerWithLabel extends StatelessWidget {
  const DividerWithLabel({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.divider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.divider,
          ),
        ),
      ],
    );
  }
}


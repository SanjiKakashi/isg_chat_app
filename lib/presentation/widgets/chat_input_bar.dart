import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/presentation/controllers/chat_controller.dart';

/// Input bar with send/cancel button that reacts to [ChatController.isGenerating].
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key, required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundCard,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: Obx(
          () {
            final generating = controller.isGenerating.value;
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.inputController,
                    enabled: !generating,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: generating ? 'Generating…' : 'Ask anything…',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionButton(controller: controller, generating: generating),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.controller,
    required this.generating,
  });

  final ChatController controller;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: generating
          ? _CircleButton(
              key: const ValueKey('cancel'),
              icon: Icons.stop_rounded,
              color: Colors.redAccent,
              onTap: controller.cancelGeneration,
              tooltip: 'Cancel',
            )
          : _CircleButton(
              key: const ValueKey('send'),
              icon: Icons.send_rounded,
              color: AppTheme.primary,
              onTap: () => controller.sendMessage(controller.inputController.text),
              tooltip: 'Send',
            ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}


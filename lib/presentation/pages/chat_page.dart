import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/presentation/controllers/chat_controller.dart';
import 'package:isg_chat_app/presentation/widgets/chat_drawer.dart';
import 'package:isg_chat_app/presentation/widgets/chat_input_bar.dart';
import 'package:isg_chat_app/presentation/widgets/message_bubble.dart';

/// Chat screen — streams messages from Firestore and handles send/cancel.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = Get.find<ChatController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      drawer: ChatDrawer(controller: chat),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundCard,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.textSecondary),
            tooltip: 'History',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ISG Chat',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (chat.conversationId.value.isNotEmpty)
              Text(
                '#${chat.conversationId.value.substring(0, 8)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: AppTheme.textSecondary),
            tooltip: 'New conversation',
            onPressed: () {
              Scaffold.of(context).openDrawer();
              chat.startNewConversation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _MessageList(controller: chat)),
          ChatInputBar(controller: chat),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msgs = controller.messages;
      if (msgs.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: AppTheme.textSecondary, size: 48),
              SizedBox(height: 12),
              Text(
                'Start a conversation',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: msgs.length,
        itemBuilder: (_, i) => MessageBubble(message: msgs[i]),
      );
    });
  }
}

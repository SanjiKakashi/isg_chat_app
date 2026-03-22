import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:isg_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:isg_chat_app/presentation/widgets/chat_drawer.dart';
import 'package:isg_chat_app/presentation/widgets/chat_input_bar.dart';
import 'package:isg_chat_app/presentation/widgets/message_bubble.dart';
import 'package:isg_chat_app/routes/app_routes.dart';

/// Chat screen — streams messages via Firestore and handles send/cancel.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              AppRouter.pushReplaceAll(context, AppRoutes.login);
            }
            if (state is AuthLinkSuccess) {
              context.read<ChatBloc>().add(ChatUserChanged(state.user));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account linked! Chat history transferred.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is AuthLinkFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        drawer: const ChatDrawer(),
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
          title: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final convId =
                  state is ChatReady ? state.conversationId : '';
              return Column(
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
                  if (convId.isNotEmpty)
                    Text(
                      '#${convId.substring(0, convId.length.clamp(0, 8))}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_rounded, color: AppTheme.textSecondary),
              tooltip: 'New conversation',
              onPressed: () =>
                  context.read<ChatBloc>().add(const ChatStartNewConversation()),
            ),
          ],
        ),
        body: const Column(
          children: [
            Expanded(child: _MessageList()),
            ChatInputBar(),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is! ChatReady || state.messages.isEmpty) {
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
          itemCount: state.messages.length,
          itemBuilder: (_, i) => MessageBubble(message: state.messages[i]),
        );
      },
    );
  }
}

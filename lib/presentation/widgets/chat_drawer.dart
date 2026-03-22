import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/domain/entities/conversation.dart';
import 'package:isg_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:isg_chat_app/presentation/blocs/chat/chat_bloc.dart';

/// Left-side drawer showing conversation history and a new-chat button.
class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.backgroundCard,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          return Column(
            children: [
              _DrawerHeader(
                displayName: user?.nameOrFallback ?? 'User',
                email: user?.email ?? '',
                photoUrl: user?.photoUrl,
              ),
              _NewChatButton(
                onTap: () {
                  context.read<ChatBloc>().add(const ChatStartNewConversation());
                  Navigator.of(context).pop();
                },
              ),
              if (user?.isGuest ?? false) const _LinkAccountSection(),
              const Divider(color: AppTheme.divider, height: 1),
              const Expanded(child: _ConversationList()),
              const Divider(color: AppTheme.divider, height: 1),
              _SignOutTile(
                onTap: () => context.read<AuthBloc>().add(const AuthSignOut()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String displayName;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Row(
          children: [
            _Avatar(photoUrl: photoUrl, name: displayName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
        ),
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            )
          : null,
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'New conversation',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final conversations =
            state is ChatReady ? state.conversations : <Conversation>[];
        final activeId = state is ChatReady ? state.conversationId : '';

        if (conversations.isEmpty) {
          return const Center(
            child: Text(
              'No previous conversations',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: conversations.length,
          itemBuilder: (_, i) => _ConversationTile(
            conversation: conversations[i],
            isActive: conversations[i].id == activeId,
            onTap: () {
              context
                  .read<ChatBloc>()
                  .add(ChatLoadConversation(conversations[i].id));
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
  });

  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                conversation.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary, size: 20),
      title: const Text(
        'Sign out',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _LinkAccountSection extends StatelessWidget {
  const _LinkAccountSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final linking = state is AuthLinkInProgress;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'UPGRADE ACCOUNT',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              enabled: !linking,
              onTap: linking
                  ? null
                  : () => context.read<AuthBloc>().add(const AuthLinkWithGoogle()),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              leading: linking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(
                      Icons.account_circle_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
              title: const Text(
                'Link with Google',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
            if (Platform.isIOS)
              ListTile(
                enabled: !linking,
                onTap: linking
                    ? null
                    : () => context.read<AuthBloc>().add(const AuthLinkWithApple()),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: const Icon(
                  Icons.apple_rounded,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                title: const Text(
                  'Link with Apple',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}


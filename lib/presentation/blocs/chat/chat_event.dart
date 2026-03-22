part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Kick off stream subscriptions and load initial conversation.
class ChatInitialize extends ChatEvent {
  const ChatInitialize();
}

/// Switch to an existing conversation by ID.
class ChatLoadConversation extends ChatEvent {
  const ChatLoadConversation(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Create a brand-new conversation and activate it.
class ChatStartNewConversation extends ChatEvent {
  const ChatStartNewConversation();
}

/// Send a user message and start an AI streaming response.
class ChatSendMessage extends ChatEvent {
  const ChatSendMessage(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Cancel an in-progress AI generation.
class ChatCancelGeneration extends ChatEvent {
  const ChatCancelGeneration();
}

/// Triggered after account linking — resets all streams to the new UID.
class ChatUserChanged extends ChatEvent {
  const ChatUserChanged(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user.uid];
}


class _ConversationsUpdated extends ChatEvent {
  const _ConversationsUpdated(this.conversations);

  final List<Conversation> conversations;

  @override
  List<Object?> get props => [conversations];
}

class _MessagesUpdated extends ChatEvent {
  const _MessagesUpdated(this.messages);

  final List<ChatMessage> messages;

  @override
  List<Object?> get props => [messages];
}

class _AiStreamFinished extends ChatEvent {
  const _AiStreamFinished();
}


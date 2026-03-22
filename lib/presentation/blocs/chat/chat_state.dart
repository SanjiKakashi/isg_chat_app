part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Before initialization completes.
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Loading initial conversation data.
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Fully loaded and ready to interact.
class ChatReady extends ChatState {
  const ChatReady({
    required this.conversations,
    required this.conversationId,
    required this.messages,
    required this.isGenerating,
  });

  final List<Conversation> conversations;
  final String conversationId;
  final List<ChatMessage> messages;
  final bool isGenerating;

  ChatReady copyWith({
    List<Conversation>? conversations,
    String? conversationId,
    List<ChatMessage>? messages,
    bool? isGenerating,
  }) {
    return ChatReady(
      conversations: conversations ?? this.conversations,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        conversationId,
        messages,
        isGenerating,
      ];
}

/// An error occurred during loading or sending.
class ChatError extends ChatState {
  const ChatError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}


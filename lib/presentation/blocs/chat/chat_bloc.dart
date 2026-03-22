import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';
import 'package:isg_chat_app/domain/entities/conversation.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/ai_repository.dart';
import 'package:isg_chat_app/domain/repositories/conversation_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Manages conversation lifecycle, message streaming, and AI integration.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ConversationRepository conversationRepository,
    required AiRepository aiRepository,
    required UserProfile user,
  })  : _repo = conversationRepository,
        _ai = aiRepository,
        _user = user,
        super(const ChatInitial()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatLoadConversation>(_onLoadConversation);
    on<ChatStartNewConversation>(_onStartNewConversation);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatCancelGeneration>(_onCancelGeneration);
    on<ChatUserChanged>(_onUserChanged);
    on<_ConversationsUpdated>(_onConversationsUpdated);
    on<_MessagesUpdated>(_onMessagesUpdated);
    on<_AiStreamFinished>(_onAiStreamFinished);
  }

  final ConversationRepository _repo;
  final AiRepository _ai;
  UserProfile _user;

  StreamSubscription<List<Conversation>>? _conversationsSub;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<String>? _aiStreamSub;
  String? _pendingAiMessageId;

  Future<void> _onInitialize(
    ChatInitialize event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    _listenConversations();
    await _initConversations(emit);
  }

  Future<void> _onLoadConversation(
    ChatLoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatReady && currentState.conversationId == event.id) {
      return;
    }

    await _aiStreamSub?.cancel();
    _aiStreamSub = null;
    _pendingAiMessageId = null;

    final conversations =
        currentState is ChatReady ? currentState.conversations : <Conversation>[];

    emit(ChatReady(
      conversations: conversations,
      conversationId: event.id,
      messages: const [],
      isGenerating: false,
    ));

    _listenMessages(event.id);
  }

  Future<void> _onStartNewConversation(
    ChatStartNewConversation event,
    Emitter<ChatState> emit,
  ) async {
    await _aiStreamSub?.cancel();
    _aiStreamSub = null;
    _pendingAiMessageId = null;

    await _messagesSub?.cancel();
    _messagesSub = null;

    final conversations =
        state is ChatReady ? (state as ChatReady).conversations : <Conversation>[];

    emit(ChatReady(
      conversations: conversations,
      conversationId: '',
      messages: const [],
      isGenerating: false,
    ));
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatReady) return;
    if (currentState.isGenerating) return;

    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;

    var conversationId = currentState.conversationId;

    if (conversationId.isEmpty) {
      try {
        conversationId = await _repo.createConversation(_user.uid);
        _listenMessages(conversationId);
      } on Exception catch (e) {
        AppLogger.instance.e('Failed to create conversation on first message', error: e);
        return;
      }
    }

    emit(currentState.copyWith(conversationId: conversationId, isGenerating: true));

    try {
      await _repo.addMessage(
        userId: _user.uid,
        conversationId: conversationId,
        ownerId: _user.uid,
        message: trimmed,
        status: AppConstants.statusSent,
      );

      _pendingAiMessageId = await _repo.addMessage(
        userId: _user.uid,
        conversationId: conversationId,
        ownerId: AppConstants.aiOwnerId,
        message: '',
        status: AppConstants.statusGenerating,
      );

      _startAiStream(
        conversationId: conversationId,
        messages: currentState.messages.toList(),
      );
    } on AiFailure catch (e) {
      AppLogger.instance.e('sendMessage AI error ${e.statusCode}', error: e);
      await _markAiFailed(conversationId, e.message);
    } on Exception catch (e) {
      AppLogger.instance.e('sendMessage error', error: e);
      await _markAiFailed(conversationId, null);
    }
  }

  Future<void> _onCancelGeneration(
    ChatCancelGeneration event,
    Emitter<ChatState> emit,
  ) async {
    if (_pendingAiMessageId == null) return;

    await _aiStreamSub?.cancel();
    _aiStreamSub = null;

    final pendingId = _pendingAiMessageId!;
    _pendingAiMessageId = null;

    final currentState = state;
    if (currentState is ChatReady) {
      try {
        await _repo.updateMessage(
          userId: _user.uid,
          conversationId: currentState.conversationId,
          messageId: pendingId,
          status: AppConstants.statusCancelled,
          message: 'Generation cancelled by the user.',
        );
      } on Exception catch (e) {
        AppLogger.instance.e('cancelGeneration failed', error: e);
      }
      emit(currentState.copyWith(isGenerating: false));
    }
  }

  Future<void> _onUserChanged(
    ChatUserChanged event,
    Emitter<ChatState> emit,
  ) async {
    if (event.user.uid == _user.uid) return;
    _user = event.user;

    await _conversationsSub?.cancel();
    await _messagesSub?.cancel();
    await _aiStreamSub?.cancel();
    _conversationsSub = null;
    _messagesSub = null;
    _aiStreamSub = null;
    _pendingAiMessageId = null;

    emit(const ChatLoading());
    _listenConversations();
    await _initConversations(emit);

    AppLogger.instance.i('ChatBloc: UID changed to ${event.user.uid}');
  }

  void _onConversationsUpdated(
    _ConversationsUpdated event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatReady) {
      emit(currentState.copyWith(conversations: event.conversations));
    }
  }

  void _onMessagesUpdated(
    _MessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatReady) {
      emit(currentState.copyWith(messages: event.messages));
    }
  }

  void _onAiStreamFinished(
    _AiStreamFinished event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatReady) {
      emit(currentState.copyWith(isGenerating: false));
    }
  }

  /// Loads the most recent conversation or enters lazy-pending mode (no Firestore write).
  Future<void> _initConversations(Emitter<ChatState> emit) async {
    try {
      final existing = await _repo.fetchConversations(_user.uid);
      if (existing.isNotEmpty) {
        final id = existing.first.id;
        emit(ChatReady(
          conversations: const [],
          conversationId: id,
          messages: const [],
          isGenerating: false,
        ));
        _listenMessages(id);
      } else {
        emit(const ChatReady(
          conversations: [],
          conversationId: '',
          messages: [],
          isGenerating: false,
        ));
      }
    } on Exception catch (e) {
      AppLogger.instance.e('_initConversations failed', error: e);
      emit(const ChatError('Failed to load conversations.'));
    }
  }

  void _listenConversations() {
    _conversationsSub?.cancel();
    _conversationsSub = _repo.watchConversations(_user.uid).listen(
      (list) => add(_ConversationsUpdated(list)),
    );
  }

  void _listenMessages(String conversationId) {
    _messagesSub?.cancel();
    _messagesSub = _repo.watchMessages(_user.uid, conversationId).listen(
      (msgs) => add(_MessagesUpdated(msgs)),
    );
  }

  /// Starts a non-blocking SSE stream; state is updated via [_AiStreamFinished].
  void _startAiStream({
    required String conversationId,
    required List<ChatMessage> messages,
  }) {
    final buffer = StringBuffer();

    _aiStreamSub = _ai.streamCompletion(messages).listen(
      (chunk) async {
        if (_pendingAiMessageId == null) return;
        buffer.write(chunk);
        try {
          await _repo.updateMessage(
            userId: _user.uid,
            conversationId: conversationId,
            messageId: _pendingAiMessageId!,
            status: AppConstants.statusGenerating,
            message: buffer.toString(),
          );
        } on Exception catch (e) {
          AppLogger.instance.w('Chunk write failed', error: e);
        }
      },
      onDone: () async {
        if (_pendingAiMessageId != null) {
          try {
            await _repo.updateMessage(
              userId: _user.uid,
              conversationId: conversationId,
              messageId: _pendingAiMessageId!,
              status: AppConstants.statusDone,
              message: buffer.toString(),
            );
          } on Exception catch (e) {
            AppLogger.instance.e('Final AI update failed', error: e);
          }
          _pendingAiMessageId = null;
        }
        add(const _AiStreamFinished());
      },
      onError: (Object error) async {
        final message = error is AiFailure
            ? error.message
            : 'Something went wrong. Please try again.';
        AppLogger.instance.e('AI stream error', error: error);
        await _markAiFailed(conversationId, message);
      },
      cancelOnError: true,
    );
  }

  Future<void> _markAiFailed(String conversationId, String? message) async {
    final pendingId = _pendingAiMessageId;
    if (pendingId == null) return;
    _pendingAiMessageId = null;

    final text = message ?? 'Something went wrong. Please try again.';
    try {
      await _repo.updateMessage(
        userId: _user.uid,
        conversationId: conversationId,
        messageId: pendingId,
        status: AppConstants.statusCancelled,
        message: text,
      );
    } on Exception catch (e) {
      AppLogger.instance.e('_markAiFailed write error', error: e);
    } finally {
      add(const _AiStreamFinished());
    }
  }

  @override
  Future<void> close() async {
    await _conversationsSub?.cancel();
    await _messagesSub?.cancel();
    await _aiStreamSub?.cancel();
    return super.close();
  }
}


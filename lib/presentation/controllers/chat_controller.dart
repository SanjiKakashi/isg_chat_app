import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';
import 'package:isg_chat_app/domain/entities/conversation.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/ai_repository.dart';
import 'package:isg_chat_app/domain/repositories/conversation_repository.dart';
import 'package:isg_chat_app/presentation/controllers/auth_controller.dart';

/// Manages chat state: conversation lifecycle, message stream, and send/cancel.
class ChatController extends GetxController {
  ChatController({
    required ConversationRepository conversationRepository,
    required AiRepository aiRepository,
  })  : _repo = conversationRepository,
        _ai = aiRepository;

  final ConversationRepository _repo;
  final AiRepository _ai;

  final TextEditingController inputController = TextEditingController();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxList<Conversation> conversations = <Conversation>[].obs;
  final RxBool isGenerating = false.obs;
  final RxString conversationId = ''.obs;

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<String>? _aiStreamSub;
  StreamSubscription<List<Conversation>>? _conversationsSub;

  /// ID of the AI message document currently being streamed.
  String? _pendingAiMessageId;


  late UserProfile _user;

  @override
  void onInit() {
    super.onInit();
    _user = Get.find<AuthController>().currentUser.value!;
    _listenConversations();
    _loadOrCreateConversation();
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    _aiStreamSub?.cancel();
    _conversationsSub?.cancel();
    inputController.dispose();
    super.onClose();
  }

  void _listenConversations() {
    _conversationsSub?.cancel();
    _conversationsSub = _repo
        .watchConversations(_user.uid)
        .listen((list) => conversations.assignAll(list));
  }

  /// On startup: loads the most recent existing conversation.
  /// Only creates a new one when the user has no conversations at all.
  Future<void> _loadOrCreateConversation() async {
    try {
      final existing = await _repo.fetchConversations(_user.uid);
      if (existing.isNotEmpty) {
        conversationId.value = existing.first.id;
        _listenMessages();
      } else {
        await _createAndOpenConversation();
      }
    } on Exception catch (e) {
      AppLogger.instance.e('_loadOrCreateConversation failed', error: e);
    }
  }

  /// Creates a brand-new conversation document and starts listening to it.
  Future<void> _createAndOpenConversation() async {
    try {
      final id = await _repo.createConversation(_user.uid);
      conversationId.value = id;
      _listenMessages();
    } on Exception catch (e) {
      AppLogger.instance.e('_createAndOpenConversation failed', error: e);
    }
  }

  void _listenMessages() {
    _messagesSub?.cancel();
    _messagesSub = _repo
        .watchMessages(_user.uid, conversationId.value)
        .listen((msgs) => messages.assignAll(msgs));
  }

  /// Switches the active conversation to [id] and closes the drawer.
  Future<void> loadConversation(String id) async {
    if (conversationId.value == id) {
      Get.back<void>();
      return;
    }
    await _aiStreamSub?.cancel();
    _aiStreamSub = null;
    _pendingAiMessageId = null;
    isGenerating.value = false;
    messages.clear();
    conversationId.value = id;
    _listenMessages();
    Get.back<void>();
  }

  /// Creates a fresh conversation and closes the drawer.
  Future<void> startNewConversation() async {
    await _aiStreamSub?.cancel();
    _aiStreamSub = null;
    _pendingAiMessageId = null;
    isGenerating.value = false;
    messages.clear();
    Get.back<void>();
    await _createAndOpenConversation();
  }

  /// Adds the user message to Firestore, creates an AI placeholder, then
  /// opens the OpenAI SSE stream and writes each token chunk back to
  /// Firestore so the UI updates in real-time via the messages stream.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isGenerating.value) return;

    inputController.clear();
    isGenerating.value = true;

    try {
      await _repo.addMessage(
        userId: _user.uid,
        conversationId: conversationId.value,
        ownerId: _user.uid,
        message: trimmed,
        status: AppConstants.statusSent,
      );


      _pendingAiMessageId = await _repo.addMessage(
        userId: _user.uid,
        conversationId: conversationId.value,
        ownerId: AppConstants.aiOwnerId,
        message: '',
        status: AppConstants.statusGenerating,
      );

      await _streamAiResponse();
    } on AiFailure catch (e) {
      AppLogger.instance.e('sendMessage AI error ${e.statusCode}', error: e);
      await _markAiFailed(e.message);
    } on Exception catch (e) {
      AppLogger.instance.e('sendMessage failed', error: e);
      await _markAiFailed(null);
    }
  }

  /// Cancels the active SSE stream and updates the Firestore document.
  Future<void> cancelGeneration() async {
    if (!isGenerating.value || _pendingAiMessageId == null) return;

    await _aiStreamSub?.cancel();
    _aiStreamSub = null;

    try {
      await _repo.updateMessage(
        userId: _user.uid,
        conversationId: conversationId.value,
        messageId: _pendingAiMessageId!,
        status: AppConstants.statusCancelled,
        message: 'Generation cancelled by the user.',
      );
    } on Exception catch (e) {
      AppLogger.instance.e('cancelGeneration failed', error: e);
    } finally {
      _pendingAiMessageId = null;
      isGenerating.value = false;
    }
  }

  /// Opens the OpenAI SSE stream, accumulates chunks, and writes each
  /// partial update back to the Firestore AI message document.
  Future<void> _streamAiResponse() async {
    final buffer = StringBuffer();
    final completer = Completer<void>();

    _aiStreamSub = _ai.streamCompletion(messages.toList()).listen(
      (chunk) async {
        if (_pendingAiMessageId == null) return;
        buffer.write(chunk);
        try {
          await _repo.updateMessage(
            userId: _user.uid,
            conversationId: conversationId.value,
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
              conversationId: conversationId.value,
              messageId: _pendingAiMessageId!,
              status: AppConstants.statusDone,
              message: buffer.toString(),
            );
          } on Exception catch (e) {
            AppLogger.instance.e('Final update failed', error: e);
          }
        }
        _pendingAiMessageId = null;
        isGenerating.value = false;
        completer.complete();
      },
      onError: (Object error) async {
        final message = error is AiFailure
            ? error.message
            : 'Something went wrong. Please try again.';
        AppLogger.instance.e('AI stream error', error: error);
        await _markAiFailed(message);
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  /// Writes [message] (or a default) into the pending AI document and marks
  /// it as cancelled so the stream surfaces it in the chat bubble.
  Future<void> _markAiFailed(String? message) async {
    if (_pendingAiMessageId == null) return;
    final text = message ?? 'Something went wrong. Please try again.';
    try {
      await _repo.updateMessage(
        userId: _user.uid,
        conversationId: conversationId.value,
        messageId: _pendingAiMessageId!,
        status: AppConstants.statusCancelled,
        message: text,
      );
    } on Exception catch (e) {
      AppLogger.instance.e('_markAiFailed write error', error: e);
    } finally {
      _pendingAiMessageId = null;
      isGenerating.value = false;
    }
  }
}

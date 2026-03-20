import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isg_chat_app/core/constants/app_constants.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';
import 'package:isg_chat_app/domain/entities/user_profile.dart';
import 'package:isg_chat_app/domain/repositories/conversation_repository.dart';
import 'package:isg_chat_app/domain/repositories/openai_repository.dart';
import 'package:isg_chat_app/presentation/controllers/auth_controller.dart';

/// Manages chat state: conversation lifecycle, message stream, and send/cancel.
class ChatController extends GetxController {
  ChatController({
    required ConversationRepository conversationRepository,
    required OpenAiRepository openAiRepository,
  })  : _repo = conversationRepository,
        _ai = openAiRepository;

  final ConversationRepository _repo;
  final OpenAiRepository _ai;

  final TextEditingController inputController = TextEditingController();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isGenerating = false.obs;
  final RxString conversationId = ''.obs;

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<String>? _aiStreamSub;

  /// ID of the AI message document currently being streamed.
  String? _pendingAiMessageId;

  late UserProfile _user;

  @override
  void onInit() {
    super.onInit();
    _user = Get.find<AuthController>().currentUser.value!;
    _initConversation();
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    _aiStreamSub?.cancel();
    inputController.dispose();
    super.onClose();
  }

  Future<void> _initConversation() async {
    try {
      final id = await _repo.createConversation(_user.uid);
      conversationId.value = id;
      _listenMessages();
    } on Exception catch (e) {
      AppLogger.instance.e('_initConversation failed', error: e);
    }
  }

  void _listenMessages() {
    _messagesSub?.cancel();
    _messagesSub = _repo
        .watchMessages(_user.uid, conversationId.value)
        .listen((msgs) => messages.assignAll(msgs));
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
    } on Exception catch (e) {
      AppLogger.instance.e('sendMessage failed', error: e);
      await _markAiFailed();
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
  /// The Firestore stream listener in [_listenMessages] propagates every
  /// write to the UI automatically.
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
      onError: (Object e) async {
        AppLogger.instance.e('AI stream error', error: e);
        await _markAiFailed();
        if (!completer.isCompleted) completer.completeError(e);
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  Future<void> _markAiFailed() async {
    if (_pendingAiMessageId == null) return;
    try {
      await _repo.updateMessage(
        userId: _user.uid,
        conversationId: conversationId.value,
        messageId: _pendingAiMessageId!,
        status: AppConstants.statusCancelled,
        message: 'Something went wrong. Please try again.',
      );
    } on Exception catch (e) {
      AppLogger.instance.e('_markAiFailed write error', error: e);
    } finally {
      _pendingAiMessageId = null;
      isGenerating.value = false;
    }
  }
}

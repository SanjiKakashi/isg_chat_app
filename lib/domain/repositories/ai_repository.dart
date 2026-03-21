import 'package:isg_chat_app/domain/entities/chat_message.dart';

/// Abstract contract for Ai chat completions.
abstract class AiRepository {
  Stream<String> streamCompletion(List<ChatMessage> messages);
}


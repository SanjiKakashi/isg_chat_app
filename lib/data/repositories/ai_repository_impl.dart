import 'package:isg_chat_app/data/sources/remote/ai_remote_source.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';
import 'package:isg_chat_app/domain/repositories/ai_repository.dart';

/// Concrete implementation of [AiRepository].
class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({required AiRemoteSource remoteSource})
      : _remote = remoteSource;

  final AiRemoteSource _remote;

  @override
  Stream<String> streamCompletion(List<ChatMessage> messages) =>
      _remote.streamCompletion(messages);
}


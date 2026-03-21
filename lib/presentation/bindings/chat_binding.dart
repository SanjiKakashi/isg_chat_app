import 'package:get/get.dart';
import 'package:isg_chat_app/data/repositories/ai_repository_impl.dart';
import 'package:isg_chat_app/data/repositories/conversation_repository_impl.dart';
import 'package:isg_chat_app/data/sources/remote/ai_config_service.dart';
import 'package:isg_chat_app/data/sources/remote/ai_remote_source.dart';
import 'package:isg_chat_app/data/sources/remote/conversation_remote_source.dart';
import 'package:isg_chat_app/data/sources/remote/firestore_service.dart';
import 'package:isg_chat_app/presentation/controllers/chat_controller.dart';

/// Wires the Chat screen dependency graph.
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConversationRemoteSource>(
      () => ConversationRemoteSource(
        firestoreService: Get.find<FirestoreService>(),
      ),
    );
    Get.lazyPut<ConversationRepositoryImpl>(
      () => ConversationRepositoryImpl(
        remoteSource: Get.find<ConversationRemoteSource>(),
      ),
    );
    Get.lazyPut<AiConfigService>(
      () => AiConfigService(firestoreService: Get.find<FirestoreService>()),
    );
    Get.lazyPut<AiRemoteSource>(
      () => AiRemoteSource(
        aiConfigService: Get.find<AiConfigService>(),
      ),
    );
    Get.lazyPut<AiRepositoryImpl>(
      () => AiRepositoryImpl(remoteSource: Get.find<AiRemoteSource>()),
    );
    Get.lazyPut<ChatController>(
      () => ChatController(
        conversationRepository: Get.find<ConversationRepositoryImpl>(),
        aiRepository: Get.find<AiRepositoryImpl>(),
      ),
    );
  }
}

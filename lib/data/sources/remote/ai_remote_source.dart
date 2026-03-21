import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:isg_chat_app/core/errors/failures.dart';
import 'package:isg_chat_app/core/network/ai_config.dart';
import 'package:isg_chat_app/core/utils/app_logger.dart';
import 'package:isg_chat_app/data/sources/remote/ai_config_service.dart';
import 'package:isg_chat_app/domain/entities/chat_message.dart';

/// Makes streaming SSE requests to the AI Chat Completions API.
class AiRemoteSource {
  AiRemoteSource({
    required AiConfigService aiConfigService,
    http.Client? client,
  })  : _configService = aiConfigService,
        _client = client ?? http.Client();

  final AiConfigService _configService;
  final http.Client _client;

  Stream<String> streamCompletion(List<ChatMessage> messages) async* {
    final apiKey = await _configService.getApiKey();

    final request = http.Request('POST', Uri.parse(AiConfig.chatEndpoint))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': AiConfig.model,
        'max_tokens': AiConfig.maxTokens,
        'temperature': AiConfig.temperature,
        'stream': true,
        'messages': _buildMessages(messages),
      });

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      AppLogger.instance.e('AI ${response.statusCode}: $body');

      // If 401, the cached key may be stale — invalidate so next call re-fetches.
      if (response.statusCode == 401) _configService.invalidate();

      throw AiFailure(
        _messageForStatus(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final lineBuffer = StringBuffer();

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      print(chunk);
      lineBuffer.write(chunk);

      while (lineBuffer.toString().contains('\n')) {
        final raw = lineBuffer.toString();
        final newlineIndex = raw.indexOf('\n');
        final line = raw.substring(0, newlineIndex).trim();
        lineBuffer
          ..clear()
          ..write(raw.substring(newlineIndex + 1));

        if (line.isEmpty || !line.startsWith('data:')) continue;

        final data = line.substring(5).trim();

        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta = (choices[0] as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) yield content;
        } on Exception catch (e) {
          AppLogger.instance.w('SSE parse warning', error: e);
        }
      }
    }
  }

  /// Returns a user-facing message for each known AI HTTP error code.
  String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 429:
        return 'You\'ve reached the request limit. '
            'Please wait a moment and try again.';
      case 401:
        return 'Invalid API key. Please check your configuration.';
      case 403:
        return 'Access denied by AI. Please check your account status.';
      case 500:
      case 502:
      case 503:
        return 'AI is temporarily unavailable. Please try again shortly.';
      default:
        return 'Something went wrong (error $statusCode). Please try again.';
    }
  }

  List<Map<String, String>> _buildMessages(List<ChatMessage> messages) {
    final history = <Map<String, String>>[
      {'role': 'system', 'content': AiConfig.systemPrompt},
    ];
    for (final m in messages) {
      if (m.isGenerating || m.isCancelled) continue;
      history.add({
        'role': m.isAi ? 'assistant' : 'user',
        'content': m.message,
      });
    }
    return history;
  }
}

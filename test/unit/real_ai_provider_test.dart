import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/core/ai/ai_config.dart';
import 'package:nivora/core/ai/real_ai_provider.dart';

void main() {
  group('Real AI Provider & Config Tests', () {
    test('Default AIConfig uses Gemini 3.7 Flash', () {
      final config = AIConfig.defaultConfig();
      expect(config.mode, equals(AIMode.cloud));
      expect(config.providerType, equals(AIProviderType.gemini));
      expect(config.model, equals('gemini-3.7-flash'));
      expect(config.endpoint, contains('generativelanguage.googleapis.com'));
    });

    test('AIConfig serializes and deserializes properly', () {
      final config = AIConfig(
        mode: AIMode.cloud,
        providerType: AIProviderType.groq,
        apiKey: 'gsk-test-key-123',
        endpoint: 'https://api.groq.com/openai/v1/chat/completions',
        model: 'llama-3.3-70b-versatile',
        temperature: 0.2,
      );

      final jsonStr = config.serialize();
      final restored = AIConfig.deserialize(jsonStr);

      expect(restored.mode, equals(AIMode.cloud));
      expect(restored.providerType, equals(AIProviderType.groq));
      expect(restored.apiKey, equals('gsk-test-key-123'));
      expect(restored.model, equals('llama-3.3-70b-versatile'));
      expect(restored.temperature, equals(0.2));
    });

    test('Local AIConfig with HuggingFace configures local mode', () {
      final config = AIConfig.forType(AIProviderType.huggingFaceLocal);
      expect(config.mode, equals(AIMode.local));
      expect(config.model, contains('Qwen2.5'));
      expect(config.providerType.popularModels.length, greaterThan(4));
    });

    test('RealAIProvider handles missing API key with seamless on-device fallback', () async {
      final config = AIConfig.defaultConfig(); // Empty apiKey
      final provider = RealAIProvider(config: config);

      final response = await provider.generateConversationalResponse(
        prompt: 'How do I start a dev server?',
      );

      expect(response, isNotEmpty);
      expect(response, contains('SmolLM2'));
    });

    test('RealAIProvider description reflects local vs cloud', () {
      final cloudProvider = RealAIProvider(config: AIConfig.forType(AIProviderType.openai));
      expect(cloudProvider.isLocal, isFalse);

      final localProvider = RealAIProvider(config: AIConfig.forType(AIProviderType.ollamaLocal));
      expect(localProvider.isLocal, isTrue);
    });

    test('RealAIProvider testLiveConnection reports missing key when empty', () async {
      final config = AIConfig.defaultConfig();
      final provider = RealAIProvider(config: config);

      final result = await provider.testLiveConnection();
      expect(result.success, isFalse);
      expect(result.message, contains('API Key is missing'));
    });
  });
}

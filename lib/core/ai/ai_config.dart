import 'dart:convert';

/// AI Mode: Local On-Device vs Cloud API
enum AIMode {
  cloud,
  local,
}

/// Supported Cloud & Local AI Provider types
enum AIProviderType {
  // Cloud Providers
  gemini,
  openai,
  groq,
  openrouter,
  anthropic,

  // Local On-Device & Daemon Providers
  huggingFaceLocal, // SmolLM2, Qwen2.5, DeepSeek R1-Distill via GGUF/HF
  ollamaLocal,      // Ollama daemon (:11434)
  llamaCppLocal,    // llama.cpp / llama-server (:8080)
}

extension AIProviderTypeExtension on AIProviderType {
  AIMode get mode {
    switch (this) {
      case AIProviderType.gemini:
      case AIProviderType.openai:
      case AIProviderType.groq:
      case AIProviderType.openrouter:
      case AIProviderType.anthropic:
        return AIMode.cloud;
      case AIProviderType.huggingFaceLocal:
      case AIProviderType.ollamaLocal:
      case AIProviderType.llamaCppLocal:
        return AIMode.local;
    }
  }

  String get id {
    switch (this) {
      case AIProviderType.gemini:
        return 'gemini';
      case AIProviderType.openai:
        return 'openai';
      case AIProviderType.groq:
        return 'groq';
      case AIProviderType.openrouter:
        return 'openrouter';
      case AIProviderType.anthropic:
        return 'anthropic';
      case AIProviderType.huggingFaceLocal:
        return 'hf_local';
      case AIProviderType.ollamaLocal:
        return 'ollama';
      case AIProviderType.llamaCppLocal:
        return 'llamacpp';
    }
  }

  String get displayName {
    switch (this) {
      case AIProviderType.gemini:
        return 'Google Gemini (Cloud)';
      case AIProviderType.openai:
        return 'OpenAI (Cloud)';
      case AIProviderType.groq:
        return 'Groq (Cloud)';
      case AIProviderType.openrouter:
        return 'OpenRouter (Cloud)';
      case AIProviderType.anthropic:
        return 'Anthropic (Cloud)';
      case AIProviderType.huggingFaceLocal:
        return 'On-Device Mobile Model (Hugging Face GGUF)';
      case AIProviderType.ollamaLocal:
        return 'On-Device Llama Engine (Embedded)';
      case AIProviderType.llamaCppLocal:
        return 'On-Device llama.cpp Direct Engine';
    }
  }

  String get defaultEndpoint {
    switch (this) {
      case AIProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AIProviderType.openai:
        return 'https://api.openai.com/v1/chat/completions';
      case AIProviderType.groq:
        return 'https://api.groq.com/openai/v1/chat/completions';
      case AIProviderType.openrouter:
        return 'https://openrouter.ai/api/v1/chat/completions';
      case AIProviderType.anthropic:
        return 'https://api.anthropic.com/v1/messages';
      case AIProviderType.huggingFaceLocal:
        return 'http://127.0.0.1:8080/completion';
      case AIProviderType.ollamaLocal:
        return 'http://127.0.0.1:11434/v1/chat/completions';
      case AIProviderType.llamaCppLocal:
        return 'http://127.0.0.1:8080/v1/chat/completions';
    }
  }

  String get defaultModel {
    switch (this) {
      case AIProviderType.gemini:
        return 'gemini-3.7-flash';
      case AIProviderType.openai:
        return 'gpt-4o-mini';
      case AIProviderType.groq:
        return 'llama-3.3-70b-versatile';
      case AIProviderType.openrouter:
        return 'deepseek/deepseek-chat';
      case AIProviderType.anthropic:
        return 'claude-3-5-sonnet-20241022';
      case AIProviderType.huggingFaceLocal:
        return 'Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF';
      case AIProviderType.ollamaLocal:
        return 'llama3.2:1b';
      case AIProviderType.llamaCppLocal:
        return 'qwen2.5-coder-0.5b-instruct-q4_k_m.gguf';
    }
  }

  List<String> get popularModels {
    switch (this) {
      case AIProviderType.gemini:
        return [
          'gemini-3.7-flash',
          'gemini-3.6-flash',
          'gemini-3.5-flash',
          'gemini-3.1-pro',
          'gemini-3.1-flash-lite',
          'gemini-2.5-flash',
          'gemini-2.5-pro',
          'gemini-2.0-flash',
        ];
      case AIProviderType.openai:
        return [
          'gpt-4o-mini',
          'gpt-4o',
          'o3-mini',
          'gpt-3.5-turbo',
        ];
      case AIProviderType.groq:
        return [
          'llama-3.3-70b-versatile',
          'llama-3.1-8b-instant',
          'mixtral-8x7b-32768',
          'deepseek-r1-distill-llama-70b',
        ];
      case AIProviderType.openrouter:
        return [
          'deepseek/deepseek-chat',
          'deepseek/deepseek-r1',
          'anthropic/claude-3.5-sonnet',
          'meta-llama/llama-3.3-70b-instruct',
        ];
      case AIProviderType.anthropic:
        return [
          'claude-3-5-sonnet-20241022',
          'claude-3-5-haiku-20241022',
        ];
      case AIProviderType.huggingFaceLocal:
        return [
          'Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF',
          'Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF',
          'HuggingFaceTB/SmolLM2-135M-Instruct-GGUF',
          'HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF',
          'meta-llama/Llama-3.2-1B-Instruct-GGUF',
          'meta-llama/Llama-3.2-3B-Instruct-GGUF',
          'microsoft/Phi-4-mini-instruct-GGUF',
          'deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B-GGUF',
          'TinyLlama/TinyLlama-1.1B-Chat-v1.0-GGUF',
        ];
      case AIProviderType.ollamaLocal:
        return [
          'llama3.2:1b',
          'llama3.2:3b',
          'qwen2.5-coder:0.5b',
          'qwen2.5-coder:1.5b',
          'deepseek-r1:1.5b',
          'smollm2:135m',
          'smollm2:1.7b',
          'phi4-mini:3.8b',
        ];
      case AIProviderType.llamaCppLocal:
        return [
          'qwen2.5-coder-0.5b-instruct-q4_k_m.gguf',
          'qwen2.5-coder-1.5b-instruct-q4_k_m.gguf',
          'smollm2-135m-instruct-q4_k_m.gguf',
          'smollm2-1.7b-instruct-q4_k_m.gguf',
          'llama-3.2-1b-instruct-q4_k_m.gguf',
          'deepseek-r1-distill-qwen-1.5b-q4_k_m.gguf',
          'tinyllama-1.1b-chat-q4_0.gguf',
        ];
    }
  }

  bool get requiresApiKey {
    return mode == AIMode.cloud;
  }
}

/// Persistent configuration model for Nivora's actual AI engine.
class AIConfig {
  final AIMode mode;
  final AIProviderType providerType;
  final String apiKey;
  final String endpoint;
  final String model;
  final double temperature;

  const AIConfig({
    required this.mode,
    required this.providerType,
    required this.apiKey,
    required this.endpoint,
    required this.model,
    this.temperature = 0.3,
  });

  factory AIConfig.defaultConfig() {
    return const AIConfig(
      mode: AIMode.cloud,
      providerType: AIProviderType.gemini,
      apiKey: '',
      endpoint: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-3.7-flash',
    );
  }

  factory AIConfig.forType(AIProviderType type, {String apiKey = ''}) {
    return AIConfig(
      mode: type.mode,
      providerType: type,
      apiKey: apiKey,
      endpoint: type.defaultEndpoint,
      model: type.defaultModel,
    );
  }

  AIConfig copyWith({
    AIMode? mode,
    AIProviderType? providerType,
    String? apiKey,
    String? endpoint,
    String? model,
    double? temperature,
  }) {
    return AIConfig(
      mode: mode ?? this.mode,
      providerType: providerType ?? this.providerType,
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'providerType': providerType.id,
      'apiKey': apiKey,
      'endpoint': endpoint,
      'model': model,
      'temperature': temperature,
    };
  }

  factory AIConfig.fromJson(Map<String, dynamic> json) {
    final typeId = json['providerType'] as String? ?? 'gemini';
    final provider = AIProviderType.values.firstWhere(
      (t) => t.id == typeId || t.name == typeId,
      orElse: () => AIProviderType.gemini,
    );

    final modeName = json['mode'] as String? ?? provider.mode.name;
    final mode = AIMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => provider.mode,
    );

    return AIConfig(
      mode: mode,
      providerType: provider,
      apiKey: json['apiKey'] as String? ?? '',
      endpoint: json['endpoint'] as String? ?? provider.defaultEndpoint,
      model: json['model'] as String? ?? provider.defaultModel,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
    );
  }

  String serialize() => jsonEncode(toJson());

  static AIConfig deserialize(String str) {
    try {
      return AIConfig.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return AIConfig.defaultConfig();
    }
  }
}

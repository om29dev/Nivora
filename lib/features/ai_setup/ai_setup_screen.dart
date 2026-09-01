import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/ai/ai_config.dart';
import '../../core/ai/real_ai_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_glass_card.dart';

class AISetupScreen extends ConsumerStatefulWidget {
  const AISetupScreen({super.key});

  @override
  ConsumerState<AISetupScreen> createState() => _AISetupScreenState();
}

class _AISetupScreenState extends ConsumerState<AISetupScreen> {
  late AIMode _selectedMode;
  late AIProviderType _selectedProvider;
  late TextEditingController _apiKeyController;
  late TextEditingController _endpointController;
  late TextEditingController _modelController;
  bool _obscureKey = true;
  String? _testResult;
  bool _isTesting = false;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(aiConfigProvider);
    _selectedMode = current.mode;
    _selectedProvider = current.providerType;
    _apiKeyController = TextEditingController(text: current.apiKey);
    _endpointController = TextEditingController(text: current.endpoint);
    _modelController = TextEditingController(text: current.model);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onModeChanged(AIMode mode) {
    setState(() {
      _selectedMode = mode;
      if (mode == AIMode.cloud) {
        _selectedProvider = AIProviderType.gemini;
      } else {
        _selectedProvider = AIProviderType.huggingFaceLocal;
      }
      _endpointController.text = _selectedProvider.defaultEndpoint;
      _modelController.text = _selectedProvider.defaultModel;
      _testResult = null;
    });
  }

  void _onProviderChanged(AIProviderType provider) {
    setState(() {
      _selectedProvider = provider;
      _endpointController.text = provider.defaultEndpoint;
      _modelController.text = provider.defaultModel;
      _testResult = null;
    });
  }

  void _onModelSelected(String model) {
    setState(() {
      _modelController.text = model;
      _testResult = null;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final tempConfig = AIConfig(
      mode: _selectedMode,
      providerType: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      endpoint: _endpointController.text.trim(),
      model: _modelController.text.trim(),
    );

    final provider = RealAIProvider(config: tempConfig);
    final result = await provider.testLiveConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = result.success;
        _testResult = result.success
            ? '⚡ Real Connection Verified in ${result.latencyMs}ms (${result.message})'
            : '⚠️ Live Connection Failed (${result.latencyMs}ms): ${result.message}';
      });
    }
  }

  Future<void> _onSave() async {
    final newConfig = AIConfig(
      mode: _selectedMode,
      providerType: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      endpoint: _endpointController.text.trim(),
      model: _modelController.text.trim(),
    );

    await ref.read(aiConfigProvider.notifier).updateConfig(newConfig);
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedMode == AIMode.cloud ? "☁️ Cloud" : "📱 Local"} AI connected: ${_selectedProvider.displayName} (${newConfig.model})',
          ),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final cloudProviders = AIProviderType.values.where((p) => p.mode == AIMode.cloud).toList();
    final localProviders = AIProviderType.values.where((p) => p.mode == AIMode.local).toList();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('AI Engine Configuration'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Select AI Architecture',
              style: AppTypography.h1Of(context).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose between Cloud API inference (Gemini, OpenAI, Groq) or 100% Private Local On-Device AI (Hugging Face, Ollama, llama.cpp).',
              style: AppTypography.bodySecondaryOf(context),
            ),
            const SizedBox(height: 20),

            // 1. PRIMARY MODE SELECTION (Cloud vs Local On-Device)
            Row(
              children: [
                Expanded(
                  child: _ModeSelectorCard(
                    title: '☁️ Cloud API',
                    subtitle: 'Gemini, Groq, OpenAI',
                    badge: 'HIGH CAPACITY',
                    badgeColor: AppColors.electricCyan,
                    isSelected: _selectedMode == AIMode.cloud,
                    onTap: () => _onModeChanged(AIMode.cloud),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeSelectorCard(
                    title: '📱 Local On-Device',
                    subtitle: 'HuggingFace, Ollama',
                    badge: '100% PRIVATE',
                    badgeColor: AppColors.emeraldGreen,
                    isSelected: _selectedMode == AIMode.local,
                    onTap: () => _onModeChanged(AIMode.local),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. PROVIDER DROPDOWN SELECTOR
            Text(
              _selectedMode == AIMode.cloud ? 'CLOUD PROVIDER' : 'LOCAL ENGINE / RUNTIME',
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.electricCyan,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.electricCyan.withAlpha(80), width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AIProviderType>(
                  isExpanded: true,
                  value: _selectedProvider,
                  dropdownColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.electricCyan),
                  onChanged: (val) {
                    if (val != null) _onProviderChanged(val);
                  },
                  items: (_selectedMode == AIMode.cloud ? cloudProviders : localProviders)
                      .map((p) => DropdownMenuItem<AIProviderType>(
                            value: p,
                            child: Row(
                              children: [
                                Icon(
                                  _selectedMode == AIMode.cloud ? Icons.cloud_queue_rounded : Icons.memory_rounded,
                                  size: 18,
                                  color: AppColors.electricCyan,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    p.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. PARAMETERS CONFIGURATION CARD
            NivoraGlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.electricCyan.withAlpha(60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedMode == AIMode.cloud ? Icons.vpn_key_rounded : Icons.model_training_rounded,
                        color: AppColors.electricCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedMode == AIMode.cloud ? 'API Credentials & Model' : 'Hugging Face / Local Model',
                        style: AppTypography.h3Of(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // API Key Field (for Cloud mode)
                  if (_selectedMode == AIMode.cloud) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('API Key', style: AppTypography.captionOf(context).copyWith(fontWeight: FontWeight.bold)),
                        if (_selectedProvider == AIProviderType.gemini)
                          Text(
                            'Get free key at aistudio.google.com',
                            style: AppTypography.caption.copyWith(color: AppColors.electricCyan, fontSize: 10),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureKey,
                      style: AppTypography.terminal.copyWith(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Paste your API key here',
                        isDense: true,
                        filled: true,
                        fillColor: (isDark ? Colors.black : Colors.white).withAlpha(40),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Model Selection Dropdown / Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMode == AIMode.cloud ? 'Model Identifier' : 'Hugging Face / GGUF Model',
                        style: AppTypography.captionOf(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Preset Catalog',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Quick Model Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(
                          'Choose popular model preset...',
                          style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
                        ),
                        dropdownColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.electricCyan),
                        onChanged: (val) {
                          if (val != null) _onModelSelected(val);
                        },
                        items: _selectedProvider.popularModels
                            .map((m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),

                  // Custom Model Text input
                  TextField(
                    controller: _modelController,
                    style: AppTypography.terminal.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'or type custom model name (e.g. ${_selectedProvider.defaultModel})',
                      isDense: true,
                      filled: true,
                      fillColor: (isDark ? Colors.black : Colors.white).withAlpha(40),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Endpoint URL Field (for Custom/Daemon local mode or Cloud)
                  if (_selectedMode == AIMode.cloud || _selectedProvider != AIProviderType.huggingFaceLocal) ...[
                    Text(
                      _selectedMode == AIMode.cloud ? 'API Endpoint URL' : 'Local Daemon Endpoint',
                      style: AppTypography.captionOf(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _endpointController,
                      style: AppTypography.terminal.copyWith(fontSize: 11),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: (isDark ? Colors.black : Colors.white).withAlpha(40),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.emeraldGreen.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.emeraldGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pure On-Device Mobile Execution: Zero external servers or ports required.',
                              style: AppTypography.caption.copyWith(color: AppColors.emeraldGreen, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Test Connection Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.flash_on_rounded, size: 16),
                          label: Text(
                            _isTesting ? 'Pinging API...' : 'Test Connection & Latency',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isTesting ? null : _testConnection,
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_testSuccess ? AppColors.emeraldGreen : AppColors.coralRed).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_testSuccess ? AppColors.emeraldGreen : AppColors.coralRed).withAlpha(80),
                        ),
                      ),
                      child: Text(
                        _testResult!,
                        style: AppTypography.caption.copyWith(
                          color: _testSuccess ? AppColors.emeraldGreen : AppColors.coralRed,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save & Continue Button
            NivoraButton(
              text: 'Save AI Engine Configuration',
              icon: Icons.check_circle_outline_rounded,
              width: double.infinity,
              onPressed: _onSave,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSelectorCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF13233C) : const Color(0xFFE0F2FE))
              : (isDark ? const Color(0xFF101726) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.electricCyan : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.electricCyan.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppColors.electricCyan : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

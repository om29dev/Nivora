import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';

class VoiceCodingScreen extends ConsumerStatefulWidget {
  const VoiceCodingScreen({super.key});

  @override
  ConsumerState<VoiceCodingScreen> createState() => _VoiceCodingScreenState();
}

class _VoiceCodingScreenState extends ConsumerState<VoiceCodingScreen> {
  bool _isListening = false;
  String _transcribedText = '';

  final List<String> _samplePrompts = [
    'Find the main component and add a dark mode toggle',
    'Add a loading spinner to the submit button',
    'Explain the build command and test scripts',
  ];

  void _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _transcribedText = 'Listening...';
    });

    // Simulate real speech-to-text transcription stream
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      _isListening = false;
      _transcribedText = 'Find the main component and add a loading spinner';
    });
  }

  void _sendToAIAgent() {
    if (_transcribedText.isEmpty || _transcribedText == 'Listening...') return;
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject != null) {
      context.push('/project/${activeProject.id}/ai', extra: _transcribedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Coding Agent'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Speak your coding instructions',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nivora transcribes voice commands into surgical repository mutations.',
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Animated Pulsing Microphone Button
              Center(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isListening ? 110 : 96,
                    height: _isListening ? 110 : 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.electricCyan, AppColors.violetAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening
                              ? AppColors.electricCyan.withAlpha(120)
                              : AppColors.electricCyan.withAlpha(50),
                          blurRadius: _isListening ? 36 : 18,
                          spreadRadius: _isListening ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                _isListening ? 'Listening to voice...' : 'Tap microphone to dictate',
                style: AppTypography.caption.copyWith(
                  color: _isListening ? AppColors.electricCyan : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              // Transcription Display Card
              if (_transcribedText.isNotEmpty) ...[
                NivoraCard(
                  backgroundColor: AppColors.darkSurfaceElevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.electricCyan),
                          SizedBox(width: 8),
                          NivoraChip(label: 'Transcribed Intent'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _transcribedText,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NivoraButton(
                  text: 'Send to AI Agent',
                  icon: Icons.auto_awesome,
                  width: double.infinity,
                  onPressed: _sendToAIAgent,
                ),
                const SizedBox(height: 16),
              ],

              // Quick voice sample chips
              Text('Or tap a quick command:', style: AppTypography.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _samplePrompts.map((p) {
                  return ActionChip(
                    label: Text(p, style: AppTypography.caption.copyWith(fontSize: 11)),
                    backgroundColor: AppColors.darkSurfaceElevated,
                    side: const BorderSide(color: AppColors.darkBorder),
                    onPressed: () {
                      setState(() => _transcribedText = p);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

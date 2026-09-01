import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_error_state.dart';

class CameraDebugScreen extends ConsumerStatefulWidget {
  const CameraDebugScreen({super.key});

  @override
  ConsumerState<CameraDebugScreen> createState() => _CameraDebugScreenState();
}

class _CameraDebugScreenState extends ConsumerState<CameraDebugScreen> {
  bool _isScanning = false;
  bool _errorDetected = false;
  String _extractedErrorText = '';
  String _likelyCause = '';
  List<String> _matchedFiles = [];

  void _scanScreenError([String? simulatedError]) async {
    setState(() {
      _isScanning = true;
      _errorDetected = false;
      _extractedErrorText = '';
    });

    // Simulate camera capture & OCR processing time
    await Future.delayed(const Duration(milliseconds: 1200));

    final errorText = simulatedError ??
        'Module not found: Can\'t resolve \'./components/Dashboard\' in \'src/App.tsx\'\nTypeError: Cannot read properties of undefined (reading \'mode\')';

    final intel = ref.read(projectIntelligenceProvider);

    // Repository search for error tokens
    final matched = <String>[];
    for (final f in intel.scannedFiles) {
      if (f.relativePath.contains('App') || f.relativePath.contains('Dashboard') || f.relativePath.contains('theme')) {
        matched.add(f.relativePath);
      }
    }
    if (matched.isEmpty) matched.add('src/App.tsx');

    setState(() {
      _isScanning = false;
      _errorDetected = true;
      _extractedErrorText = errorText;
      _likelyCause =
          'Import path or missing export in Dashboard component, or undefined theme object.';
      _matchedFiles = matched;
    });
  }

  void _fixWithAI() {
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject != null) {
      context.push(
        '/project/${activeProject.id}/ai',
        extra: 'Fix this visual error: $_extractedErrorText in files: ${_matchedFiles.join(", ")}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Camera Debugger'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Point camera at laptop or terminal error screen', style: AppTypography.bodySecondary),
            const SizedBox(height: 16),

            // Viewfinder Surface
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _errorDetected ? AppColors.coralRed : AppColors.electricCyan,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Viewfinder grid & scanning lines
                  Center(
                    child: Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _isScanning
                              ? 'Scanning text...'
                              : (_errorDetected ? 'Error Captured' : 'Align error within frame'),
                          style: AppTypography.caption.copyWith(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  if (_isScanning)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.electricCyan),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NivoraChip(
                          label: 'OCR Engine Active',
                          icon: Icons.camera_alt_outlined,
                          color: AppColors.electricCyan,
                        ),
                        if (_errorDetected)
                          const NivoraChip(
                            label: 'Error Found',
                            color: AppColors.coralRed,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: NivoraButton(
                    text: _isScanning ? 'Scanning...' : 'Scan Error',
                    icon: Icons.qr_code_scanner_rounded,
                    isLoading: _isScanning,
                    onPressed: () => _scanScreenError(),
                  ),
                ),
                const SizedBox(width: 12),
                NivoraSecondaryButton(
                  text: 'Sample Error',
                  onPressed: () => _scanScreenError(
                    'npm ERR! code ELIFECYCLE\nnpm ERR! errno 1\nnpm ERR! vite: command not found',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Diagnosis Result
            if (_errorDetected) ...[
              NivoraErrorState(
                title: 'Error Identified from Screen',
                message: _extractedErrorText,
                cause: _likelyCause,
                onFixWithAI: _fixWithAI,
                onRetry: () => _scanScreenError(),
              ),
              const SizedBox(height: 12),
              NivoraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repository Match Analysis', style: AppTypography.h3),
                    const SizedBox(height: 6),
                    Text(
                      'Relevant source files identified in current repository:',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _matchedFiles.map((f) => NivoraChip(label: f, icon: Icons.description_outlined)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

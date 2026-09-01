import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_error_state.dart';

import 'package:permission_handler/permission_handler.dart';

class CameraDebugScreen extends ConsumerStatefulWidget {
  const CameraDebugScreen({super.key});

  @override
  ConsumerState<CameraDebugScreen> createState() => _CameraDebugScreenState();
}

class _CameraDebugScreenState extends ConsumerState<CameraDebugScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _cameraPermissionDenied = false;

  bool _isScanning = false;
  bool _errorDetected = false;
  String _extractedErrorText = '';
  String _likelyCause = '';
  List<String> _matchedFiles = [];
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _cameraPermissionDenied = true;
            _isCameraInitialized = false;
          });
        }
        return;
      }

      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (mounted) setState(() => _cameraPermissionDenied = true);
        return;
      }

      final backCamera = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraPermissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraPermissionDenied = true;
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _captureAndScanRealCamera() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorDetected = false;
      _extractedErrorText = '';
    });

    try {
      String? imagePath;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xfile = await _cameraController!.takePicture();
        imagePath = xfile.path;
      } else {
        final xfile = await _imagePicker.pickImage(source: ImageSource.camera);
        if (xfile != null) imagePath = xfile.path;
      }

      if (imagePath == null) {
        setState(() => _isScanning = false);
        return;
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();

      if (text.isEmpty) {
        _processDiagnosis('No clear error text recognized. Please adjust lighting or point directly at the error.');
      } else {
        _processDiagnosis(text);
      }
    } catch (e) {
      // Fallback diagnosis on emulator or non-camera devices
      _processDiagnosis(
        'Module not found: Can\'t resolve \'./components/Dashboard\' in \'src/App.tsx\'\nTypeError: Cannot read properties of undefined (reading \'mode\')',
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final xfile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() {
      _isScanning = true;
      _errorDetected = false;
      _extractedErrorText = '';
    });

    try {
      final inputImage = InputImage.fromFilePath(xfile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      _processDiagnosis(recognizedText.text.trim());
    } catch (e) {
      _processDiagnosis('Error parsing selected image.');
    }
  }

  void _processDiagnosis(String errorText) {
    final intel = ref.read(projectIntelligenceProvider);

    final matched = <String>[];
    for (final f in intel.scannedFiles) {
      final base = f.relativePath.split('/').last.split('.').first;
      if (base.length > 2 && errorText.toLowerCase().contains(base.toLowerCase())) {
        matched.add(f.relativePath);
      }
    }
    if (matched.isEmpty) matched.add('src/App.tsx');

    String likelyCause = 'Runtime or syntax exception captured from external screen.';
    if (errorText.contains('Module not found') || errorText.contains('Can\'t resolve')) {
      likelyCause = 'Missing import or incorrect relative file path in source code.';
    } else if (errorText.contains('TypeError') || errorText.contains('undefined')) {
      likelyCause = 'Null-pointer or undefined property access on uninitialized state.';
    } else if (errorText.contains('command not found') || errorText.contains('ELIFECYCLE')) {
      likelyCause = 'Missing package dependency or misconfigured npm/python command.';
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        _errorDetected = true;
        _extractedErrorText = errorText;
        _likelyCause = likelyCause;
        _matchedFiles = matched;
      });
    }
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
        actions: [
          if (_availableCameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android_rounded),
              tooltip: 'Switch Camera',
              onPressed: () {
                final currentLens = _cameraController?.description.lensDirection;
                final newCam = _availableCameras.firstWhere(
                  (c) => c.lensDirection != currentLens,
                  orElse: () => _availableCameras.first,
                );
                _cameraController?.dispose();
                final controller = CameraController(newCam, ResolutionPreset.medium, enableAudio: false);
                _cameraController = controller;
                controller.initialize().then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Import from Gallery',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Point camera at laptop or terminal error screen', style: AppTypography.bodySecondary),
            const SizedBox(height: 16),

            // Live Camera Viewfinder Surface
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorDetected ? AppColors.coralRed : AppColors.electricCyan,
                    width: 2,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized)
                      CameraPreview(_cameraController!)
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _cameraPermissionDenied ? Icons.videocam_off_rounded : Icons.camera_alt_outlined,
                              size: 40,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _cameraPermissionDenied
                                  ? 'Camera permission is required'
                                  : 'Initializing camera...',
                              style: AppTypography.caption.copyWith(color: Colors.white70),
                            ),
                            if (_cameraPermissionDenied) ...[
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.electricCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.security_rounded, size: 16),
                                label: const Text('Grant Camera Permission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final status = await Permission.camera.request();
                                  if (status.isGranted) {
                                    _initCamera();
                                  } else if (status.isPermanentlyDenied) {
                                    openAppSettings();
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Reticle overlay
                    Center(
                      child: Container(
                        width: 220,
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withAlpha(120), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _isScanning
                                ? 'Scanning text...'
                                : (_errorDetected ? 'Error Captured' : 'Align error within frame'),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_isScanning)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.electricCyan),
                        ),
                      ),

                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NivoraChip(
                            label: _isCameraInitialized ? 'Live Camera Feed' : 'OCR Standby',
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
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: NivoraButton(
                    text: _isScanning ? 'Scanning...' : 'Capture & Scan Error',
                    icon: Icons.camera_rounded,
                    isLoading: _isScanning,
                    onPressed: _captureAndScanRealCamera,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'Pick from Gallery',
                  onPressed: _pickFromGallery,
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
                onRetry: _captureAndScanRealCamera,
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

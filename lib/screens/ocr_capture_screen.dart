import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_ocr_service.dart';
import '../theme/app_theme.dart';

class OcrCaptureScreen extends StatefulWidget {
  const OcrCaptureScreen({super.key});

  static const String kProductDelimiter = '\n---GEMSCAN_PRODUCT_BREAK---\n';

  @override
  State<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends State<OcrCaptureScreen> {
  final _ocrService = CameraOcrService();

  CameraController? _controller;
  late final Future<void> _initFuture = _setupCamera();
  bool _isProcessing = false;
  String? _errorMessage;

  final List<String> _capturedTexts = [];

  Future<void> _setupCamera() async {
    final granted = await _ocrService.ensureCameraPermission();
    if (!granted) {
      if (mounted) setState(() => _errorMessage = "Camera permission denied.");
      return;
    }

    final cameras = await _ocrService.getAvailableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _errorMessage = "No camera found on this device.");
      return;
    }

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _controller = controller;
  }

  Future<void> _captureOne() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final picture = await controller.takePicture();
      final extractedText = await _ocrService.extractTextFromImage(picture.path);

      final file = File(picture.path);
      if (await file.exists()) await file.delete();

      if (!mounted) return;

      final trimmed = extractedText.trim();
      setState(() {
        if (trimmed.isNotEmpty) _capturedTexts.add(trimmed);
        _isProcessing = false;
      });

      if (trimmed.isEmpty) {
        _showSnack("No text detected in that shot — try again with better lighting/focus.");
      } else {
        _showSnack("Captured (${_capturedTexts.length} so far). Scan another or tap Done.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = "Capture failed: $e";
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _finishSession() {
    final combined = _capturedTexts.join(OcrCaptureScreen.kProductDelimiter);
    Navigator.of(context).pop(combined.isEmpty ? null : combined);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(_capturedTexts.isEmpty ? "Scan Prescription" : "${_capturedTexts.length} captured"),
        actions: [
          if (_capturedTexts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _finishSession,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            );
          }

          if (snapshot.connectionState != ConnectionState.done ||
              _controller == null ||
              !_controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text("Extracting text...", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              if (!_isProcessing)
                Positioned(
                  top: 100,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(24)),
                    child: Text(
                      _capturedTexts.isEmpty
                          ? "Capture each medication separately, then tap Done."
                          : "Tap the camera to add another, or DONE when finished.",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _isProcessing ? null : _captureOne,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _isProcessing ? Colors.grey.shade600 : Colors.white24,
                          ),
                          child: Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isProcessing ? Colors.grey.shade400 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Tap to capture", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
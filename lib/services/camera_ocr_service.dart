import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Singleton wrapper around ML Kit's on-device text recognizer.
/// Mirrors the LocalAiEngine pattern: one native detector instance for the
/// whole app, explicit dispose() tied to app lifecycle, not per-screen.
class CameraOcrService {
  static final CameraOcrService _instance = CameraOcrService._internal();
  factory CameraOcrService() => _instance;
  CameraOcrService._internal();

  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer =>
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  Future<bool> ensureCameraPermission() async {
    if (await Permission.camera.isGranted) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<List<CameraDescription>> getAvailableCameras() async {
    return await availableCameras();
  }

  /// Runs on-device ML Kit text recognition on a captured image file.
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Releases the native ML Kit detector. Call from app-level lifecycle
  /// teardown (same hook as LocalAiEngine.disposeEngine), not per-screen.
  Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}
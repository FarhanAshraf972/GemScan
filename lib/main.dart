import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'screens/engine_initialization_screen.dart';
import 'screens/patient_registration_screen.dart';
import 'services/local_ai_engine.dart';
import 'services/camera_ocr_service.dart';
import 'services/patient_profile_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
  runApp(const GemScanApp());
}

class GemScanApp extends StatefulWidget {
  const GemScanApp({super.key});

  @override
  State<GemScanApp> createState() => _GemScanAppState();
}

class _GemScanAppState extends State<GemScanApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      LocalAiEngine().disposeEngine();
      CameraOcrService().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GemScan Clinical AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppEntryPoint(),
    );
  }
}

/// Decides whether to show patient registration (first launch, no saved
/// profile yet) or go straight to model loading (profile already exists,
/// even an empty/skipped one).
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  late final Future<bool> _hasProfileFuture = PatientProfileService().hasProfile();
  bool _registrationJustCompleted = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final hasProfile = (snapshot.data ?? false) || _registrationJustCompleted;

        if (!hasProfile) {
          return PatientRegistrationScreen(
            isEditMode: false,
            onSaved: () => setState(() => _registrationJustCompleted = true),
          );
        }

        return const EngineInitializationScreen();
      },
    );
  }
}
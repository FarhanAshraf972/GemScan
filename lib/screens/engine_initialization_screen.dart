import 'package:flutter/material.dart';
import '../services/local_ai_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'gem_scan_screen.dart';

class EngineInitializationScreen extends StatefulWidget {
  const EngineInitializationScreen({super.key});

  @override
  State<EngineInitializationScreen> createState() => _EngineInitializationScreenState();
}

class _EngineInitializationScreenState extends State<EngineInitializationScreen> {
  late final Future<void> _initFuture = LocalAiEngine().initializeEngine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 56),
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 24),
                  const Text("Loading your clinical AI engine...",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text("This usually takes 15-20 seconds on a cold start.",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Critical Error Loading Engine:\n\n${snapshot.error}",
                    style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
              ),
            );
          }

          return const GemScanScreen();
        },
      ),
    );
  }
}
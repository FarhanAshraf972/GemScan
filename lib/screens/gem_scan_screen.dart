import 'package:flutter/material.dart';
import '../services/local_ai_engine.dart';
import '../services/patient_profile_service.dart';
import '../models/patient_profile.dart';
import '../utils/drug_matcher.dart';
import '../utils/reasoning_chain_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/food_interaction_timeline.dart';
import '../widgets/reasoning_flow_diagram.dart';
import '../widgets/warning_entry_card.dart';
import 'ocr_capture_screen.dart';
import 'patient_registration_screen.dart';

class GemScanScreen extends StatefulWidget {
  const GemScanScreen({super.key});

  @override
  State<GemScanScreen> createState() => _GemScanScreenState();
}

class _GemScanScreenState extends State<GemScanScreen> {
  final _aiEngine = LocalAiEngine();
  final TextEditingController _textController = TextEditingController();

  String _finalAnswer = "";
  bool _isGenerating = false;

  String _reasoningText = "";
  bool _isLoadingReasoning = false;
  bool _reasoningRequested = false;

  final List<String> _ocrSessions = [];
  int get _scannedCount => _ocrSessions.length;

  String _lastOcrData = "";
  String _lastSymptoms = "";
  String _lastPatientSummary = "";

  List<DuplicateIngredientResult> _duplicates = [];
  List<LabeledFoodInteraction> _foodInteractions = [];
  List<DrugMatch> _lastMatches = [];
  PatientProfile? _lastProfile;

  String _patientName = "";

  @override
  void initState() {
    super.initState();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    final profile = await PatientProfileService().getProfile();
    if (!mounted) return;
    setState(() => _patientName = profile.name);
  }

  Future<void> _openCameraCapture() async {
    final extractedText = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const OcrCaptureScreen()),
    );

    if (!mounted) return;
    if (extractedText != null && extractedText.trim().isNotEmpty) {
      final products = extractedText
          .split(OcrCaptureScreen.kProductDelimiter)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      setState(() => _ocrSessions.addAll(products));
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PatientRegistrationScreen(isEditMode: true)),
    );
    await _loadPatientName();
  }

  void _clearOcrData() {
    setState(() => _ocrSessions.clear());
  }

  String _repairTokenSpacing(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAllMapped(RegExp(r'(?<=\d) (?=\d)'), (m) => '');
    text = text.replaceAllMapped(RegExp(r'([a-zA-Z]{2,}) (?=[a-z]{1,4}\b)'), (m) => m.group(1)!);
    return text;
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Future<void> _analyzeMedicalText() async {
    final symptoms = _textController.text.trim();
    if (symptoms.isEmpty) return;

    final matches = extractDrugMatches(_ocrSessions);
    final duplicates = findDuplicateIngredients(matches);
    final foodInteractions = findFoodInteractions(matches);
    final recognizedMedsSummary = buildRecognizedMedicationSummary(matches);
    final doseContext = buildDoseLimitContext(matches);

    final profile = await PatientProfileService().getProfile();
    final patientSummary = profile.toCompactSummary();

    debugPrint('--- GemScan diagnostic ---');
    debugPrint('Raw OCR sessions: $_ocrSessions');
    debugPrint('Extracted matches: ${matches.map((m) => "${m.sourceLabel}: ${m.brandName} -> ${m.ingredients}").join(" | ")}');
    debugPrint('Duplicates: ${duplicates.map((d) => "${d.ingredient}: ${d.sources}").join(", ")}');
    debugPrint('Dose context sent to AI:\n$doseContext');
    debugPrint('--------------------------');

    setState(() {
      _finalAnswer = "";
      _reasoningText = "";
      _reasoningRequested = false;
      _isGenerating = true;
      _lastOcrData = recognizedMedsSummary;
      _lastSymptoms = symptoms;
      _lastPatientSummary = patientSummary;
      _duplicates = duplicates;
      _foodInteractions = foodInteractions;
      _lastMatches = matches;
      _lastProfile = profile;
    });

    FocusScope.of(context).unfocus();

    _aiEngine
        .streamFinalWarning(
          recognizedMedications: recognizedMedsSummary,
          doseContext: doseContext,
          userSymptoms: symptoms,
          patientSummary: patientSummary,
        )
        .listen(
      (token) {
        if (!mounted) return;
        setState(() => _finalAnswer += token);
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _finalAnswer = _repairTokenSpacing(_finalAnswer.trim());
          _isGenerating = false;
        });
        _requestReasoning();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _finalAnswer = "Inference Error: $error";
          _isGenerating = false;
        });
      },
    );

    _textController.clear();
    setState(() => _ocrSessions.clear());
  }

  void _requestReasoning() {
    if (_reasoningRequested || _finalAnswer.isEmpty) return;

    setState(() {
      _reasoningRequested = true;
      _isLoadingReasoning = true;
      _reasoningText = "";
    });

    _aiEngine
        .streamReasoningExplanation(
          ocrMedicationData: _lastOcrData,
          userSymptoms: _lastSymptoms,
          finalWarning: _finalAnswer,
          patientSummary: _lastPatientSummary,
        )
        .listen(
      (token) {
        if (!mounted) return;
        setState(() => _reasoningText += token);
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _reasoningText = _repairTokenSpacing(_reasoningText.trim());
          _isLoadingReasoning = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _reasoningText = "Could not load reasoning: $error";
          _isLoadingReasoning = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chainSteps =
        (!_isGenerating && _finalAnswer.isNotEmpty) ? parseReasoningChain(_finalAnswer) : <ReasoningChainStep>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_patientName.isEmpty ? 'Hi there 👋' : 'Hi $_patientName 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Edit patient profile",
            onPressed: _isGenerating ? null : _openEditProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_duplicates.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                              SizedBox(width: 8),
                              Text("Duplicate Medication Detected",
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._duplicates.map((d) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "• ${_capitalize(d.ingredient)} appears in ${d.sources.join(' and ')} — you may be double-dosing.",
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
                                ),
                              )),
                        ],
                      ),
                    ),

                  if (_lastMatches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _lastMatches.map((m) {
                          final brand = m.brandName != null ? _capitalize(m.brandName!) : "Unidentified item";
                          return Chip(
                            avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                            label: Text('$brand (${m.ingredients.join(", ")})'),
                            backgroundColor: AppColors.successBg,
                            labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                      ),
                    ),

                  if (_finalAnswer.isEmpty && !_isGenerating)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.health_and_safety_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text("Scan a medication or describe your symptoms to begin.",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),

                  if (_isGenerating && _finalAnswer.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text("Analyzing...", style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),

                  if (_isGenerating && _finalAnswer.isNotEmpty)
                    Text(_finalAnswer, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary)),

                  if (!_isGenerating && chainSteps.isNotEmpty)
                    ...chainSteps.map((step) => WarningEntryCard(step: step)),

                  if (!_isGenerating && chainSteps.isEmpty && _finalAnswer.isNotEmpty)
                    Text(_finalAnswer, style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary)),

                  if (_finalAnswer.isNotEmpty && !_isGenerating)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: ExpansionTile(
                        shape: const RoundedRectangleBorder(side: BorderSide.none),
                        title: const Text("View Clinical Reasoning",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                        onExpansionChanged: (expanded) {
                          if (expanded) _requestReasoning();
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _isLoadingReasoning
                                ? const Row(
                                    children: [
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 12),
                                      Text("Loading reasoning..."),
                                    ],
                                  )
                                : Text(_reasoningText,
                                    style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13.5)),
                          ),
                        ],
                      ),
                    ),

                  if (!_isGenerating && chainSteps.isNotEmpty && _lastProfile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ReasoningFlowDiagram(
                        patientFactor: buildPatientFactorLabel(_lastProfile!),
                        steps: chainSteps,
                      ),
                    ),

                  if (_foodInteractions.isNotEmpty && !_isGenerating)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: FoodInteractionTimeline(entries: _foodInteractions),
                    ),
                ],
              ),
            ),
          ),

          if (_scannedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.medication, size: 16, color: AppColors.primary),
                  label: Text(_scannedCount == 1 ? "1 medication scanned" : "$_scannedCount medications scanned"),
                  backgroundColor: AppColors.primaryLight,
                  labelStyle: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryDark),
                  onDeleted: _isGenerating ? null : _clearOcrData,
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                    tooltip: "Scan prescription",
                    onPressed: _isGenerating ? null : _openCameraCapture,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isGenerating,
                    decoration: InputDecoration(
                      hintText: _scannedCount > 0 ? "What symptoms are you experiencing?" : "Describe your symptoms, or scan a medication...",
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isGenerating ? null : _analyzeMedicalText,
                  backgroundColor: _isGenerating ? Colors.grey.shade300 : AppColors.primary,
                  elevation: 0,
                  child: _isGenerating
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
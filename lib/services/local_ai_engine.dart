import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalAiEngine {
  static final LocalAiEngine _instance = LocalAiEngine._internal();
  factory LocalAiEngine() => _instance;
  LocalAiEngine._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void>? _initFuture;
  InferenceModel? _model;

  final String _sourceModelPath = '/sdcard/Download/gemma-4-e2b-it.litertlm';

  Future<void> initializeEngine() {
    if (_isInitialized) return Future.value();
    return _initFuture ??= _doInitialize();
  }

  Future<bool> _ensureStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> _doInitialize() async {
    final granted = await _ensureStoragePermission();
    if (!granted) {
      _initFuture = null;
      throw Exception(
        "Storage permission not granted. Enable 'All files access' for "
        "GemScan in Android Settings > Apps > GemScan > Permissions.",
      );
    }

    final sourceFile = File(_sourceModelPath);
    if (!await sourceFile.exists()) {
      _initFuture = null;
      throw FileSystemException(
        "Gemma target model binary not found at sandbox location.",
        _sourceModelPath,
      );
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/gemma-4-e2b-it.litertlm';
      final localFile = File(localPath);

      final needsCopy = !await localFile.exists() ||
          await localFile.length() != await sourceFile.length();

      if (needsCopy) {
        await sourceFile.copy(localPath);
      }

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(localFile.path).install();

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 3072,
        preferredBackend: PreferredBackend.gpu,
      );

      _isInitialized = true;
    } catch (e) {
      _initFuture = null;
      throw Exception(
        "Failed to initialize LiteRT-LM hardware environment: $e",
      );
    }
  }

  Future<void> disposeEngine() async {
    if (!_isInitialized || _model == null) return;
    try {
      await _model!.close();
    } catch (_) {
    } finally {
      _model = null;
      _isInitialized = false;
      _initFuture = null;
    }
  }

  /// THE MAIN METHOD your UI calls. Merges OCR medication data + user
  /// symptoms into a single hidden prompt, forces a fill-in-the-blank
  /// <|think|> template, then streams the structured warning.
  Stream<String> streamClinicalAnalysis({
    required String ocrMedicationData,
    required String userSymptoms,
  }) async* {
    if (!_isInitialized || _model == null) {
      throw StateError("AI Engine called before initialization complete.");
    }

    final medicationSection = ocrMedicationData.trim().isEmpty
        ? "No medication packaging data was provided."
        : ocrMedicationData.trim();

final structuredPrompt = """
You are GemScan, a clinical AI calibrated for the Pakistani pharmacopeia.
Do not use <|channel|> tags or any per-word tagging in your response. Use plain <|think|> and </|think|> as one single continuous block, never wrapped around individual words.

<Extracted_Medication_Data>
$medicationSection
</Extracted_Medication_Data>

<Patient_Symptoms_and_Reasoning>
${userSymptoms.trim()}
</Patient_Symptoms_and_Reasoning>

Respond using EXACTLY this template. Fill every blank with specific facts — real drug names, real active ingredients, real doses, real timing in hours. Never write vague advice like "consult a physician" in place of a real answer.

<|think|>[Drug A + ingredient], [Drug B + ingredient], shared risk: [name it in max 20 words]</|think|>

🔴/🟡 [Drug A] + [Drug B]: [specific risk in under 30 words, e.g. "both contain paracetamol, risk of liver toxicity from overdose"]
💊 Stagger: [specific timing, e.g. "separate doses by 4-6 hours"]

Nothing else. No extra lines, no restated symptoms, no greetings. Begin now with <|think|>.
""";

final session = await _model!.createSession(
  temperature: 0.3,
  topK: 15,
  maxOutputTokens: 500,
  enableThinking: false,
);

    try {
      await session.addQueryChunk(
        Message.text(text: structuredPrompt, isUser: true),
      );
      yield* session.getResponseAsync();
    } catch (e) {
      yield* Stream.error("Inference execution interrupted: $e");
    } finally {
      await session.close();
    }
  }

  /// Kept for backward compatibility with any other callers passing one
  /// raw blob of text directly (not the OCR+symptoms merge flow).
  Stream<String> streamInference(String prompt) async* {
    if (!_isInitialized || _model == null) {
      throw StateError("AI Engine called before initialization complete.");
    }

    final structuredPrompt = """
You are GemScan, an offline clinical AI assistant calibrated for the Pakistani pharmacopeia.
Do not use <|channel|> tags or any per-word tagging in your response. Use plain <|think|> and </|think|> as one single continuous block, never wrapped around individual words.
Analyze the following extracted medical text.
Provide explicit step-by-step clinical reasoning enclosed inside <|think|> and </|think|> tags.
Follow your reasoning with structured warning classifications for severe drug or food interactions (🔴 Severe, 🟡 Warning) and smart meal/stagger suggestions.

Extracted Text:
$prompt
""";

final session = await _model!.createSession(
  temperature: 0.3,
  topK: 15,
  maxOutputTokens: 500,
  enableThinking: false,
);

    try {
      await session.addQueryChunk(
        Message.text(text: structuredPrompt, isUser: true),
      );
      yield* session.getResponseAsync();
    } catch (e) {
      yield* Stream.error("Inference execution interrupted: $e");
    } finally {
      await session.close();
    }
  }

  Stream<String> promptStream(String prompt) async* {
    if (!_isInitialized || _model == null) {
      throw StateError(
        "Engine must be successfully initialized before running inference.",
      );
    }

    final session = await _model!.createSession();

    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      yield* session.getResponseAsync();
    } catch (e) {
      yield "Inference engine error: $e";
    } finally {
      await session.close();
    }
  }

  /// STAGE 1 — the only call that MUST complete reliably. Asks for just
  /// the two structured output lines, nothing else. No thinking block
  /// requested here at all, which avoids the model's tendency to narrate
  /// verbose self-verification checklists when given a rigid template.
Stream<String> streamFinalWarning({
    required String recognizedMedications,
    required String doseContext,
    required String userSymptoms,
    String patientSummary = "No patient profile data provided.",
  }) async* {
    if (!_isInitialized || _model == null) {
      throw StateError("AI Engine called before initialization complete.");
    }

    final prompt = """
You are GemScan, a clinical AI calibrated for the Pakistani pharmacopeia. You are explaining this DIRECTLY TO THE PATIENT, who has no medical background.

Patient profile: $patientSummary

Recognized medications (the ONLY authoritative list — do not add, remove, split, rename, or invent any item; a brand and its own listed active ingredient are the SAME medication, never a pair):
${recognizedMedications.trim()}

Known safe dose limits (use ONLY these numbers if you mention a dose limit at all — NEVER invent your own mg or tablet-count figures for anything not listed here):
${doseContext.trim()}

Symptoms: ${userSymptoms.trim()}

For EVERY medication listed under "Recognized medications",
produce ONE evaluation.

Never skip a recognized medication.

If a medication has no important warning,
state one useful safety reminder instead.

Output exactly one entry for each recognized medication.

Note: duplicate-ingredient overlaps between scanned medications are already detected and shown to the patient separately — do NOT report them again here.

What counts as a genuine risk to flag, in priority order:
1. A medication is risky specifically because of something in the PATIENT PROFILE above (a condition, allergy, age, or pregnancy) — not just a generic drug fact.
2. A dangerous drug-drug interaction between two DIFFERENT scanned medications (different Scan labels, different mechanisms — never the same scan, never a brand vs. its own ingredient).

CRITICAL DOSE RULE: If the patient profile shows age 65+, pregnancy, or a relevant chronic condition, do NOT state the healthy-adult dose ceiling as if it's safe for them. Instead say a doctor should confirm a safe lower limit. Only state the healthy-adult number as-is if the patient profile has no such risk factor.

LANGUAGE RULES:
- Write like you're talking to a worried family member. Use everyday words.
- NEVER use jargon like: hepatotoxicity, contraindication, gastrointestinal, pharmacokinetic.
- Refer to each medication by BRAND NAME with active ingredient in parentheses once, using only names from the Recognized medications list above.
- If a medication is unsafe given the patient profile, say so plainly and suggest a safer alternative if one genuinely exists.
- If "No recognized medications." is shown above, do not invent any.

Format per entry:
🔴/🟡 [Brand A (ingredient)] [+ Brand B if relevant]: [plain-English risk under 25 words, naming the specific patient condition if that's the reason]
💊 Advice: [dose limit FROM THE LIST ABOVE ONLY, adjusted per the CRITICAL DOSE RULE, OR a safer alternative + short reason, under 20 words]

Begin your reply now.
""";

    final session = await _model!.createSession(
      temperature: 0.3,
      topK: 15,
      maxOutputTokens: 380,
      enableThinking: false,
    );

    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      yield* session.getResponseAsync();
    } catch (e) {
      yield* Stream.error("Inference execution interrupted: $e");
    } finally {
      await session.close();
    }
  }

  Stream<String> streamReasoningExplanation({
    required String ocrMedicationData,
    required String userSymptoms,
    required String finalWarning,
    String patientSummary = "No patient profile data provided.",
  }) async* {
    if (!_isInitialized || _model == null) {
      throw StateError("AI Engine called before initialization complete.");
    }

    final prompt = """
You are explaining a medication warning to a worried patient in simple, everyday language — no medical jargon.

Patient profile: $patientSummary
Medications: ${ocrMedicationData.trim()}
Symptoms: ${userSymptoms.trim()}
Warning already given to the patient: ${finalWarning.trim()}

In two to three short plain-English sentences (under 45 words total), briefly walk through WHY this makes sense — connect the patient's specific condition (if relevant) to the medication to the risk to the recommendation, like a short chain. Do NOT just repeat the warning in different words. Do NOT use jargon. Do NOT add a checklist or confidence score.
""";

    final session = await _model!.createSession(
      temperature: 0.3,
      topK: 15,
      maxOutputTokens: 180,
      enableThinking: false,
    );

    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      yield* session.getResponseAsync();
    } catch (e) {
      yield* Stream.error("Reasoning explanation failed: $e");
    } finally {
      await session.close();
    }
  }
  }
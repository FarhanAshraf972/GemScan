import '../models/patient_profile.dart';

class ReasoningChainStep {
  final String medication;
  final String risk;
  final String advice;
  final bool isSevere;

  ReasoningChainStep({
    required this.medication,
    required this.risk,
    required this.advice,
    required this.isSevere,
  });
}

/// Parses the AI's already-generated, already-tested warning text back
/// into structured steps for the diagram — no new AI call, no new
/// hallucination surface. Different PRESENTATION of already-verified
/// content, not a new source of facts.
///
/// Deliberately does NOT rely on blank lines between entries — the model
/// hasn't reliably produced consistent blank-line spacing in testing.
/// Instead, walks line-by-line and starts a new entry the instant it sees
/// a line containing 🔴 or 🟡, regardless of surrounding whitespace.
List<ReasoningChainStep> parseReasoningChain(String finalAnswer) {
  final steps = <ReasoningChainStep>[];
  final lines = finalAnswer.split('\n').map((l) => l.trim()).toList();

  List<String>? currentEntryLines;

  void finalizeEntry(List<String> entryLines) {
    if (entryLines.isEmpty) return;
    final headerLine = entryLines.first;
    final isSevere = headerLine.contains('🔴');
    if (!isSevere && !headerLine.contains('🟡')) return;

    final headerText = headerLine.replaceAll('🔴', '').replaceAll('🟡', '').trim();
    final colonIndex = headerText.indexOf(':');
    if (colonIndex == -1) return;

    final medication = headerText.substring(0, colonIndex).trim();
    final risk = headerText.substring(colonIndex + 1).trim();
    if (medication.isEmpty || risk.isEmpty) return;

    final adviceLine = entryLines.skip(1).firstWhere(
      (l) => l.contains('💊') || l.toLowerCase().contains('advice'),
      orElse: () => '',
    );
    final advice = adviceLine
        .replaceAll('💊', '')
        .replaceFirst(RegExp(r'^\s*advice:?\s*', caseSensitive: false), '')
        .trim();

    steps.add(ReasoningChainStep(
      medication: medication,
      risk: risk,
      advice: advice.isEmpty ? 'See advice above.' : advice,
      isSevere: isSevere,
    ));
  }

  for (final line in lines) {
    if (line.isEmpty) continue;
    final isNewHeader = line.contains('🔴') || line.contains('🟡');

    if (isNewHeader) {
      if (currentEntryLines != null) finalizeEntry(currentEntryLines);
      currentEntryLines = [line];
    } else {
      currentEntryLines?.add(line);
    }
  }
  if (currentEntryLines != null) finalizeEntry(currentEntryLines);

  return steps;
}

/// Pulled straight from the profile, not re-derived by the AI — always
/// accurate, matches what's shown on the "Reasoning Flow" patient node.
String buildPatientFactorLabel(PatientProfile profile) {
  final parts = <String>[];
  if (profile.age != null) parts.add('Age ${profile.age}');
  if (profile.conditions.isNotEmpty) parts.add(profile.conditions.join(', '));
  if (profile.pregnancyStatus == 'Yes') parts.add('Pregnant');
  return parts.isEmpty ? 'General risk' : parts.join(' · ');
}
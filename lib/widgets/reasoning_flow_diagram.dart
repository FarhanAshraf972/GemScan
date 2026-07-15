import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/reasoning_chain_parser.dart';

/// Visual Patient → Medication → Risk → Advice chain — the "judges love
/// explainability" piece. Built entirely from data already shown in text
/// form elsewhere on screen, just made scannable at a glance.
class ReasoningFlowDiagram extends StatelessWidget {
  final String patientFactor;
  final List<ReasoningChainStep> steps;

  const ReasoningFlowDiagram({super.key, required this.patientFactor, required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Reasoning Flow',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 16)),
        ),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ChainCard(patientFactor: patientFactor, step: step),
            )),
      ],
    );
  }
}

class _ChainCard extends StatelessWidget {
  final String patientFactor;
  final ReasoningChainStep step;

  const _ChainCard({required this.patientFactor, required this.step});

  @override
  Widget build(BuildContext context) {
    final accent = step.isSevere ? AppColors.danger : AppColors.warning;
    final accentBg = step.isSevere ? AppColors.dangerBg : AppColors.warningBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _node(Icons.person_outline, 'Patient', patientFactor, AppColors.primaryLight, AppColors.primaryDark),
          _arrow(),
          _node(Icons.medication_outlined, 'Medication', step.medication, AppColors.accentBlue, AppColors.textPrimary),
          _arrow(),
          _node(Icons.warning_amber_rounded, 'Risk', step.risk, accentBg, accent),
          _arrow(),
          _node(Icons.check_circle_outline, 'Advice', step.advice, AppColors.successBg, AppColors.success),
        ],
      ),
    );
  }

  Widget _arrow() => Padding(
        padding: const EdgeInsets.only(left: 18, top: 4, bottom: 4),
        child: Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.grey.shade300),
      );

  Widget _node(IconData icon, String label, String value, Color bg, Color fg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
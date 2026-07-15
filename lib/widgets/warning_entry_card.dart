import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/reasoning_chain_parser.dart';

class WarningEntryCard extends StatelessWidget {
  final ReasoningChainStep step;
  const WarningEntryCard({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final accent = step.isSevere ? AppColors.danger : AppColors.warning;
    final accentBg = step.isSevere ? AppColors.dangerBg : AppColors.warningBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(step.isSevere ? Icons.error_outline : Icons.info_outline, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(step.medication,
                    style: TextStyle(fontWeight: FontWeight.w700, color: accent, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(step.risk,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medication_liquid_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(step.advice,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
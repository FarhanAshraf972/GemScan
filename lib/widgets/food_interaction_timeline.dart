import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/drug_matcher.dart';

class FoodInteractionTimeline extends StatelessWidget {
  final List<LabeledFoodInteraction> entries;

  const FoodInteractionTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text("Food & Timing Notes",
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 16)),
        ),
        ...entries.map((e) => _TimelineCard(labeled: e)),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final LabeledFoodInteraction labeled;
  const _TimelineCard({required this.labeled});

  @override
  Widget build(BuildContext context) {
    final entry = labeled.entry;
    final accent = entry.isWarning ? AppColors.warning : AppColors.info;
    final accentBg = entry.isWarning ? AppColors.warningBg : AppColors.infoBg;
    final ingredientLabel = labeled.ingredient[0].toUpperCase() + labeled.ingredient.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(entry.isWarning ? Icons.warning_amber_rounded : Icons.info_outline, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${entry.food} — because of $ingredientLabel',
                    style: TextStyle(fontWeight: FontWeight.w700, color: accent, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(entry.effect, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(entry.instruction,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: accent)),
          ),
        ],
      ),
    );
  }
}
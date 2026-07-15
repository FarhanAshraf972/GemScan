import 'drug_knowledge_base.dart';

class DrugMatch {
  final String sourceLabel;
  final String? brandName;
  final List<String> ingredients;

  DrugMatch({required this.sourceLabel, this.brandName, required this.ingredients});
}

class DuplicateIngredientResult {
  final String ingredient;
  final List<String> sources;

  DuplicateIngredientResult({required this.ingredient, required this.sources});
}

class LabeledFoodInteraction {
  final String ingredient;
  final FoodInteractionEntry entry;
  LabeledFoodInteraction(this.ingredient, this.entry);
}

const Map<String, String> _ocrCharFixups = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ľ': 'l', 'ĺ': 'l', 'ł': 'l',
  'č': 'c', 'ć': 'c', 'ç': 'c',
  'š': 's', 'ś': 's',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
  'ř': 'r', 'ď': 'd', 'đ': 'd', 'ť': 't', 'ň': 'n', 'ñ': 'n',
};

String normalizeOcrText(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_ocrCharFixups[char] ?? char);
  }
  return buffer.toString();
}

String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Each entry in [ocrSessions] is now guaranteed to be ONE physical
/// product (the capture screen preserves that boundary explicitly via a
/// delimiter), so a simple whole-text sweep per session is reliable —
/// no more heuristic line-by-line brand-switch guessing needed.
List<DrugMatch> extractDrugMatches(List<String> ocrSessions) {
  final matches = <DrugMatch>[];
  final sortedBrands = brandToIngredients.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length)); // longest match first

  for (var i = 0; i < ocrSessions.length; i++) {
    final lowerText = normalizeOcrText(ocrSessions[i]);
    final foundIngredients = <String>{};
    String? matchedBrand;

    for (final brand in sortedBrands) {
      if (lowerText.contains(brand)) {
        matchedBrand = brand;
        foundIngredients.addAll(brandToIngredients[brand]!);
        break;
      }
    }

    for (final ingredient in knownIngredients) {
      if (lowerText.contains(ingredient)) {
        foundIngredients.add(ingredient);
      }
    }

    if (foundIngredients.isNotEmpty) {
      matches.add(DrugMatch(
        sourceLabel: 'Scan ${i + 1}',
        brandName: matchedBrand,
        ingredients: foundIngredients.toList(),
      ));
    }
  }

  return matches;
}

List<DuplicateIngredientResult> findDuplicateIngredients(List<DrugMatch> matches) {
  final ingredientToSources = <String, List<String>>{};

  for (final match in matches) {
    for (final ingredient in match.ingredients) {
      ingredientToSources.putIfAbsent(ingredient, () => []).add(match.sourceLabel);
    }
  }

  return ingredientToSources.entries
      .where((entry) => entry.value.toSet().length > 1)
      .map((entry) => DuplicateIngredientResult(
            ingredient: entry.key,
            sources: entry.value.toSet().toList(),
          ))
      .toList();
}

List<LabeledFoodInteraction> findFoodInteractions(List<DrugMatch> matches) {
  final seen = <String>{};
  final results = <LabeledFoodInteraction>[];

  for (final match in matches) {
    for (final ingredient in match.ingredients) {
      final entries = foodInteractionsByIngredient[ingredient];
      if (entries == null) continue;
      for (final entry in entries) {
        final key = '$ingredient-${entry.food}';
        if (seen.contains(key)) continue;
        seen.add(key);
        results.add(LabeledFoodInteraction(ingredient, entry));
      }
    }
  }

  return results;
}

/// Ground-truth dose ceilings for whatever ingredients were recognized —
/// handed to the AI as the ONLY numbers it's allowed to cite.
String buildDoseLimitContext(List<DrugMatch> matches) {
  final seen = <String>{};
  final lines = <String>[];

  for (final match in matches) {
    for (final ingredient in match.ingredients) {
      if (seen.contains(ingredient)) continue;
      final limit = maxDailyDoseByIngredient[ingredient];
      if (limit == null) continue;
      seen.add(ingredient);
      lines.add(
        '${_titleCase(ingredient)}: max ${limit.maxDailyMgHealthyAdult}mg/24h for a healthy adult. ${limit.cautionNote}',
      );
    }
  }

  return lines.isEmpty ? "No dose-limit data available for these medications." : lines.join('\n');
}

String buildRecognizedMedicationSummary(List<DrugMatch> matches) {
  if (matches.isEmpty) return "No recognized medications.";
  return matches.map((m) {
    final brand = m.brandName != null ? _titleCase(m.brandName!) : "Unidentified item";
    return '${m.sourceLabel}: $brand (${m.ingredients.join(", ")})';
  }).join('\n');
}
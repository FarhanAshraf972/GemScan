/// Starter knowledge base for common medications in the Pakistani
/// pharmacopeia. Expand these maps with more brands/ingredients before a
/// live demo if you expect to scan medications not listed here.
///
/// Kept fully deterministic and separate from the AI — duplicate-ingredient
/// detection and food interactions are factual lookups, not judgment calls,
/// so they belong in plain Dart rather than risking a small on-device model
/// misremembering a specific fact.

class DoseLimit {
  final int maxDailyMgHealthyAdult;
  final String cautionNote;
  const DoseLimit({required this.maxDailyMgHealthyAdult, required this.cautionNote});
}

/// Deterministic dose ceilings. The AI is instructed to use ONLY these
/// numbers and never invent its own — same reasoning as food interactions:
/// exact factual thresholds are not something a 2B on-device model should
/// be trusted to recall correctly, especially adjusted for age/condition.
const Map<String, DoseLimit> maxDailyDoseByIngredient = {
  'paracetamol': DoseLimit(
    maxDailyMgHealthyAdult: 3000,
    cautionNote: 'Ask a doctor about a lower daily limit if over 65, or if there is liver disease or kidney disease',
  ),
  'ibuprofen': DoseLimit(
    maxDailyMgHealthyAdult: 1200,
    cautionNote: 'Ask a doctor before use if over 65, or if there is kidney disease.',
  ),
  'aspirin': DoseLimit(
    maxDailyMgHealthyAdult: 3000,
    cautionNote: 'Ask a doctor before use if there is a bleeding risk or stomach ulcer history.',
  ),
};

/// Brand name (lowercase) -> active ingredient(s) (lowercase).
const Map<String, List<String>> brandToIngredients = {
  'panadol': ['paracetamol'],
  'panadol extra': ['paracetamol', 'caffeine'],
  'calpol': ['paracetamol'],
  'brufen': ['ibuprofen'],
  'ponstan': ['mefenamic acid'],
  'disprin': ['aspirin'],
  'voltral': ['diclofenac'],
  'voltaren': ['diclofenac'],
  'flagyl': ['metronidazole'],
  'panstan': ['pantoprazole'],
  'pantoprazole': ['pantoprazole'],
  'augmentin': ['amoxicillin', 'clavulanate'],
  'ciproxin': ['ciprofloxacin'],
  'glucophage': ['metformin'],
  'norvasc': ['amlodipine'],
  'lipitor': ['atorvastatin'],
  'coumadin': ['warfarin'],
};

/// Active ingredients that may appear directly in OCR text on their own.
const List<String> knownIngredients = [
  'paracetamol', 'acetaminophen', 'ibuprofen', 'aspirin', 'diclofenac',
  'mefenamic acid', 'metronidazole', 'pantoprazole', 'omeprazole',
  'amoxicillin', 'ciprofloxacin', 'metformin', 'caffeine',
  'losartan', 'amlodipine', 'atorvastatin', 'warfarin',
];

class FoodInteractionEntry {
  final String food;
  final String effect;
  final String instruction;
  final bool isWarning; // true = risk/avoid, false = helpful usage tip

  const FoodInteractionEntry({
    required this.food,
    required this.effect,
    required this.instruction,
    this.isWarning = true,
  });
}

/// Ingredient (lowercase) -> known food interactions. Each ingredient key
/// appears exactly ONCE — multiple interactions for the same drug go in
/// that key's list, not in a second copy of the key (Dart const maps
/// can't have duplicate keys at all).
const Map<String, List<FoodInteractionEntry>> foodInteractionsByIngredient = {
  'atorvastatin': [
    FoodInteractionEntry(
      food: 'Grapefruit',
      effect: 'Raises drug concentration in your blood',
      instruction: "Avoid grapefruit or grapefruit juice entirely",
    ),
  ],
  'paracetamol': [
    FoodInteractionEntry(
      food: 'Alcohol',
      effect: 'Increases risk of liver damage',
      instruction: 'Avoid alcohol while taking this',
    ),
    FoodInteractionEntry(
      food: 'Meals',
      effect: 'No major food restriction',
      instruction: 'Can be taken with or without food',
      isWarning: false,
    ),
  ],
  'metronidazole': [
    FoodInteractionEntry(
      food: 'Alcohol',
      effect: 'Can cause a severe reaction — flushing, vomiting, fast heartbeat',
      instruction: 'Avoid alcohol completely during and 2 days after',
    ),
    FoodInteractionEntry(
      food: 'Meals',
      effect: 'Reduces stomach upset and nausea',
      instruction: 'Take with a meal or snack',
      isWarning: false,
    ),
  ],
  'caffeine': [
    FoodInteractionEntry(
      food: 'Tea / Coffee',
      effect: 'Adds to the caffeine already in this medicine',
      instruction: 'Avoid extra tea/coffee the same day',
    ),
    FoodInteractionEntry(
      food: 'Evening dosing',
      effect: 'Can disrupt sleep',
      instruction: 'Avoid taking in the late afternoon or evening',
    ),
  ],
  'amoxicillin': [
    FoodInteractionEntry(
      food: 'Meals',
      effect: 'Food may reduce stomach upset',
      instruction: 'Take with food if it upsets your stomach',
      isWarning: false,
    ),
  ],
  'metformin': [
    FoodInteractionEntry(
      food: 'Meals',
      effect: 'Reduces nausea and stomach upset',
      instruction: 'Take with meals',
      isWarning: false,
    ),
  ],
  'aspirin': [
    FoodInteractionEntry(
      food: 'Food or milk',
      effect: 'Protects your stomach lining',
      instruction: 'Take with food or milk, not on an empty stomach',
      isWarning: false,
    ),
  ],
  'ciprofloxacin': [
    FoodInteractionEntry(
      food: 'Milk / Dairy',
      effect: 'Blocks the drug from being absorbed',
      instruction: "Don't take within 2 hours of dairy",
    ),
  ],
  'warfarin': [
    FoodInteractionEntry(
      food: 'Leafy greens (spinach, kale)',
      effect: 'Can reduce how well the drug thins your blood',
      instruction: "Keep intake consistent — don't suddenly increase or drop it",
    ),
  ],
  'ibuprofen': [
    FoodInteractionEntry(
      food: 'Empty stomach',
      effect: 'Can irritate your stomach lining',
      instruction: 'Always take with food',
      isWarning: false,
    ),
  ],
  'diclofenac': [
    FoodInteractionEntry(
      food: 'Empty stomach',
      effect: 'Can irritate your stomach lining',
      instruction: 'Always take with food',
      isWarning: false,
    ),
  ],
  'pantoprazole': [
    FoodInteractionEntry(
      food: 'Meal timing',
      effect: 'Works best when absorbed before food arrives',
      instruction: 'Take 30-60 minutes before a meal',
      isWarning: false,
    ),
  ],
  'omeprazole': [
    FoodInteractionEntry(
      food: 'Meal timing',
      effect: 'Works best when absorbed before food arrives',
      instruction: 'Take 30-60 minutes before a meal',
      isWarning: false,
    ),
  ],
};
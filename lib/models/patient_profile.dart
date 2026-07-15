class PatientProfile {
  final String name;
  final int? age;
  final List<String> conditions;
  final String pregnancyStatus;
  final String allergies;
  final String otherMedicines;
  final String sleepSchedule;

  const PatientProfile({
    this.name = "",
    this.age,
    this.conditions = const [],
    this.pregnancyStatus = "Not Applicable",
    this.allergies = "",
    this.otherMedicines = "",
    this.sleepSchedule = "",
  });

  factory PatientProfile.empty() => const PatientProfile();

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'conditions': conditions,
        'pregnancyStatus': pregnancyStatus,
        'allergies': allergies,
        'otherMedicines': otherMedicines,
        'sleepSchedule': sleepSchedule,
      };

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
        name: json['name'] as String? ?? "",
        age: json['age'] as int?,
        conditions: List<String>.from(json['conditions'] ?? const []),
        pregnancyStatus: json['pregnancyStatus'] as String? ?? "Not Applicable",
        allergies: json['allergies'] as String? ?? "",
        otherMedicines: json['otherMedicines'] as String? ?? "",
        sleepSchedule: json['sleepSchedule'] as String? ?? "",
      );

  String toCompactSummary() {
    final parts = <String>[];
    if (age != null) parts.add('Age:$age');
    if (conditions.isNotEmpty) parts.add('Conditions:${conditions.join(",")}');
    if (pregnancyStatus != "Not Applicable") parts.add('Pregnant:$pregnancyStatus');
    if (allergies.trim().isNotEmpty) parts.add('Allergies:${allergies.trim()}');
    if (otherMedicines.trim().isNotEmpty) parts.add('Other meds:${otherMedicines.trim()}');
    if (sleepSchedule.trim().isNotEmpty) parts.add('Sleep:${sleepSchedule.trim()}');
    if (parts.isEmpty) return "No patient profile data provided.";
    return parts.join('; ');
  }
}
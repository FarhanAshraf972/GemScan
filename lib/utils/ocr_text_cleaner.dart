/// Cleans and trims raw OCR output before it enters the token budget.
String cleanAndTrimOcrText(String rawOcrText, {int maxChars = 350}) {
  if (rawOcrText.trim().isEmpty) return '';

  final lines = rawOcrText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty);

  final seen = <String>{};
  final cleanedLines = <String>[];

  for (final line in lines) {
    final isMostlyDigits = RegExp(r'^[\d\-\s]{8,}$').hasMatch(line);
    final isMostlySymbols = RegExp(r'^[^a-zA-Z0-9]{3,}$').hasMatch(line);
    final isTooShortToMatter = line.length < 2;

    if (isMostlyDigits || isMostlySymbols || isTooShortToMatter) continue;

    final normalized = line.toLowerCase();
    if (seen.contains(normalized)) continue;
    seen.add(normalized);

    cleanedLines.add(line);
  }

  var result = cleanedLines.join('; ');

  if (result.length > maxChars) {
    result = '${result.substring(0, maxChars).trim()}...';
  }

  return result;
}
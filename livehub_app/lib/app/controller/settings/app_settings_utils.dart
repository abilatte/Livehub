List<String> normalizeOrderedKeys({
  required Iterable<String> storedKeys,
  required Iterable<String> validKeys,
}) {
  final normalized = <String>[];
  final seen = <String>{};
  final allowed = validKeys.toList();

  for (final key in storedKeys) {
    final value = key.trim();
    if (value.isEmpty || !allowed.contains(value) || !seen.add(value)) {
      continue;
    }
    normalized.add(value);
  }

  for (final key in allowed) {
    if (seen.add(key)) {
      normalized.add(key);
    }
  }

  return normalized;
}

List<String> normalizeShieldWords(Iterable<dynamic> values) {
  final words = <String>[];
  final existed = <String>{};

  for (final item in values) {
    final value = item.toString().trim();
    if (value.isEmpty || !existed.add(value)) {
      continue;
    }
    words.add(value);
  }

  return words;
}

int clampNonNegativeInt(int value) {
  return value < 0 ? 0 : value;
}

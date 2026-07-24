/// Named keyword shield preset (keywords only for LiveHub filter path).
class DanmuShieldPreset {
  final String name;
  final List<String> keywords;

  const DanmuShieldPreset({
    required this.name,
    required this.keywords,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'keywords': keywords,
    };
  }

  factory DanmuShieldPreset.fromJson(Map<String, dynamic> json) {
    final rawKeywords = json['keywords'];
    final keywords = <String>[];
    if (rawKeywords is List) {
      for (final item in rawKeywords) {
        final value = item.toString().trim();
        if (value.isNotEmpty) {
          keywords.add(value);
        }
      }
    }
    return DanmuShieldPreset(
      name: (json['name'] ?? '').toString().trim(),
      keywords: keywords,
    );
  }
}

import 'dart:convert';

import '../../../models/danmu_shield_preset.dart';

/// Pure preset apply / serialize helpers (no Hive / GetX).
class DanmuShieldPresetUtils {
  /// Apply [preset] keywords as the new active shield set (deduped, trimmed).
  static List<String> applyPresetKeywords(DanmuShieldPreset preset) {
    return normalizeKeywordList(preset.keywords);
  }

  static List<String> normalizeKeywordList(Iterable<dynamic> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final item in values) {
      final value = item.toString().trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      result.add(value);
    }
    return result;
  }

  /// Build a preset snapshot from the current keyword list.
  static DanmuShieldPreset snapshotFromKeywords({
    required String name,
    required Iterable<String> keywords,
  }) {
    return DanmuShieldPreset(
      name: name.trim(),
      keywords: normalizeKeywordList(keywords),
    );
  }

  static String encodePresets(List<DanmuShieldPreset> presets) {
    return jsonEncode(presets.map((e) => e.toJson()).toList());
  }

  static List<DanmuShieldPreset> decodePresets(String raw) {
    if (raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final result = <DanmuShieldPreset>[];
      final seenNames = <String>{};
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final preset = DanmuShieldPreset.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (preset.name.isEmpty || !seenNames.add(preset.name)) {
          continue;
        }
        result.add(preset);
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// Upsert by name (replace keywords if name exists).
  static List<DanmuShieldPreset> upsertPreset(
    List<DanmuShieldPreset> current,
    DanmuShieldPreset preset,
  ) {
    if (preset.name.trim().isEmpty) {
      return List<DanmuShieldPreset>.from(current);
    }
    final next = <DanmuShieldPreset>[];
    var replaced = false;
    for (final item in current) {
      if (item.name == preset.name) {
        next.add(preset);
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) {
      next.add(preset);
    }
    return next;
  }

  static List<DanmuShieldPreset> removePresetByName(
    List<DanmuShieldPreset> current,
    String name,
  ) {
    return current.where((e) => e.name != name).toList();
  }
}

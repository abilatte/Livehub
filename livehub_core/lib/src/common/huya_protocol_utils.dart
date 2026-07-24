/// Pure Huya protocol helpers shared by [HuyaSite] (no network I/O).
class HuyaProtocolUtils {
  /// Coerce dynamic values into a non-negative int (0 if invalid).
  static int asPositiveInt(dynamic value) {
    if (value is int) {
      return value > 0 ? value : 0;
    }
    if (value is num) {
      final n = value.toInt();
      return n > 0 ? n : 0;
    }
    if (value is String) {
      final n = int.tryParse(value.trim());
      if (n != null && n > 0) {
        return n;
      }
    }
    return 0;
  }

  /// Walk [source] (maps/lists) for the first positive int under any of [keys].
  static int firstPositiveIntByKeys(
    dynamic source,
    List<String> keys, {
    int depth = 0,
  }) {
    if (source == null || depth > 6) {
      return 0;
    }
    if (source is Map) {
      for (final key in keys) {
        if (!source.containsKey(key)) {
          continue;
        }
        final direct = asPositiveInt(source[key]);
        if (direct > 0) {
          return direct;
        }
      }
      for (final value in source.values) {
        final nested = firstPositiveIntByKeys(value, keys, depth: depth + 1);
        if (nested > 0) {
          return nested;
        }
      }
    } else if (source is List) {
      for (final item in source) {
        final nested = firstPositiveIntByKeys(item, keys, depth: depth + 1);
        if (nested > 0) {
          return nested;
        }
      }
    }
    return 0;
  }

  /// Prefer topSid, then subSid, then profile room id for presenter/danmaku.
  static int resolvePresenterUid({
    required dynamic topSid,
    required dynamic subSid,
    dynamic profileRoomId,
  }) {
    final top = asPositiveInt(topSid);
    if (top > 0) {
      return top;
    }
    final sub = asPositiveInt(subSid);
    if (sub > 0) {
      return sub;
    }
    return asPositiveInt(profileRoomId);
  }

  /// Live when eLiveStatus == 2 (Huya convention).
  static bool isHuyaLiveStatus(dynamic eLiveStatus) {
    return asPositiveInt(eLiveStatus) == 2 || eLiveStatus == 2;
  }
}

/// Pure Douyin protocol helpers shared by [DouyinSite] (no network I/O).
class DouyinProtocolUtils {
  /// Parse a Cookie header into key/value pairs (last value wins on duplicate keys).
  static Map<String, String> parseCookieValue(String cookieValue) {
    final cookieMap = <String, String>{};
    for (final part in cookieValue.split(";")) {
      final item = part.trim();
      if (item.isEmpty) {
        continue;
      }
      final separatorIndex = item.indexOf("=");
      if (separatorIndex <= 0) {
        continue;
      }
      final key = item.substring(0, separatorIndex).trim();
      final value = item.substring(separatorIndex + 1).trim();
      if (key.isNotEmpty) {
        cookieMap[key] = value;
      }
    }
    return cookieMap;
  }

  /// Merge two cookie strings. When [preferBase] is true, base keys win.
  static String mergeCookieValues(
    String baseCookie,
    String extraCookie, {
    bool preferBase = false,
  }) {
    final base = parseCookieValue(baseCookie);
    final extra = parseCookieValue(extraCookie);
    final merged = preferBase ? {...extra, ...base} : {...base, ...extra};
    if (merged.isEmpty) {
      return "";
    }
    return merged.entries
        .map((entry) => "${entry.key}=${entry.value}")
        .join("; ");
  }

  static String getCookieHeaderValue(Map<String, dynamic> requestHeaders) {
    return (requestHeaders["Cookie"] ?? requestHeaders["cookie"] ?? "")
        .toString()
        .trim();
  }

  static String ensureCookieEndsWithSemicolon(String value) {
    final cookie = value.trim();
    if (cookie.isEmpty || cookie.endsWith(";")) {
      return cookie;
    }
    return "$cookie;";
  }

  /// Parse Douyin room status fields; live rooms typically use status == 2.
  static int? parseDouyinStatus(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    if (value is Map) {
      for (final key in const ["status", "live_status", "room_status"]) {
        final parsed = parseDouyinStatus(value[key]);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  /// Whether a room data map indicates the stream is live.
  static bool isDouyinLiveStatus(dynamic data) {
    if (data is! Map) {
      return false;
    }
    final candidates = <dynamic>[
      data["status"],
      data["live_status"],
      data["room_status"],
      data["status_str"],
    ];
    for (final candidate in candidates) {
      final parsed = parseDouyinStatus(candidate);
      if (parsed != null) {
        return parsed == 2;
      }
    }
    return false;
  }

  /// Heuristic: short ids are webRid, longer ones are one-shot roomId.
  static bool looksLikeWebRid(String roomId) {
    final value = roomId.trim();
    return value.isNotEmpty && value.length <= 16;
  }
}

/// Pure multi-room helpers (no Flutter widgets).
class MultiRoomUtils {
  /// Distinct room keys in insertion order. Key format: siteId_roomId.
  static List<String> distinctRoomKeys(Iterable<String> keys) {
    final result = <String>[];
    final seen = <String>{};
    for (final key in keys) {
      final value = key.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      result.add(value);
    }
    return result;
  }

  static String roomKey({required String siteId, required String roomId}) {
    return "${siteId.trim()}_${roomId.trim()}";
  }

  /// Grid column count for same-window monitoring layout.
  static int gridColumnCount({
    required int roomCount,
    required double maxWidth,
  }) {
    if (roomCount <= 1) {
      return 1;
    }
    if (maxWidth >= 1400 && roomCount >= 3) {
      return 3;
    }
    if (maxWidth >= 760) {
      return 2;
    }
    return 1;
  }

  /// Cap concurrent rooms for desktop multi-room to limit decoder load.
  static const int maxRooms = 6;

  static List<T> capRooms<T>(List<T> rooms, {int max = maxRooms}) {
    if (rooms.length <= max) {
      return List<T>.from(rooms);
    }
    return rooms.take(max).toList();
  }
}

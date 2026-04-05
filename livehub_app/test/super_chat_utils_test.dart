import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/super_chat_utils.dart';
import 'package:livehub_core/livehub_core.dart';

void main() {
  LiveSuperChatMessage buildMessage({
    String userName = 'user',
    String message = 'message',
    int price = 30,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return LiveSuperChatMessage(
      backgroundBottomColor: '#ffffff',
      backgroundColor: '#000000',
      endTime: endTime,
      face: 'face',
      message: message,
      price: price,
      startTime: startTime,
      userName: userName,
    );
  }

  group('buildSuperChatKey', () {
    test('同一条 SC 生成稳定键', () {
      final startTime = DateTime(2026, 3, 18, 12, 0, 0);
      final endTime = DateTime(2026, 3, 18, 12, 1, 0);
      final message = buildMessage(startTime: startTime, endTime: endTime);

      final key1 = buildSuperChatKey(message);
      final key2 = buildSuperChatKey(message);

      expect(key1, key2);
    });
  });

  group('remainingSuperChatSeconds', () {
    test('已过期 SC 返回 0 而不是负数', () {
      final now = DateTime(2026, 3, 18, 12, 0, 10);
      final sc = buildMessage(
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 0, 5),
      );

      expect(remainingSuperChatSeconds(sc, now: now), 0);
    });

    test('未过期 SC 返回真实剩余秒数', () {
      final now = DateTime(2026, 3, 18, 12, 0, 10);
      final sc = buildMessage(
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 0, 25),
      );

      expect(remainingSuperChatSeconds(sc, now: now), 15);
    });
  });

  group('resolveOverlayDisplaySeconds', () {
    test('浮层保留模式使用真实剩余秒数', () {
      final now = DateTime(2026, 3, 18, 12, 0, 10);
      final sc = buildMessage(
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 0, 40),
      );

      expect(
        resolveOverlayDisplaySeconds(sc, keepInOverlay: true, now: now),
        30,
      );
    });

    test('浮层非保留模式最多显示 15 秒', () {
      final now = DateTime(2026, 3, 18, 12, 0, 10);
      final sc = buildMessage(
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 1, 10),
      );

      expect(
        resolveOverlayDisplaySeconds(sc, keepInOverlay: false, now: now),
        15,
      );
    });

    test('浮层非保留模式对临界过期值做非负裁剪', () {
      final now = DateTime(2026, 3, 18, 12, 0, 10);
      final sc = buildMessage(
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 0, 9),
      );

      expect(
        resolveOverlayDisplaySeconds(sc, keepInOverlay: false, now: now),
        0,
      );
    });
  });

  group('sortSuperChatsForPage', () {
    test('SC页保留模式按发送时间从新到旧排序', () {
      final older = buildMessage(
        message: 'older',
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 10, 0),
      );
      final newer = buildMessage(
        message: 'newer',
        startTime: DateTime(2026, 3, 18, 12, 5, 0),
        endTime: DateTime(2026, 3, 18, 12, 15, 0),
      );

      final result = sortSuperChatsForPage(
        [older, newer],
        keepInPage: true,
      );

      expect(result.map((e) => e.message).toList(), ['newer', 'older']);
    });

    test('SC页非保留模式保持原始顺序', () {
      final first = buildMessage(
        message: 'first',
        startTime: DateTime(2026, 3, 18, 12, 0, 0),
        endTime: DateTime(2026, 3, 18, 12, 10, 0),
      );
      final second = buildMessage(
        message: 'second',
        startTime: DateTime(2026, 3, 18, 12, 5, 0),
        endTime: DateTime(2026, 3, 18, 12, 15, 0),
      );

      final result = sortSuperChatsForPage(
        [first, second],
        keepInPage: false,
      );

      expect(result.map((e) => e.message).toList(), ['first', 'second']);
    });
  });
}

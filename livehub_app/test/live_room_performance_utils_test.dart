import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:livehub_app/modules/live_room/live_room_performance_utils.dart';

void main() {
  group('buildLiveRoomLookupKey', () {
    test('同一房间生成稳定索引键', () {
      expect(
        buildLiveRoomLookupKey('bilibili', '123'),
        buildLiveRoomLookupKey('bilibili', '123'),
      );
    });
  });

  group('expandHistoryVisibleCount', () {
    test('首次展开使用页大小', () {
      expect(
        expandHistoryVisibleCount(
            totalCount: 50, currentCount: 0, pageSize: 20),
        20,
      );
    });

    test('后续展开不超过总数', () {
      expect(
        expandHistoryVisibleCount(
          totalCount: 35,
          currentCount: 20,
          pageSize: 20,
        ),
        35,
      );
    });
  });

  group('shouldLoadMoreHistory', () {
    test('接近底部时触发加载更多', () {
      expect(shouldLoadMoreHistory(extentAfter: 120), isTrue);
      expect(shouldLoadMoreHistory(extentAfter: 999), isFalse);
    });
  });

  group('聊天自动跟随状态', () {
    test('仅在用户明显上翻且离底部较远时禁用自动跟随', () {
      expect(
        shouldDisableChatAutoScroll(
          extentAfter: 240,
          userScrollDirection: ScrollDirection.forward,
        ),
        isTrue,
      );
      expect(
        shouldDisableChatAutoScroll(
          extentAfter: 8,
          userScrollDirection: ScrollDirection.forward,
        ),
        isFalse,
      );
    });

    test('手动回到底部附近时自动恢复跟随', () {
      expect(
        shouldEnableChatAutoScroll(extentAfter: 12),
        isTrue,
      );
      expect(
        shouldEnableChatAutoScroll(extentAfter: 120),
        isFalse,
      );
    });
  });

  group('聊天列表裁剪策略', () {
    test('跟随模式保留较小窗口', () {
      expect(
        resolveChatMessageLimit(autoScrollDisabled: false),
        300,
      );
      expect(
        resolveChatTrimCount(
          nextCount: 320,
          autoScrollDisabled: false,
        ),
        20,
      );
    });

    test('查看历史模式保留更大窗口', () {
      expect(
        resolveChatMessageLimit(autoScrollDisabled: true),
        1200,
      );
      expect(
        resolveChatTrimCount(
          nextCount: 1210,
          autoScrollDisabled: true,
        ),
        10,
      );
    });

    test('用户自定义保留数量时覆盖默认策略', () {
      expect(
        resolveChatMessageLimit(
          autoScrollDisabled: true,
          customLimit: 520,
        ),
        520,
      );
      expect(
        resolveChatTrimCount(
          nextCount: 600,
          autoScrollDisabled: false,
          customLimit: 520,
        ),
        80,
      );
    });
  });

  group('SC 列表裁剪策略', () {
    test('普通模式保留较小窗口', () {
      expect(
        resolveSuperChatLimit(keepInPage: false),
        30,
      );
      expect(
        resolveSuperChatTrimCount(
          nextCount: 35,
          keepInPage: false,
        ),
        5,
      );
    });

    test('保留模式保留更大窗口', () {
      expect(
        resolveSuperChatLimit(keepInPage: true),
        120,
      );
      expect(
        resolveSuperChatTrimCount(
          nextCount: 140,
          keepInPage: true,
        ),
        20,
      );
    });

    test('用户自定义 SC 保留数量时覆盖默认策略', () {
      expect(
        resolveSuperChatLimit(
          keepInPage: true,
          customLimit: 66,
        ),
        66,
      );
      expect(
        resolveSuperChatTrimCount(
          nextCount: 80,
          keepInPage: false,
          customLimit: 66,
        ),
        14,
      );
    });
  });

  group('remainingOverlaySeconds', () {
    test('已过期返回 0', () {
      final now = DateTime(2026, 3, 18, 12, 0, 0);
      expect(
        remainingOverlaySeconds(
          now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        0,
      );
    });

    test('未过期返回向上取整的剩余秒数', () {
      final now = DateTime(2026, 3, 18, 12, 0, 0);
      expect(
        remainingOverlaySeconds(
          now.add(const Duration(milliseconds: 1500)),
          now: now,
        ),
        2,
      );
    });
  });
}

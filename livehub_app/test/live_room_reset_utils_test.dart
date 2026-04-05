import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_reset_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_sidebar_tab_utils.dart';

void main() {
  group('buildLiveRoomRecordId', () {
    test('会生成站点加房间号的通用记录 key', () {
      expect(
        buildLiveRoomRecordId('bilibili', '12345'),
        'bilibili_12345',
      );
    });
  });

  group('buildLiveRoomFollowLookupKey', () {
    test('关注查询 key 复用通用记录 key 规则', () {
      expect(
        buildLiveRoomFollowLookupKey('bilibili', '12345'),
        'bilibili_12345',
      );
    });
  });

  group('resolveLiveRoomSwitchPlan', () {
    test('同房间重复进入时不触发重置', () {
      final plan = resolveLiveRoomSwitchPlan(
        currentSiteId: 'bilibili',
        currentRoomId: '12345',
        nextSiteId: 'bilibili',
        nextRoomId: '12345',
        currentSidebarTab: LiveRoomSidebarTab.chat,
      );

      expect(plan.shouldReset, isFalse);
      expect(plan.nextSidebarTab, LiveRoomSidebarTab.chat);
      expect(plan.nextFollowLookupKey, 'bilibili_12345');
    });

    test('切换到其他房间时会触发重置并更新关注 key', () {
      final plan = resolveLiveRoomSwitchPlan(
        currentSiteId: 'bilibili',
        currentRoomId: '12345',
        nextSiteId: 'douyin',
        nextRoomId: '67890',
        currentSidebarTab: LiveRoomSidebarTab.follow,
      );

      expect(plan.shouldReset, isTrue);
      expect(plan.nextSidebarTab, LiveRoomSidebarTab.follow);
      expect(plan.nextFollowLookupKey, 'douyin_67890');
    });

    test('B站 SC tab 切到其他站点时回退到聊天 tab', () {
      final plan = resolveLiveRoomSwitchPlan(
        currentSiteId: 'bilibili',
        currentRoomId: '12345',
        nextSiteId: 'douyin',
        nextRoomId: '67890',
        currentSidebarTab: LiveRoomSidebarTab.superChat,
      );

      expect(plan.shouldReset, isTrue);
      expect(plan.nextSidebarTab, LiveRoomSidebarTab.chat);
      expect(plan.nextFollowLookupKey, 'douyin_67890');
    });
  });
}

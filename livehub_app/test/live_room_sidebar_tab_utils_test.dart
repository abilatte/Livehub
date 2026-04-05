import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_sidebar_tab_utils.dart';

void main() {
  group('liveRoomSidebarTabFromIndex', () {
    test('B站索引映射为语义 tab', () {
      expect(
        liveRoomSidebarTabFromIndex(0, hasSuperChatTab: true),
        LiveRoomSidebarTab.chat,
      );
      expect(
        liveRoomSidebarTabFromIndex(1, hasSuperChatTab: true),
        LiveRoomSidebarTab.superChat,
      );
      expect(
        liveRoomSidebarTabFromIndex(2, hasSuperChatTab: true),
        LiveRoomSidebarTab.follow,
      );
      expect(
        liveRoomSidebarTabFromIndex(3, hasSuperChatTab: true),
        LiveRoomSidebarTab.settings,
      );
    });

    test('其他平台索引映射为语义 tab', () {
      expect(
        liveRoomSidebarTabFromIndex(0, hasSuperChatTab: false),
        LiveRoomSidebarTab.chat,
      );
      expect(
        liveRoomSidebarTabFromIndex(1, hasSuperChatTab: false),
        LiveRoomSidebarTab.follow,
      );
      expect(
        liveRoomSidebarTabFromIndex(2, hasSuperChatTab: false),
        LiveRoomSidebarTab.settings,
      );
    });
  });

  group('liveRoomSidebarTabToIndex', () {
    test('关注 tab 在不同平台都映射到正确索引', () {
      expect(
        liveRoomSidebarTabToIndex(
          LiveRoomSidebarTab.follow,
          hasSuperChatTab: true,
        ),
        2,
      );
      expect(
        liveRoomSidebarTabToIndex(
          LiveRoomSidebarTab.follow,
          hasSuperChatTab: false,
        ),
        1,
      );
    });

    test('设置 tab 在不同平台都映射到正确索引', () {
      expect(
        liveRoomSidebarTabToIndex(
          LiveRoomSidebarTab.settings,
          hasSuperChatTab: true,
        ),
        3,
      );
      expect(
        liveRoomSidebarTabToIndex(
          LiveRoomSidebarTab.settings,
          hasSuperChatTab: false,
        ),
        2,
      );
    });
  });

  group('resolveLiveRoomSidebarTabForSite', () {
    test('B站关注切其他平台后仍保持关注语义', () {
      const currentTab = LiveRoomSidebarTab.follow;
      final nextTab = resolveLiveRoomSidebarTabForSite(
        currentTab,
        hasSuperChatTab: false,
      );

      expect(nextTab, LiveRoomSidebarTab.follow);
      expect(liveRoomSidebarTabToIndex(nextTab, hasSuperChatTab: false), 1);
    });

    test('其他平台关注切B站后仍保持关注语义', () {
      const currentTab = LiveRoomSidebarTab.follow;
      final nextTab = resolveLiveRoomSidebarTabForSite(
        currentTab,
        hasSuperChatTab: true,
      );

      expect(nextTab, LiveRoomSidebarTab.follow);
      expect(liveRoomSidebarTabToIndex(nextTab, hasSuperChatTab: true), 2);
    });

    test('B站SC切到其他平台时回退到聊天', () {
      final nextTab = resolveLiveRoomSidebarTabForSite(
        LiveRoomSidebarTab.superChat,
        hasSuperChatTab: false,
      );

      expect(nextTab, LiveRoomSidebarTab.chat);
      expect(liveRoomSidebarTabToIndex(nextTab, hasSuperChatTab: false), 0);
    });
  });
}

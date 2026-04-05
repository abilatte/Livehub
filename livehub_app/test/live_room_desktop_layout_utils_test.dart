import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_desktop_layout_utils.dart';

void main() {
  group('shouldUseDesktopLiveRoomLayout', () {
    test('桌面平台且宽度足够时启用桌面布局', () {
      expect(
        shouldUseDesktopLiveRoomLayout(
          width: 1280,
          isDesktopPlatform: true,
        ),
        isTrue,
      );
    });

    test('非桌面平台不启用桌面布局', () {
      expect(
        shouldUseDesktopLiveRoomLayout(
          width: 1600,
          isDesktopPlatform: false,
        ),
        isFalse,
      );
    });

    test('宽度不足时不启用桌面布局', () {
      expect(
        shouldUseDesktopLiveRoomLayout(
          width: 1024,
          isDesktopPlatform: true,
        ),
        isFalse,
      );
    });
  });

  group('resolveDesktopSidebarWidth', () {
    test('较窄窗口使用新的默认最小宽度', () {
      expect(resolveDesktopSidebarWidth(1200), 280);
    });

    test('较宽窗口默认宽度会被收窄', () {
      expect(resolveDesktopSidebarWidth(1600), 304);
    });

    test('超宽窗口使用新的默认最大宽度', () {
      expect(resolveDesktopSidebarWidth(2200), 320);
    });

    test('用户自定义宽度时优先使用输入值', () {
      expect(
        resolveDesktopSidebarWidth(1600, customWidth: 330),
        330,
      );
    });

    test('用户自定义宽度会被限制到安全范围', () {
      expect(
        resolveDesktopSidebarWidth(1600, customWidth: 999),
        360,
      );
    });
  });

  group('resolveDesktopSidebarWidthHint', () {
    test('为空时提示默认宽度', () {
      expect(
        resolveDesktopSidebarWidthHint(1600),
        '默认宽度：304',
      );
    });
  });

  group('shouldShowDesktopSidebar', () {
    test('铺满窗口时自动隐藏右侧栏', () {
      expect(
        shouldShowDesktopSidebar(fillWindowState: true),
        isFalse,
      );
    });

    test('普通窗口时显示右侧栏', () {
      expect(
        shouldShowDesktopSidebar(fillWindowState: false),
        isTrue,
      );
    });
  });
}

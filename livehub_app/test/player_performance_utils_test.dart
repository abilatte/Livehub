import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/player/player_performance_utils.dart';

void main() {
  group('resolvePlayerControlLayoutMode', () {
    test('正在进入全屏时提前切到全屏布局', () {
      expect(
        resolvePlayerControlLayoutMode(
          nativeFullScreenState: false,
          enteringFullScreenState: true,
          smallWindowState: false,
        ),
        PlayerControlLayoutMode.fullScreen,
      );
    });

    test('非全屏且无过渡态时保持普通布局', () {
      expect(
        resolvePlayerControlLayoutMode(
          nativeFullScreenState: false,
          enteringFullScreenState: false,
          smallWindowState: false,
        ),
        PlayerControlLayoutMode.normal,
      );
    });

    test('桌面小窗也应使用全屏控制布局', () {
      expect(
        resolvePlayerControlLayoutMode(
          nativeFullScreenState: false,
          enteringFullScreenState: false,
          smallWindowState: true,
        ),
        PlayerControlLayoutMode.fullScreen,
      );
    });
  });

  group('shouldEnableVerbosePlayerStreamLogging', () {
    test('仅在调试模式且日志开关开启时启用详细日志', () {
      expect(
        shouldEnableVerbosePlayerStreamLogging(
          logEnabled: true,
          isDebugMode: true,
        ),
        isTrue,
      );
      expect(
        shouldEnableVerbosePlayerStreamLogging(
          logEnabled: true,
          isDebugMode: false,
        ),
        isFalse,
      );
      expect(
        shouldEnableVerbosePlayerStreamLogging(
          logEnabled: false,
          isDebugMode: true,
        ),
        isFalse,
      );
    });
  });

  group('hasPlayerVideoSizeChanged', () {
    test('尺寸未变化时返回 false', () {
      expect(
        hasPlayerVideoSizeChanged(
          previousWidth: 1920,
          previousHeight: 1080,
          nextWidth: 1920,
          nextHeight: 1080,
        ),
        isFalse,
      );
    });

    test('宽高任一变化时返回 true', () {
      expect(
        hasPlayerVideoSizeChanged(
          previousWidth: 1920,
          previousHeight: 1080,
          nextWidth: 1280,
          nextHeight: 720,
        ),
        isTrue,
      );
    });
  });

  group('resolveIsVerticalLiveRoom', () {
    test('宽高异常时回退为之前状态', () {
      expect(
        resolveIsVerticalLiveRoom(
          width: null,
          height: 720,
          fallback: true,
        ),
        isTrue,
      );
      expect(
        resolveIsVerticalLiveRoom(
          width: 0,
          height: 720,
          fallback: false,
        ),
        isFalse,
      );
    });

    test('根据宽高计算直播间方向', () {
      expect(
        resolveIsVerticalLiveRoom(
          width: 720,
          height: 1280,
          fallback: false,
        ),
        isTrue,
      );
      expect(
        resolveIsVerticalLiveRoom(
          width: 1920,
          height: 1080,
          fallback: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldShowDesktopControlsOnHover', () {
    test('鼠标位于顶部或底部热区时显示控制条', () {
      expect(
        shouldShowDesktopControlsOnHover(
          localDy: 12,
          viewportHeight: 800,
        ),
        isTrue,
      );
      expect(
        shouldShowDesktopControlsOnHover(
          localDy: 790,
          viewportHeight: 800,
        ),
        isTrue,
      );
    });

    test('鼠标位于中间区域时不主动显示控制条', () {
      expect(
        shouldShowDesktopControlsOnHover(
          localDy: 400,
          viewportHeight: 800,
        ),
        isFalse,
      );
    });
  });
}

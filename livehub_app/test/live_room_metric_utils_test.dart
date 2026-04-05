import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_core/livehub_core.dart';
import 'package:livehub_app/modules/live_room/live_room_metric_utils.dart';

void main() {
  group('buildBilibiliMetricText', () {
    test('优先显示弹幕推送的在线文案并拼接大航海', () {
      final result = buildBilibiliMetricText(
        roomAudienceText: '1万+',
        online: 9876,
        captainText: '大航海 88',
      );

      expect(result, '1万+ · 大航海 88');
    });

    test('没有弹幕在线文案时回退到静态在线人数', () {
      final result = buildBilibiliMetricText(
        roomAudienceText: '',
        online: 12345,
        captainText: '大航海 66',
      );

      expect(result, '1.2万 · 大航海 66');
    });

    test('只有大航海时仍然显示大航海', () {
      final result = buildBilibiliMetricText(
        roomAudienceText: '',
        online: 0,
        captainText: '大航海 12',
      );

      expect(result, '大航海 12');
    });
  });

  group('弹幕降级状态', () {
    test('空弹幕参数时不应继续启动弹幕连接', () {
      final unavailable = BiliBiliDanmakuUnavailable(
        roomId: 123,
        reason: '弹幕参数读取失败，本次仅播放视频',
        retryCount: 3,
      );

      expect(shouldStartDanmaku(unavailable), isFalse);
      expect(resolveDanmakuStatusMessage(unavailable), '弹幕参数读取失败，本次仅播放视频');
    });

    test('正常弹幕参数时允许继续启动弹幕连接', () {
      final args = BiliBiliDanmakuArgs(
        roomId: 123,
        token: 'token',
        serverHost: 'broadcastlv.chat.bilibili.com',
        buvid: 'buvid',
        uid: 1,
        cookie: '',
      );

      expect(shouldStartDanmaku(args), isTrue);
      expect(resolveDanmakuStatusMessage(args), '弹幕参数读取失败，本次仅播放视频');
    });
  });
}

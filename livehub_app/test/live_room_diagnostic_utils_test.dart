import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_diagnostic_utils.dart';

void main() {
  group('buildLiveRoomPlayerSettingContext', () {
    test('会按原结构输出播放器设置字段', () {
      final context = buildLiveRoomPlayerSettingContext(
        customPlayerOutput: true,
        videoOutputDriver: 'libmpv',
        audioOutputDriver: 'wasapi',
        videoHardwareDecoder: 'auto',
        logEnabled: true,
        scaleMode: 2,
      );

      expect(context, <String, dynamic>{
        'customPlayerOutput': true,
        'videoOutputDriver': 'libmpv',
        'audioOutputDriver': 'wasapi',
        'videoHardwareDecoder': 'auto',
        'logEnabled': true,
        'scaleMode': 2,
      });
    });
  });

  group('buildLiveRoomDiagnosticContext', () {
    test('会保留诊断包上下文需要的关键字段', () {
      final context = buildLiveRoomDiagnosticContext(
        siteId: 'bilibili',
        siteName: '哔哩哔哩',
        roomId: '12345',
        roomTitle: '测试直播间',
        anchor: '主播A',
        url: 'https://example.com',
        liveStatus: true,
        currentQuality: '原画',
        currentLine: '线路1',
        online: 9527,
        roomAudienceText: '1万+',
        errorType: 'network',
        errorTitle: '网络连接异常',
        errorSummary: '接口超时',
        errorSuggestion: '稍后重试',
        playerSetting: <String, dynamic>{'scaleMode': 1},
        errorDetail: 'detail',
      );

      expect(context['scope'], 'live_room');
      expect(context['siteId'], 'bilibili');
      expect(context['roomTitle'], '测试直播间');
      expect(context['playerSetting'], <String, dynamic>{'scaleMode': 1});
      expect(context['errorDetail'], 'detail');
    });
  });

  group('buildLiveRoomErrorDetailText', () {
    test('有房间文案时优先使用房间观看文案', () {
      final text = buildLiveRoomErrorDetailText(
        appVersion: '2.0.3+23',
        generatedAt: DateTime.parse('2026-04-05T12:34:56.000Z'),
        siteName: '哔哩哔哩',
        roomId: '12345',
        roomTitle: '测试直播间',
        anchor: '主播A',
        roomAudienceText: '1万+',
        online: 9527,
        errorTitle: '网络连接异常',
        errorType: 'network',
        errorSummary: '接口超时',
        errorSuggestion: '稍后重试',
        rawError: 'SocketException',
        rawStackTrace: 'stack line',
      );

      expect(text, contains('应用版本：2.0.3+23'));
      expect(text, contains('时间：2026-04-05T12:34:56.000Z'));
      expect(text, contains('观看信息：1万+'));
      expect(text, contains('错误分类：网络连接异常（network）'));
      expect(text, contains('SocketException'));
      expect(text, contains('stack line'));
    });

    test('房间观看文案为空时回退到在线人数', () {
      final text = buildLiveRoomErrorDetailText(
        appVersion: '2.0.3+23',
        generatedAt: DateTime.parse('2026-04-05T12:34:56.000Z'),
        siteName: '哔哩哔哩',
        roomId: '12345',
        roomAudienceText: '',
        online: 9527,
        errorTitle: '未知错误',
        errorType: 'unknown',
        errorSummary: 'summary',
        errorSuggestion: 'suggestion',
      );

      expect(text, contains('观看信息：9527'));
      expect(text, contains('房间标题：-'));
      expect(text, contains('主播：-'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_error_utils.dart';

void main() {
  group('resolveLiveRoomErrorPresentation', () {
    test('网络关键字归类为网络异常', () {
      final presentation = resolveLiveRoomErrorPresentation(
        Exception('SocketException: Connection timed out'),
      );

      expect(presentation.type, 'network');
      expect(presentation.title, '网络连接异常');
    });

    test('权限关键字归类为账号状态异常', () {
      final presentation = resolveLiveRoomErrorPresentation(
        Exception('401 unauthorized'),
      );

      expect(presentation.type, 'auth');
      expect(presentation.title, '账号状态或权限异常');
    });

    test('播放器关键字归类为播放器失败', () {
      final presentation = resolveLiveRoomErrorPresentation(
        Exception('media decoder init failed'),
      );

      expect(presentation.type, 'player');
      expect(presentation.title, '播放器初始化失败');
    });

    test('未知错误回退到通用文案', () {
      final presentation = resolveLiveRoomErrorPresentation(
        Exception('something weird happened'),
      );

      expect(presentation.type, 'unknown');
      expect(presentation.suggestion, contains('导出诊断包'));
    });
  });
}

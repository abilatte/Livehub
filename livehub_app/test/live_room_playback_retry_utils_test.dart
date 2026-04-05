import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_playback_utils.dart';

void main() {
  group('playback retry helpers', () {
    test('未达到最大重试次数时继续重试', () {
      expect(
        shouldRetryPlayback(retryCount: 0),
        isTrue,
      );
      expect(
        shouldRetryPlayback(retryCount: 1),
        isTrue,
      );
      expect(
        shouldRetryPlayback(retryCount: 2),
        isFalse,
      );
    });

    test('重试计数按次递增', () {
      expect(nextPlaybackRetryCount(0), 1);
      expect(nextPlaybackRetryCount(1), 2);
    });

    test('第二次重试前增加 1 秒延迟', () {
      expect(resolvePlaybackRetryDelay(0), Duration.zero);
      expect(
        resolvePlaybackRetryDelay(1),
        const Duration(seconds: 1),
      );
    });
  });
}

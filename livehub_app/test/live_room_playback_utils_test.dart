import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/live_room_playback_utils.dart';

void main() {
  group('resolveInitialQualityIndex', () {
    test('最高画质模式选择第一项', () {
      expect(
        resolveInitialQualityIndex(qualityCount: 5, qualityLevel: 2),
        0,
      );
    });

    test('最低画质模式选择最后一项', () {
      expect(
        resolveInitialQualityIndex(qualityCount: 5, qualityLevel: 0),
        4,
      );
    });

    test('默认模式选择中间项', () {
      expect(
        resolveInitialQualityIndex(qualityCount: 5, qualityLevel: 1),
        2,
      );
      expect(
        resolveInitialQualityIndex(qualityCount: 4, qualityLevel: 1),
        2,
      );
    });

    test('没有清晰度时回退为 -1', () {
      expect(
        resolveInitialQualityIndex(qualityCount: 0, qualityLevel: 1),
        -1,
      );
    });
  });

  group('buildLiveRoomLineLabel', () {
    test('线路标签从 1 开始显示', () {
      expect(buildLiveRoomLineLabel(0), '线路1');
      expect(buildLiveRoomLineLabel(2), '线路3');
    });
  });

  group('normalizePlaybackUrl', () {
    test('强制 https 时替换 http 链接', () {
      expect(
        normalizePlaybackUrl(
          'http://example.com/live.m3u8',
          forceHttps: true,
        ),
        'https://example.com/live.m3u8',
      );
    });

    test('非强制模式保留原链接', () {
      expect(
        normalizePlaybackUrl(
          'http://example.com/live.m3u8',
          forceHttps: false,
        ),
        'http://example.com/live.m3u8',
      );
    });
  });

  group('normalizePlaybackUrls', () {
    test('批量处理播放链接', () {
      expect(
        normalizePlaybackUrls(
          <String>[
            'http://a.example.com/1',
            'https://b.example.com/2',
          ],
          forceHttps: true,
        ),
        <String>[
          'https://a.example.com/1',
          'https://b.example.com/2',
        ],
      );
    });
  });

  group('hasNextPlayLine', () {
    test('还有下一条线路时返回 true', () {
      expect(
        hasNextPlayLine(currentLineIndex: 0, playUrlCount: 3),
        isTrue,
      );
    });

    test('已经是最后一条线路时返回 false', () {
      expect(
        hasNextPlayLine(currentLineIndex: 2, playUrlCount: 3),
        isFalse,
      );
    });
  });
}

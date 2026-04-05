import 'package:livehub_core/src/bilibili_site.dart';
import 'package:livehub_core/src/common/core_log.dart';
import 'package:livehub_core/src/danmaku/bilibili_danmaku.dart';
import 'package:test/test.dart';

void main() {
  group('bilibili fallback helpers', () {
    test('buildBilibiliAvatarUrl 会补全协议和缩略图后缀', () {
      expect(buildBilibiliAvatarUrl(""), "");
      expect(
        buildBilibiliAvatarUrl("//example.com/avatar.jpg"),
        "https://example.com/avatar.jpg@400w.jpg",
      );
      expect(
        buildBilibiliAvatarUrl("https://example.com/avatar.jpg@100w.jpg"),
        "https://example.com/avatar.jpg@100w.jpg",
      );
    });

    test('normalizeBilibiliLiveStartTime 会过滤空值和 0', () {
      expect(normalizeBilibiliLiveStartTime(null), isNull);
      expect(normalizeBilibiliLiveStartTime(""), isNull);
      expect(normalizeBilibiliLiveStartTime("0"), isNull);
      expect(normalizeBilibiliLiveStartTime(1774152406), "1774152406");
    });

    test('ensureBilibiliDanmuInfo 在 data 为空时返回安全结构', () {
      final result = ensureBilibiliDanmuInfo(null);

      expect(result["token"], "");
      expect(result["host_list"], isA<List<Map<String, dynamic>>>());
      expect((result["host_list"] as List), isEmpty);
    });

    test('空弹幕参数不会再生成可连接的 B站弹幕数据', () {
      final payload = buildBilibiliDanmakuPayload(
        roomId: '22637261',
        uid: 123,
        buvid: 'buvid',
        cookie: '',
        danmuInfo: ensureBilibiliDanmuInfo(null),
        retryCount: 3,
      );

      expect(payload, isA<BiliBiliDanmakuUnavailable>());
      expect(
        (payload as BiliBiliDanmakuUnavailable).reason,
        '弹幕参数读取失败，本次仅播放视频',
      );
    });

    test('有效弹幕参数会生成可连接的 B站弹幕数据', () {
      final payload = buildBilibiliDanmakuPayload(
        roomId: '22637261',
        uid: 123,
        buvid: 'buvid',
        cookie: 'cookie',
        danmuInfo: <String, dynamic>{
          'token': 'token',
          'host_list': <Map<String, dynamic>>[
            <String, dynamic>{'host': 'broadcastlv.chat.bilibili.com'},
          ],
        },
        retryCount: 1,
      );

      expect(payload, isA<BiliBiliDanmakuArgs>());
      expect((payload as BiliBiliDanmakuArgs).token, 'token');
      expect(payload.serverHost, 'broadcastlv.chat.bilibili.com');
    });

    test('语义空主路径结果会通过备用路径恢复弹幕参数', () async {
      final site = _TestBiliBiliSite(
        primaryDanmuInfoResponses: <Map<String, dynamic>>[
          _semanticEmptyDanmuInfo(),
        ],
        alternateDanmuInfoResponses: <Map<String, dynamic>>[_validDanmuInfo()],
      );

      final result = await site.getStableRoomDanmuInfo(
        roomId: '22637261',
        maxAttempts: 1,
      );

      expect(site.primaryDanmuInfoCallCount, 1);
      expect(site.alternateDanmuInfoCallCount, 1);
      expect(hasValidBilibiliDanmuInfo(result), isTrue);
      expect(result['token'], 'alt-token');
      expect(
        extractBilibiliDanmuHosts(result),
        contains('broadcastlv.chat.bilibili.com'),
      );
    });

    test('语义空主路径和备用路径都会保持不可用弹幕载荷', () async {
      final site = _TestBiliBiliSite(
        primaryDanmuInfoResponses: <Map<String, dynamic>>[
          _semanticEmptyDanmuInfo(),
        ],
        alternateDanmuInfoResponses: <Map<String, dynamic>>[
          _semanticEmptyDanmuInfo(),
        ],
      );

      final result = await site.getStableRoomDanmuInfo(
        roomId: '22637261',
        maxAttempts: 1,
      );
      final payload = buildBilibiliDanmakuPayload(
        roomId: '22637261',
        uid: 123,
        buvid: 'buvid',
        cookie: '',
        danmuInfo: result,
        retryCount: 1,
      );

      expect(site.primaryDanmuInfoCallCount, 1);
      expect(site.alternateDanmuInfoCallCount, 1);
      expect(hasValidBilibiliDanmuInfo(result), isFalse);
      expect(payload, isA<BiliBiliDanmakuUnavailable>());
      expect(
        (payload as BiliBiliDanmakuUnavailable).reason,
        '弹幕参数读取失败，本次仅播放视频',
      );
    });

    test('非语义空坏数据不会触发备用路径', () async {
      final site = _TestBiliBiliSite(
        primaryDanmuInfoResponses: <dynamic>[
          ensureBilibiliDanmuInfo(<String, dynamic>{
            'token': 'token-only',
            'host_list': <Map<String, dynamic>>[],
          }),
        ],
        alternateDanmuInfoResponses: <dynamic>[_validDanmuInfo()],
      );

      final result = await site.getStableRoomDanmuInfo(
        roomId: '22637261',
        maxAttempts: 1,
      );

      expect(site.primaryDanmuInfoCallCount, 1);
      expect(site.alternateDanmuInfoCallCount, 0);
      expect(hasValidBilibiliDanmuInfo(result), isFalse);
      expect(result['token'], 'token-only');
    });

    test('主路径抛错时不会触发备用路径', () async {
      final site = _TestBiliBiliSite(
        primaryDanmuInfoResponses: <dynamic>[StateError('boom')],
        alternateDanmuInfoResponses: <dynamic>[_validDanmuInfo()],
      );

      final result = await site.getStableRoomDanmuInfo(
        roomId: '22637261',
        maxAttempts: 1,
      );

      expect(site.primaryDanmuInfoCallCount, 1);
      expect(site.alternateDanmuInfoCallCount, 0);
      expect(hasValidBilibiliDanmuInfo(result), isFalse);
      expect(isSemanticEmptyBilibiliDanmuInfo(result), isTrue);
    });

    test('语义空恢复会输出备用路径日志', () async {
      final site = _TestBiliBiliSite(
        primaryDanmuInfoResponses: <dynamic>[_semanticEmptyDanmuInfo()],
        alternateDanmuInfoResponses: <dynamic>[_validDanmuInfo()],
      );
      final logs = <String>[];
      final previousOnPrintLog = CoreLog.onPrintLog;

      CoreLog.onPrintLog = (_, message) {
        logs.add(message);
      };

      try {
        await site.getStableRoomDanmuInfo(roomId: '22637261', maxAttempts: 1);
      } finally {
        CoreLog.onPrintLog = previousOnPrintLog;
      }

      expect(logs, contains(contains('B站弹幕参数语义空结果耗尽')));
      expect(logs, contains(contains('B站弹幕参数备用路径开始')));
      expect(logs, contains(contains('B站弹幕参数备用路径恢复')));
    });

    test('语义空最终失败会输出备用路径失败日志', () async {
      final site = _TestBiliBiliSite(
        primaryDanmuInfoResponses: <dynamic>[_semanticEmptyDanmuInfo()],
        alternateDanmuInfoResponses: <dynamic>[_semanticEmptyDanmuInfo()],
      );
      final logs = <String>[];
      final previousOnPrintLog = CoreLog.onPrintLog;

      CoreLog.onPrintLog = (_, message) {
        logs.add(message);
      };

      try {
        await site.getStableRoomDanmuInfo(roomId: '22637261', maxAttempts: 1);
      } finally {
        CoreLog.onPrintLog = previousOnPrintLog;
      }

      expect(logs, contains(contains('B站弹幕参数语义空结果耗尽')));
      expect(logs, contains(contains('B站弹幕参数备用路径开始')));
      expect(logs, contains(contains('B站弹幕参数备用路径最终失败')));
    });

    test('观看人数文案优先读取 watched_show 的 text_large', () {
      final watchedText = resolveBilibiliWatchedText(<String, dynamic>{
        'room_info': <String, dynamic>{
          'watched_show': <String, dynamic>{
            'text_large': '1.2万',
            'text_small': '1.1万',
          },
        },
      });

      expect(watchedText, '1.2万');
    });

    test('ensureBilibiliRoomInfo 在 room_info 缺失时用基础信息补齐', () {
      final result = ensureBilibiliRoomInfo(
        roomInfo: <String, dynamic>{},
        roomBaseInfo: <String, dynamic>{
          "room_id": 22637261,
          "uid": 672328094,
          "title": "测试标题",
          "description": "测试简介",
          "online": 12345,
          "live_status": 1,
          "live_start_time": 1774152406,
          "user_cover": "//example.com/cover.jpg",
          "uname": "测试主播",
          "face": "//example.com/avatar.jpg",
        },
        fallbackRoomId: "22637261",
      );

      expect(result["room_info"]["room_id"], 22637261);
      expect(result["room_info"]["title"], "测试标题");
      expect(result["room_info"]["cover"], "https://example.com/cover.jpg");
      expect(result["anchor_info"]["base_info"]["uid"], 672328094);
      expect(
        result["anchor_info"]["base_info"]["face"],
        "https://example.com/avatar.jpg",
      );
    });
  });
}

Map<String, dynamic> _semanticEmptyDanmuInfo() {
  return ensureBilibiliDanmuInfo(<String, dynamic>{
    'token': '',
    'host_list': <Map<String, dynamic>>[],
  });
}

Map<String, dynamic> _validDanmuInfo() {
  return ensureBilibiliDanmuInfo(<String, dynamic>{
    'token': 'alt-token',
    'host_list': <Map<String, dynamic>>[
      <String, dynamic>{'host': 'broadcastlv.chat.bilibili.com'},
    ],
  });
}

class _TestBiliBiliSite extends BiliBiliSite {
  _TestBiliBiliSite({
    required List<dynamic> primaryDanmuInfoResponses,
    required List<dynamic> alternateDanmuInfoResponses,
  }) : _primaryDanmuInfoResponses = List<dynamic>.from(
         primaryDanmuInfoResponses,
       ),
       _alternateDanmuInfoResponses = List<dynamic>.from(
         alternateDanmuInfoResponses,
       );

  final List<dynamic> _primaryDanmuInfoResponses;
  final List<dynamic> _alternateDanmuInfoResponses;

  int primaryDanmuInfoCallCount = 0;
  int alternateDanmuInfoCallCount = 0;

  @override
  Future<Map<String, dynamic>> getRoomDanmuInfo({
    required String roomId,
  }) async {
    primaryDanmuInfoCallCount += 1;
    if (_primaryDanmuInfoResponses.isEmpty) {
      throw StateError('No primary danmu info response queued for $roomId');
    }
    final next = _primaryDanmuInfoResponses.removeAt(0);
    if (next is Exception) {
      throw next;
    }
    if (next is Error) {
      throw next;
    }
    return next as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getAlternateRoomDanmuInfo({
    required String roomId,
  }) async {
    alternateDanmuInfoCallCount += 1;
    if (_alternateDanmuInfoResponses.isEmpty) {
      throw StateError('No alternate danmu info response queued for $roomId');
    }
    final next = _alternateDanmuInfoResponses.removeAt(0);
    if (next is Exception) {
      throw next;
    }
    if (next is Error) {
      throw next;
    }
    return next as Map<String, dynamic>;
  }
}

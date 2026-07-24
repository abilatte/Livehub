import 'package:livehub_core/src/common/huya_protocol_utils.dart';
import 'package:test/test.dart';

void main() {
  group('HuyaProtocolUtils', () {
    test('asPositiveInt coerces strings and rejects non-positive values', () {
      expect(HuyaProtocolUtils.asPositiveInt(12), 12);
      expect(HuyaProtocolUtils.asPositiveInt('34'), 34);
      expect(HuyaProtocolUtils.asPositiveInt(0), 0);
      expect(HuyaProtocolUtils.asPositiveInt(-3), 0);
      expect(HuyaProtocolUtils.asPositiveInt('x'), 0);
      expect(HuyaProtocolUtils.asPositiveInt(null), 0);
    });

    test('firstPositiveIntByKeys finds nested channel ids', () {
      final source = {
        'roomInfo': {
          'tLiveInfo': {
            'lChannelId': '0',
          },
          'extra': {
            'lSubChannelId': 998877,
          },
        },
      };
      expect(
        HuyaProtocolUtils.firstPositiveIntByKeys(
          source,
          const ['lChannelId', 'lSubChannelId'],
        ),
        998877,
      );
    });

    test('resolvePresenterUid prefers topSid then subSid then profile', () {
      expect(
        HuyaProtocolUtils.resolvePresenterUid(
          topSid: 11,
          subSid: 22,
          profileRoomId: 33,
        ),
        11,
      );
      expect(
        HuyaProtocolUtils.resolvePresenterUid(
          topSid: 0,
          subSid: 22,
          profileRoomId: 33,
        ),
        22,
      );
      expect(
        HuyaProtocolUtils.resolvePresenterUid(
          topSid: '0',
          subSid: null,
          profileRoomId: '44',
        ),
        44,
      );
    });

    test('isHuyaLiveStatus treats eLiveStatus 2 as live', () {
      expect(HuyaProtocolUtils.isHuyaLiveStatus(2), isTrue);
      expect(HuyaProtocolUtils.isHuyaLiveStatus('2'), isTrue);
      expect(HuyaProtocolUtils.isHuyaLiveStatus(0), isFalse);
    });
  });
}

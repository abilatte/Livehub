import 'package:livehub_core/src/common/douyin_protocol_utils.dart';
import 'package:test/test.dart';

void main() {
  group('DouyinProtocolUtils', () {
    test('parseCookieValue and mergeCookieValues merge keys correctly', () {
      final merged = DouyinProtocolUtils.mergeCookieValues(
        'ttwid=base; sessionid=old',
        'sessionid=new; __ac_nonce=n1',
      );
      final map = DouyinProtocolUtils.parseCookieValue(merged);
      expect(map['ttwid'], 'base');
      expect(map['sessionid'], 'new');
      expect(map['__ac_nonce'], 'n1');

      final preferBase = DouyinProtocolUtils.mergeCookieValues(
        'ttwid=base; sessionid=old',
        'sessionid=new',
        preferBase: true,
      );
      expect(
        DouyinProtocolUtils.parseCookieValue(preferBase)['sessionid'],
        'old',
      );
    });

    test('getCookieHeaderValue accepts Cookie or cookie keys', () {
      expect(
        DouyinProtocolUtils.getCookieHeaderValue({'cookie': 'a=1'}),
        'a=1',
      );
      expect(
        DouyinProtocolUtils.getCookieHeaderValue({'Cookie': 'b=2'}),
        'b=2',
      );
    });

    test('ensureCookieEndsWithSemicolon is idempotent', () {
      expect(DouyinProtocolUtils.ensureCookieEndsWithSemicolon('a=1'), 'a=1;');
      expect(DouyinProtocolUtils.ensureCookieEndsWithSemicolon('a=1;'), 'a=1;');
      expect(DouyinProtocolUtils.ensureCookieEndsWithSemicolon('  '), '');
    });

    test('parseDouyinStatus and isDouyinLiveStatus use status==2 as live', () {
      expect(DouyinProtocolUtils.parseDouyinStatus(2), 2);
      expect(DouyinProtocolUtils.parseDouyinStatus('2'), 2);
      expect(DouyinProtocolUtils.parseDouyinStatus({'status': '4'}), 4);
      expect(DouyinProtocolUtils.isDouyinLiveStatus({'status': 2}), isTrue);
      expect(
        DouyinProtocolUtils.isDouyinLiveStatus({'live_status': 4}),
        isFalse,
      );
      expect(DouyinProtocolUtils.isDouyinLiveStatus('not-a-map'), isFalse);
    });

    test('looksLikeWebRid distinguishes short webRid from long roomId', () {
      expect(DouyinProtocolUtils.looksLikeWebRid('416144012050'), isTrue);
      expect(
        DouyinProtocolUtils.looksLikeWebRid('7376429659866598196'),
        isFalse,
      );
      expect(DouyinProtocolUtils.looksLikeWebRid(''), isFalse);
    });
  });
}

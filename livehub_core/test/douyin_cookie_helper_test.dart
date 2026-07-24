import 'package:livehub_core/src/common/douyin_cookie_helper.dart';
import 'package:test/test.dart';

void main() {
  group('DouyinCookieHelper', () {
    test('normalizeInput wraps bare ttwid token', () {
      expect(
        DouyinCookieHelper.normalizeInput('abc123token'),
        'ttwid=abc123token',
      );
    });

    test('normalizeInput strips Cookie: prefix', () {
      expect(
        DouyinCookieHelper.normalizeInput('Cookie: ttwid=x; sessionid=y'),
        'ttwid=x; sessionid=y',
      );
    });

    test('extractCookieFromHeaderText reads multi-line request headers', () {
      const headers = '''
Host: live.douyin.com
User-Agent: Mozilla/5.0
Cookie: ttwid=1%7Cabc; sessionid=sid_value
Accept: */*
''';
      expect(
        DouyinCookieHelper.extractCookieFromHeaderText(headers),
        'ttwid=1%7Cabc; sessionid=sid_value',
      );
      expect(
        DouyinCookieHelper.normalizeInput(headers),
        'ttwid=1%7Cabc; sessionid=sid_value',
      );
    });

    test('isOnlyTtwid and hasFullCookie distinguish cookie completeness', () {
      expect(DouyinCookieHelper.isOnlyTtwid('ttwid=only'), isTrue);
      expect(DouyinCookieHelper.hasFullCookie('ttwid=only'), isFalse);
      expect(
        DouyinCookieHelper.hasFullCookie('ttwid=a; sessionid=b'),
        isTrue,
      );
      expect(DouyinCookieHelper.hasCustomCookie(''), isFalse);
    });

    test('cookieCompletenessHint returns stable messages for fixtures', () {
      expect(DouyinCookieHelper.cookieCompletenessHint(''), contains('未配置'));
      expect(
        DouyinCookieHelper.cookieCompletenessHint('ttwid=only'),
        contains('ttwid'),
      );
      expect(
        DouyinCookieHelper.cookieCompletenessHint('ttwid=a; sessionid=b'),
        contains('登录态'),
      );
    });
  });
}

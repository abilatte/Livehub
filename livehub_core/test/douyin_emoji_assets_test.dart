import 'package:livehub_core/src/danmaku/douyin_emoji_assets.dart';
import 'package:test/test.dart';

void main() {
  group('resolveDouyinEmojiAsset', () {
    test('resolves known code to asset path', () {
      final path = resolveDouyinEmojiAsset('[微笑]');
      expect(path, isNotNull);
      expect(path, contains('douyin_emoji'));
    });

    test('unknown code returns null without throwing', () {
      expect(resolveDouyinEmojiAsset('[不存在的表情]'), isNull);
      expect(resolveDouyinEmojiAsset(''), isNull);
    });
  });

  group('splitDouyinChatWithEmoji', () {
    test('keeps unknown codes as plain text', () {
      final segments = splitDouyinChatWithEmoji('你好[不存在]世界');
      expect(segments.map((e) => e.text).join(), '你好[不存在]世界');
      expect(segments.every((e) => !e.isEmoji || e.assetPath != null), isTrue);
    });

    test('splits known emoji into emoji segment', () {
      final segments = splitDouyinChatWithEmoji('打call[666]');
      expect(segments.length, greaterThanOrEqualTo(2));
      final emoji = segments.where((e) => e.isEmoji).toList();
      expect(emoji, isNotEmpty);
      expect(emoji.first.emojiCode, '[666]');
      expect(emoji.first.assetPath, isNotNull);
    });
  });
}

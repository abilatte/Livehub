// Subset of Douyin emoji code → asset path mapping (fork-compatible keys).
// Full image dump is optional; resolve returns null for unknown codes.
const Map<String, String> douyinEmojiAssets = {
  '[微笑]': 'assets/images/douyin_emoji/1f642.png',
  '[害羞]': 'assets/images/douyin_emoji/1f60a.png',
  '[爱心]': 'assets/images/douyin_emoji/2764.png',
  '[心碎]': 'assets/images/douyin_emoji/1f494.png',
  '[礼物]': 'assets/images/douyin_emoji/1f381.png',
  '[蛋糕]': 'assets/images/douyin_emoji/1f382.png',
  '[派对]': 'assets/images/douyin_emoji/1f389.png',
  '[强]': 'assets/images/douyin_emoji/cp7.png',
  '[666]': 'assets/images/douyin_emoji/co9.png',
  '[机智]': 'assets/images/douyin_emoji/cn0.png',
  '[给力]': 'assets/images/douyin_emoji/clw.png',
  '[嘿哈]': 'assets/images/douyin_emoji/cm8.png',
  '[疑问]': 'assets/images/douyin_emoji/cnb.png',
  '[奋斗]': 'assets/images/douyin_emoji/cpc.png',
  '[太阳]': 'assets/images/douyin_emoji/1f31e.png',
  '[月亮]': 'assets/images/douyin_emoji/1f31c.png',
  '[咖啡]': 'assets/images/douyin_emoji/2615.png',
  '[西瓜]': 'assets/images/douyin_emoji/1f349.png',
  '[红包]': 'assets/images/douyin_emoji/1f9e7.png',
  '[胜利]': 'assets/images/douyin_emoji/270c.png',
};

/// Resolve a Douyin emoji code like `[微笑]` to a local asset path, or null.
String? resolveDouyinEmojiAsset(String code) {
  final key = code.trim();
  if (key.isEmpty) {
    return null;
  }
  final direct = douyinEmojiAssets[key];
  if (direct != null) {
    return direct;
  }
  // Accept codes without brackets.
  if (!key.startsWith('[')) {
    return douyinEmojiAssets['[$key]'];
  }
  return null;
}

/// Split chat text into plain segments and emoji codes for safe rendering.
List<DouyinChatSegment> splitDouyinChatWithEmoji(String text) {
  final result = <DouyinChatSegment>[];
  final pattern = RegExp(r'\[[^\[\]]+\]');
  var start = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > start) {
      result.add(DouyinChatSegment.text(text.substring(start, match.start)));
    }
    final code = match.group(0)!;
    final asset = resolveDouyinEmojiAsset(code);
    if (asset != null) {
      result.add(DouyinChatSegment.emoji(code, asset));
    } else {
      // Unknown code: keep as plain text so chat never breaks.
      result.add(DouyinChatSegment.text(code));
    }
    start = match.end;
  }
  if (start < text.length) {
    result.add(DouyinChatSegment.text(text.substring(start)));
  }
  if (result.isEmpty && text.isNotEmpty) {
    result.add(DouyinChatSegment.text(text));
  }
  return result;
}

class DouyinChatSegment {
  final String text;
  final String? emojiCode;
  final String? assetPath;

  const DouyinChatSegment._({
    required this.text,
    this.emojiCode,
    this.assetPath,
  });

  factory DouyinChatSegment.text(String value) =>
      DouyinChatSegment._(text: value);

  factory DouyinChatSegment.emoji(String code, String asset) =>
      DouyinChatSegment._(text: code, emojiCode: code, assetPath: asset);

  bool get isEmoji => assetPath != null;
}

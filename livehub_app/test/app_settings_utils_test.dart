import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/app/controller/settings/app_settings_utils.dart';

void main() {
  group('normalizeOrderedKeys', () {
    test('会保留原有顺序并补齐缺失键', () {
      final result = normalizeOrderedKeys(
        storedKeys: ['bilibili', 'douyu'],
        validKeys: const ['bilibili', 'douyu', 'huya', 'douyin'],
      );

      expect(result, ['bilibili', 'douyu', 'huya', 'douyin']);
    });

    test('会过滤无效键和重复键', () {
      final result = normalizeOrderedKeys(
        storedKeys: ['douyu', 'unknown', 'douyu', 'huya'],
        validKeys: const ['bilibili', 'douyu', 'huya'],
      );

      expect(result, ['douyu', 'huya', 'bilibili']);
    });

    test('空输入时回退为全部合法键', () {
      final result = normalizeOrderedKeys(
        storedKeys: const [],
        validKeys: const ['home', 'follow'],
      );

      expect(result, ['home', 'follow']);
    });
  });

  group('normalizeShieldWords', () {
    test('会去空白、去重并保留原始顺序', () {
      final result = normalizeShieldWords([
        ' 剧透 ',
        '',
        '广告',
        '剧透',
        '   ',
        '弹幕',
      ]);

      expect(result, ['剧透', '广告', '弹幕']);
    });
  });

  group('clampNonNegativeInt', () {
    test('负数会被收口到 0', () {
      expect(clampNonNegativeInt(-1), 0);
      expect(clampNonNegativeInt(-99), 0);
    });

    test('非负数保持原值', () {
      expect(clampNonNegativeInt(0), 0);
      expect(clampNonNegativeInt(16), 16);
    });
  });
}

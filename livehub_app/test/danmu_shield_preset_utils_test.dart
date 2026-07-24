import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/models/danmu_shield_preset.dart';
import 'package:livehub_app/modules/settings/danmu_shield/danmu_shield_preset_utils.dart';

void main() {
  group('DanmuShieldPresetUtils', () {
    test('applyPresetKeywords normalizes and dedupes', () {
      const preset = DanmuShieldPreset(
        name: '广告',
        keywords: [' 广告 ', '广告', '抽奖', ''],
      );
      expect(
        DanmuShieldPresetUtils.applyPresetKeywords(preset),
        ['广告', '抽奖'],
      );
    });

    test('encode/decode roundtrip and upsert/remove', () {
      final a = DanmuShieldPresetUtils.snapshotFromKeywords(
        name: 'p1',
        keywords: ['a', 'b'],
      );
      final encoded = DanmuShieldPresetUtils.encodePresets([a]);
      final decoded = DanmuShieldPresetUtils.decodePresets(encoded);
      expect(decoded.length, 1);
      expect(decoded.first.name, 'p1');
      expect(decoded.first.keywords, ['a', 'b']);

      final upserted = DanmuShieldPresetUtils.upsertPreset(
        decoded,
        const DanmuShieldPreset(name: 'p1', keywords: ['c']),
      );
      expect(upserted.single.keywords, ['c']);
      expect(
        DanmuShieldPresetUtils.removePresetByName(upserted, 'p1'),
        isEmpty,
      );
    });
  });
}

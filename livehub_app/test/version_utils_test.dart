import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/app/version_utils.dart';

void main() {
  group('VersionUtils', () {
    test('展示版本统一补 v 前缀', () {
      expect(VersionUtils.buildDisplayVersion('2.0.0'), 'v2.0.0');
    });

    test('展示版本已带 v 时保持原样', () {
      expect(VersionUtils.buildDisplayVersion('v2.0.0'), 'v2.0.0');
    });

    test('详细版本保留构建号', () {
      expect(
        VersionUtils.buildDetailedVersion('2.0.0', '20'),
        '2.0.0+20',
      );
    });

    test('构建号为空时只返回版本号', () {
      expect(
        VersionUtils.buildDetailedVersion('2.0.0', ''),
        '2.0.0',
      );
    });
  });
}

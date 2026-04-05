import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/app/utils.dart';

void main() {
  group('Utils.parseTime', () {
    test('空时间返回空字符串', () {
      expect(Utils.parseTime(null), '');
    });

    test('当天时间使用 HH:mm 格式', () {
      final now = DateTime.now();
      final input = DateTime(
        now.year,
        now.month,
        now.day,
        9,
        5,
      );

      expect(Utils.parseTime(input), '09:05');
    });

    test('跨年时间使用 yyyy-MM-dd HH:mm 格式', () {
      final now = DateTime.now();
      final input = DateTime(now.year - 1, 12, 31, 23, 59);

      expect(
        Utils.parseTime(input),
        '${now.year - 1}-12-31 23:59',
      );
    });
  });
}

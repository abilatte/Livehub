import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/search/search_site_utils.dart';

void main() {
  group('resolveSearchSiteIndex', () {
    const supportSiteIds = <String>[
      'bilibili',
      'douyu',
      'huya',
      'douyin',
    ];

    test('未传站点时回退到第一个站点', () {
      expect(
        resolveSearchSiteIndex(supportSiteIds: supportSiteIds),
        0,
      );
    });

    test('传入存在的站点时返回对应索引', () {
      expect(
        resolveSearchSiteIndex(
          supportSiteIds: supportSiteIds,
          initialSiteId: 'huya',
        ),
        2,
      );
    });

    test('传入不存在的站点时回退到第一个站点', () {
      expect(
        resolveSearchSiteIndex(
          supportSiteIds: supportSiteIds,
          initialSiteId: 'unknown',
        ),
        0,
      );
    });
  });
}

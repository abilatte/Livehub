import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/modules/follow_user/follow_user_filter_utils.dart';

void main() {
  group('FollowUser 导入导出结构', () {
    test('导出 JSON 不再包含标签字段', () {
      final follow = FollowUser(
        id: 'bilibili_13308358',
        roomId: '13308358',
        siteId: 'bilibili',
        userName: '甜药Jamren',
        face: 'face',
        addTime: DateTime(2026, 3, 21, 15, 30, 0),
      );

      final json = follow.toJson();

      expect(json.containsKey('tag'), isFalse);
    });

    test('读取旧数据时忽略遗留的标签字段', () {
      final follow = FollowUser.fromJson({
        'id': 'bilibili_13308358',
        'roomId': '13308358',
        'siteId': 'bilibili',
        'userName': '甜药Jamren',
        'face': 'face',
        'addTime': '2026-03-21 15:30:00.000',
        'tag': '自定义标签',
      });

      expect(follow.id, 'bilibili_13308358');
      expect(follow.roomId, '13308358');
    });
  });

  group('关注页筛选配置', () {
    test('只保留三个内置筛选项', () {
      expect(
        kDefaultFollowFilters.map((item) => item.label).toList(),
        ['全部', '直播中', '未开播'],
      );
    });
  });
}

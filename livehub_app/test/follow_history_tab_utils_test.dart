import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/follow_history_tab_utils.dart';

void main() {
  group('followHistoryTabToIndex', () {
    test('关注列表映射为 0', () {
      expect(followHistoryTabToIndex(FollowHistoryTab.follow), 0);
    });

    test('观看历史映射为 1', () {
      expect(followHistoryTabToIndex(FollowHistoryTab.history), 1);
    });
  });

  group('followHistoryTabFromIndex', () {
    test('0 映射为关注列表', () {
      expect(followHistoryTabFromIndex(0), FollowHistoryTab.follow);
    });

    test('1 映射为观看历史', () {
      expect(followHistoryTabFromIndex(1), FollowHistoryTab.history);
    });

    test('非法索引回退为关注列表', () {
      expect(followHistoryTabFromIndex(-1), FollowHistoryTab.follow);
      expect(followHistoryTabFromIndex(99), FollowHistoryTab.follow);
    });
  });

  group('isFollowTabIndex', () {
    test('非 1 的索引都回退为关注列表', () {
      expect(isFollowTabIndex(0), isTrue);
      expect(isFollowTabIndex(1), isFalse);
      expect(isFollowTabIndex(2), isTrue);
    });
  });
}

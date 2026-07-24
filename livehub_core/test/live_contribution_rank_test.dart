import 'package:livehub_core/src/model/live_contribution_rank.dart';
import 'package:test/test.dart';

void main() {
  group('LiveContributionRankItem.fromGenericMap', () {
    test('maps bilibili-like rank payload', () {
      final item = LiveContributionRankItem.fromGenericMap({
        'rank': 3,
        'name': '用户A',
        'face': 'https://example.com/a.png',
        'score': '12345',
      });
      expect(item.rank, 3);
      expect(item.userName, '用户A');
      expect(item.avatar, 'https://example.com/a.png');
      expect(item.scoreText, '12345');
    });

    test('maps douyu intimacy rank payload', () {
      final item = LiveContributionRankItem.fromGenericMap(
        {
          'rank': 2,
          'nickname': '斗鱼用户',
          'avatar': 'https://example.com/d.png',
          'value': '88',
        },
        fallbackRank: 2,
        defaultScoreDetail: '亲密度',
      );
      expect(item.rank, 2);
      expect(item.userName, '斗鱼用户');
      expect(item.scoreText, '88');
      expect(item.scoreDetail, '亲密度');
    });
  });

  group('LiveContributionRankItem.fromDouyinRankEntry', () {
    test('maps nested user and score fields', () {
      final item = LiveContributionRankItem.fromDouyinRankEntry(
        {
          'rank': 1,
          'exactly_score': '999',
          'score_description': '本场贡献',
          'user': {
            'nickname': '抖音用户',
            'avatar_thumb': {
              'url_list': ['https://example.com/dy.png'],
            },
            'pay_grade': {'level': 12},
            'fans_club': {
              'data': {'level': 5, 'club_name': '粉丝团'},
            },
          },
        },
        index: 0,
      );
      expect(item.rank, 1);
      expect(item.userName, '抖音用户');
      expect(item.avatar, 'https://example.com/dy.png');
      expect(item.scoreText, '999');
      expect(item.userLevel, 12);
      expect(item.fansLevel, 5);
      expect(item.fansName, '粉丝团');
    });

    test('resolveDouyinRank falls back to index when rank missing', () {
      expect(
        LiveContributionRankItem.resolveDouyinRank({}, 3),
        4,
      );
    });
  });
}

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

    test('uses fallback rank and alternate keys', () {
      final item = LiveContributionRankItem.fromGenericMap(
        {
          'uname': 'B',
          'avatar': 'https://example.com/b.png',
          'contribution': '9',
        },
        fallbackRank: 7,
      );
      expect(item.rank, 7);
      expect(item.userName, 'B');
      expect(item.scoreText, '9');
    });
  });
}

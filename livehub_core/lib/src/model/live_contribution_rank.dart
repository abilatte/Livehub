import 'dart:convert';

class LiveContributionRankItem {
  final int rank;
  final String userName;
  final String avatar;
  final String scoreText;
  final String? scoreDetail;
  final int? userLevel;
  final String? userLevelText;
  final String? userLevelIcon;
  final int? fansLevel;
  final String? fansName;
  final String? fansIcon;

  LiveContributionRankItem({
    required this.rank,
    required this.userName,
    required this.avatar,
    required this.scoreText,
    this.scoreDetail,
    this.userLevel,
    this.userLevelText,
    this.userLevelIcon,
    this.fansLevel,
    this.fansName,
    this.fansIcon,
  });

  /// Normalize raw rank maps from site APIs into a stable item.
  static LiveContributionRankItem fromGenericMap(
    Map item, {
    int fallbackRank = 0,
  }) {
    final rank = int.tryParse(
          item["rank"]?.toString() ??
              item["rank_num"]?.toString() ??
              item["position"]?.toString() ??
              "",
        ) ??
        fallbackRank;
    final userName = item["name"]?.toString() ??
        item["uname"]?.toString() ??
        item["user_name"]?.toString() ??
        item["nickname"]?.toString() ??
        item["uinfo"]?["base"]?["name"]?.toString() ??
        "";
    final avatar = item["face"]?.toString() ??
        item["avatar"]?.toString() ??
        item["uinfo"]?["base"]?["face"]?.toString() ??
        "";
    final scoreText = item["score"]?.toString() ??
        item["score_text"]?.toString() ??
        item["contribution"]?.toString() ??
        "0";
    return LiveContributionRankItem(
      rank: rank,
      userName: userName,
      avatar: avatar,
      scoreText: scoreText,
      scoreDetail: item["score_detail"]?.toString(),
    );
  }

  @override
  String toString() {
    return jsonEncode({
      "rank": rank,
      "userName": userName,
      "avatar": avatar,
      "scoreText": scoreText,
      "scoreDetail": scoreDetail,
      "userLevel": userLevel,
      "userLevelText": userLevelText,
      "userLevelIcon": userLevelIcon,
      "fansLevel": fansLevel,
      "fansName": fansName,
      "fansIcon": fansIcon,
    });
  }
}

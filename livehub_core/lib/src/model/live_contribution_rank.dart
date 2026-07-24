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
    String? defaultScoreDetail,
  }) {
    final rank = int.tryParse(
          item["rank"]?.toString() ??
              item["rank_num"]?.toString() ??
              item["position"]?.toString() ??
              "",
        ) ??
        fallbackRank;

    final nestedUser = item["user"] is Map
        ? Map<String, dynamic>.from(item["user"] as Map)
        : const <String, dynamic>{};

    final userName = item["name"]?.toString() ??
        item["uname"]?.toString() ??
        item["user_name"]?.toString() ??
        item["nickname"]?.toString() ??
        nestedUser["nickname"]?.toString() ??
        item["uinfo"]?["base"]?["name"]?.toString() ??
        "";

    final avatar = item["face"]?.toString() ??
        item["avatar"]?.toString() ??
        firstImageUrl(nestedUser["avatar_thumb"]) ??
        item["uinfo"]?["base"]?["face"]?.toString() ??
        "";

    final scoreText = item["exactly_score"]?.toString().trim().isNotEmpty == true
        ? item["exactly_score"].toString().trim()
        : (item["score_description"]?.toString().trim().isNotEmpty == true
            ? item["score_description"].toString().trim()
            : (item["score"]?.toString() ??
                item["score_text"]?.toString() ??
                item["contribution"]?.toString() ??
                item["value"]?.toString() ??
                "0"));

    final scoreDetail = item["score_detail"]?.toString() ??
        item["gap_description"]?.toString() ??
        defaultScoreDetail;

    return LiveContributionRankItem(
      rank: rank <= 0 ? fallbackRank : rank,
      userName: userName,
      avatar: avatar,
      scoreText: scoreText,
      scoreDetail: scoreDetail,
    );
  }

  /// Map Douyin webcast ranklist audience entries (pure, no network).
  static LiveContributionRankItem fromDouyinRankEntry(
    Map item, {
    int index = 0,
  }) {
    final user = item["user"] is Map
        ? Map<String, dynamic>.from(item["user"] as Map)
        : const <String, dynamic>{};
    final payGrade = user["pay_grade"] is Map
        ? Map<String, dynamic>.from(user["pay_grade"] as Map)
        : const <String, dynamic>{};
    final fansData = user["fans_club"]?["data"] is Map
        ? Map<String, dynamic>.from(user["fans_club"]["data"] as Map)
        : const <String, dynamic>{};

    final scoreText = resolveDouyinRankScore(item);
    final scoreDescription = item["score_description"]?.toString().trim() ?? "";
    final exactlyScore = item["exactly_score"]?.toString().trim() ?? "";
    String? scoreDetail;
    if (scoreDescription.isNotEmpty && scoreDescription != scoreText) {
      scoreDetail = scoreDescription;
    } else if (exactlyScore.isNotEmpty && exactlyScore != scoreText) {
      scoreDetail = exactlyScore;
    } else {
      final gapDescription = item["gap_description"]?.toString().trim() ?? "";
      scoreDetail = gapDescription.isEmpty ? null : gapDescription;
    }

    final userLevel = int.tryParse(payGrade["level"]?.toString() ?? "");
    final fansLevel = int.tryParse(fansData["level"]?.toString() ?? "");

    return LiveContributionRankItem(
      rank: resolveDouyinRank(item, index),
      userName: user["nickname"]?.toString() ?? "",
      avatar: firstImageUrl(user["avatar_thumb"]) ?? "",
      scoreText: scoreText,
      scoreDetail: scoreDetail,
      userLevel: userLevel,
      userLevelText:
          userLevel == null || userLevel <= 0 ? null : "财富 $userLevel",
      userLevelIcon: firstImageUrl(payGrade["new_im_icon_with_level"]),
      fansLevel: fansLevel,
      fansName: fansData["club_name"]?.toString(),
      fansIcon: pickDouyinBadgeIcon(fansData["badge"]?["icons"]),
    );
  }

  static int resolveDouyinRank(Map item, int index) {
    final parsed = int.tryParse(item["rank"]?.toString() ?? "");
    if (parsed == null || parsed <= 0) {
      return index + 1;
    }
    if (parsed == 1 && index > 0) {
      return index + 1;
    }
    return parsed;
  }

  static String resolveDouyinRankScore(Map item) {
    final exactlyScore = item["exactly_score"]?.toString().trim() ?? "";
    if (exactlyScore.isNotEmpty) {
      return exactlyScore;
    }
    final scoreDescription = item["score_description"]?.toString().trim() ?? "";
    if (scoreDescription.isNotEmpty) {
      return scoreDescription;
    }
    final score = item["score"]?.toString().trim() ?? "";
    if (score.isNotEmpty) {
      return score;
    }
    final delta = item["delta"]?.toString().trim() ?? "";
    if (delta.isNotEmpty) {
      return delta;
    }
    return "0";
  }

  static String? firstImageUrl(dynamic data) {
    if (data is! Map) {
      return null;
    }
    final urls = data["url_list"];
    if (urls is List && urls.isNotEmpty) {
      final value = urls.first.toString();
      return value.isEmpty ? null : value;
    }
    return null;
  }

  static String? pickDouyinBadgeIcon(dynamic icons) {
    if (icons is! Map) {
      return null;
    }
    for (final key in const ["4", "3", "2", "1", "0"]) {
      final url = firstImageUrl(icons[key]);
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    for (final value in icons.values) {
      final url = firstImageUrl(value);
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return null;
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

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

String buildLiveRoomLookupKey(String siteId, String roomId) {
  return '$siteId::$roomId';
}

int expandHistoryVisibleCount({
  required int totalCount,
  required int currentCount,
  int pageSize = 20,
}) {
  if (totalCount <= 0) {
    return 0;
  }
  if (currentCount <= 0) {
    return math.min(totalCount, pageSize);
  }
  return math.min(totalCount, currentCount + pageSize);
}

bool shouldLoadMoreHistory({
  required double extentAfter,
  double threshold = 480,
}) {
  return extentAfter <= threshold;
}

bool isChatListNearBottom({
  required double extentAfter,
  double threshold = 48,
}) {
  return extentAfter <= threshold;
}

bool shouldDisableChatAutoScroll({
  required double extentAfter,
  required ScrollDirection userScrollDirection,
  double bottomThreshold = 48,
}) {
  if (isChatListNearBottom(
    extentAfter: extentAfter,
    threshold: bottomThreshold,
  )) {
    return false;
  }
  return userScrollDirection == ScrollDirection.forward;
}

bool shouldEnableChatAutoScroll({
  required double extentAfter,
  double bottomThreshold = 24,
}) {
  return isChatListNearBottom(
    extentAfter: extentAfter,
    threshold: bottomThreshold,
  );
}

int resolveChatMessageLimit({
  required bool autoScrollDisabled,
  int? customLimit,
  int followModeLimit = 300,
  int reviewModeLimit = 1200,
}) {
  if (customLimit != null && customLimit > 0) {
    return customLimit;
  }
  return autoScrollDisabled ? reviewModeLimit : followModeLimit;
}

int resolveChatTrimCount({
  required int nextCount,
  required bool autoScrollDisabled,
  int? customLimit,
  int followModeLimit = 300,
  int reviewModeLimit = 1200,
}) {
  final limit = resolveChatMessageLimit(
    autoScrollDisabled: autoScrollDisabled,
    customLimit: customLimit,
    followModeLimit: followModeLimit,
    reviewModeLimit: reviewModeLimit,
  );
  if (nextCount <= limit) {
    return 0;
  }
  return nextCount - limit;
}

int resolveSuperChatLimit({
  required bool keepInPage,
  int? customLimit,
  int normalLimit = 30,
  int keepModeLimit = 120,
}) {
  if (customLimit != null && customLimit > 0) {
    return customLimit;
  }
  return keepInPage ? keepModeLimit : normalLimit;
}

int resolveSuperChatTrimCount({
  required int nextCount,
  required bool keepInPage,
  int? customLimit,
  int normalLimit = 30,
  int keepModeLimit = 120,
}) {
  final limit = resolveSuperChatLimit(
    keepInPage: keepInPage,
    customLimit: customLimit,
    normalLimit: normalLimit,
    keepModeLimit: keepModeLimit,
  );
  if (nextCount <= limit) {
    return 0;
  }
  return nextCount - limit;
}

int remainingOverlaySeconds(
  DateTime expireAt, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final milliseconds =
      expireAt.millisecondsSinceEpoch - current.millisecondsSinceEpoch;
  if (milliseconds <= 0) {
    return 0;
  }
  return (milliseconds / 1000).ceil();
}

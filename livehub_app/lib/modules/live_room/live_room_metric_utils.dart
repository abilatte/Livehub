import 'package:livehub_app/app/utils.dart';
import 'package:livehub_core/livehub_core.dart';

String buildBilibiliMetricText({
  required String roomAudienceText,
  required int online,
  required String captainText,
}) {
  final metrics = <String>[];
  if (roomAudienceText.isNotEmpty) {
    metrics.add(roomAudienceText);
  } else if (online > 0) {
    metrics.add(Utils.onlineToString(online));
  }
  if (captainText.isNotEmpty) {
    metrics.add(captainText);
  }
  if (metrics.isEmpty) {
    return "--";
  }
  return metrics.join(" · ");
}

bool shouldStartDanmaku(dynamic danmakuData) {
  return danmakuData != null && danmakuData is! BiliBiliDanmakuUnavailable;
}

String resolveDanmakuStatusMessage(dynamic danmakuData) {
  if (danmakuData is BiliBiliDanmakuUnavailable &&
      danmakuData.reason.isNotEmpty) {
    return danmakuData.reason;
  }
  return "弹幕参数读取失败，本次仅播放视频";
}

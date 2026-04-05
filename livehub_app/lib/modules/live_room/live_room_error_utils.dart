class LiveRoomErrorPresentation {
  final String title;
  final String summary;
  final String suggestion;
  final String type;

  const LiveRoomErrorPresentation({
    required this.title,
    required this.summary,
    required this.suggestion,
    required this.type,
  });
}

LiveRoomErrorPresentation resolveLiveRoomErrorPresentation(Object? error) {
  final rawText = error?.toString().trim() ?? "";
  final text = rawText.toLowerCase();

  if (text.isEmpty) {
    return const LiveRoomErrorPresentation(
      title: "直播间暂时打不开",
      summary: "软件没拿到足够的错误信息。",
      suggestion: "可以先点刷新再试一次，如果仍然失败，再导出诊断包排查。",
      type: "unknown",
    );
  }

  if (_containsAny(text, const [
    "socketexception",
    "timed out",
    "timeout",
    "connection",
    "network",
    "dns",
    "handshake",
    "unreachable",
    "网络",
    "连接",
    "超时",
  ])) {
    return const LiveRoomErrorPresentation(
      title: "网络连接异常",
      summary: "直播间信息没有顺利从服务器返回。",
      suggestion: "先检查网络和代理状态，再点刷新；如果只是偶发，稍后重试通常就能恢复。",
      type: "network",
    );
  }

  if (_containsAny(text, const [
    "401",
    "403",
    "forbidden",
    "unauthorized",
    "cookie",
    "login",
    "登录",
    "权限",
  ])) {
    return const LiveRoomErrorPresentation(
      title: "账号状态或权限异常",
      summary: "当前账号可能失效，或者房间访问权限有变化。",
      suggestion: "可以先重新登录对应平台，再回到直播间刷新试一次。",
      type: "auth",
    );
  }

  if (_containsAny(text, const [
    "decoder",
    "media",
    "ffmpeg",
    "player",
    "stream",
    "播放",
    "解码",
    "音频",
    "视频",
  ])) {
    return const LiveRoomErrorPresentation(
      title: "播放器初始化失败",
      summary: "直播间信息可能已经拿到了，但播放器没能正常开始播放。",
      suggestion: "可以先切换线路或清晰度；如果问题持续，导出诊断包更方便定位。",
      type: "player",
    );
  }

  if (_containsAny(text, const [
    "404",
    "room",
    "not found",
    "不存在",
    "房间",
    "直播间",
  ])) {
    return const LiveRoomErrorPresentation(
      title: "房间信息读取失败",
      summary: "软件没能读到当前直播间的有效信息。",
      suggestion: "请先确认房间号或链接是否正确，再尝试刷新；如果仍然失败，可能是站点接口发生变化。",
      type: "room",
    );
  }

  return const LiveRoomErrorPresentation(
    title: "直播间加载失败",
    summary: "软件遇到了暂时无法自动识别的问题。",
    suggestion: "可以先刷新一次；如果重复出现，打开日志目录或导出诊断包给开发者排查。",
    type: "unknown",
  );
}

List<String> buildLiveRoomErrorContextTips({
  required String errorType,
  required int retryCount,
  required int playUrlCount,
  required int currentLineIndex,
  required int qualityCount,
  required String currentQuality,
  required String currentLine,
}) {
  final tips = <String>[];

  switch (errorType) {
    case 'network':
      tips.add('先检查当前网络、代理或 DNS，再进行刷新。');
      break;
    case 'auth':
      tips.add('优先重新登录对应平台，再回到当前直播间重试。');
      break;
    case 'player':
      if (playUrlCount > 1) {
        tips.add('当前更像是线路或拉流异常，先尝试切换线路。');
      } else if (qualityCount > 1) {
        tips.add('当前更像是播放器兼容问题，先尝试切换清晰度。');
      } else {
        tips.add('当前更像是播放器初始化问题，建议先刷新再观察。');
      }
      break;
    case 'room':
      tips.add('先确认房间号和直播状态是否有效，再决定是否刷新。');
      break;
    default:
      tips.add('先执行最轻量的刷新动作，再决定是否导出诊断包。');
      break;
  }

  if (retryCount > 0) {
    tips.add('播放器已自动重试 $retryCount 次。');
  }
  if (currentQuality.isNotEmpty) {
    tips.add('当前清晰度：$currentQuality');
  }
  if (currentLine.isNotEmpty) {
    tips.add('当前线路：$currentLine');
  } else if (playUrlCount > 1 && currentLineIndex >= 0) {
    tips.add('当前线路：线路${currentLineIndex + 1}');
  }
  if (playUrlCount > 1) {
    tips.add('还可以尝试其他 ${playUrlCount - 1} 条备用线路。');
  } else if (qualityCount > 1) {
    tips.add('还可以尝试其他清晰度档位。');
  }

  tips.add('如仍失败，再复制详情或导出诊断包进行排查。');
  return tips.take(4).toList();
}

bool _containsAny(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) {
      return true;
    }
  }
  return false;
}

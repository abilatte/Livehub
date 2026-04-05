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

bool _containsAny(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) {
      return true;
    }
  }
  return false;
}

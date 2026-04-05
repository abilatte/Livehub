Map<String, dynamic> buildLiveRoomPlayerSettingContext({
  required bool customPlayerOutput,
  required String videoOutputDriver,
  required String audioOutputDriver,
  required String videoHardwareDecoder,
  required bool logEnabled,
  required int scaleMode,
}) {
  return <String, dynamic>{
    'customPlayerOutput': customPlayerOutput,
    'videoOutputDriver': videoOutputDriver,
    'audioOutputDriver': audioOutputDriver,
    'videoHardwareDecoder': videoHardwareDecoder,
    'logEnabled': logEnabled,
    'scaleMode': scaleMode,
  };
}

Map<String, dynamic> buildLiveRoomDiagnosticContext({
  required String siteId,
  required String siteName,
  required String roomId,
  String? roomTitle,
  String? anchor,
  String? url,
  required bool liveStatus,
  required String currentQuality,
  required String currentLine,
  required int online,
  required String roomAudienceText,
  required String errorType,
  required String errorTitle,
  required String errorSummary,
  required String errorSuggestion,
  required Map<String, dynamic> playerSetting,
  required String errorDetail,
}) {
  return <String, dynamic>{
    'scope': 'live_room',
    'siteId': siteId,
    'siteName': siteName,
    'roomId': roomId,
    'roomTitle': roomTitle,
    'anchor': anchor,
    'url': url,
    'liveStatus': liveStatus,
    'currentQuality': currentQuality,
    'currentLine': currentLine,
    'online': online,
    'roomAudienceText': roomAudienceText,
    'errorType': errorType,
    'errorTitle': errorTitle,
    'errorSummary': errorSummary,
    'errorSuggestion': errorSuggestion,
    'playerSetting': playerSetting,
    'errorDetail': errorDetail,
  };
}

String buildLiveRoomErrorDetailText({
  required String appVersion,
  required DateTime generatedAt,
  required String siteName,
  required String roomId,
  String? roomTitle,
  String? anchor,
  required String roomAudienceText,
  required int online,
  required String errorTitle,
  required String errorType,
  required String errorSummary,
  required String errorSuggestion,
  String? rawError,
  String? rawStackTrace,
}) {
  final audienceText = roomAudienceText.isNotEmpty ? roomAudienceText : '$online';

  return '''应用版本：$appVersion
时间：${generatedAt.toIso8601String()}
直播平台：$siteName
房间号：$roomId
房间标题：${roomTitle ?? "-"}
主播：${anchor ?? "-"}
观看信息：$audienceText
错误分类：$errorTitle（$errorType）
问题概述：$errorSummary
建议处理：$errorSuggestion
错误信息：
${rawError ?? ""}
----------------
${rawStackTrace ?? ""}''';
}

enum LiveRoomPlaybackSwitchKind { quality, line }

class LiveRoomPlaybackSnapshot {
  final int qualityIndex;
  final String qualityLabel;
  final List<String> playUrls;
  final Map<String, String>? playHeaders;
  final int lineIndex;
  final String lineLabel;

  const LiveRoomPlaybackSnapshot({
    required this.qualityIndex,
    required this.qualityLabel,
    required this.playUrls,
    required this.playHeaders,
    required this.lineIndex,
    required this.lineLabel,
  });
}

class LiveRoomPlaybackSwitchRequest {
  final LiveRoomPlaybackSwitchKind kind;
  final LiveRoomPlaybackSnapshot previous;
  final int targetQualityIndex;
  final String targetQualityLabel;
  final List<String> targetPlayUrls;
  final Map<String, String>? targetPlayHeaders;
  final int targetLineIndex;
  final String targetLineLabel;

  const LiveRoomPlaybackSwitchRequest({
    required this.kind,
    required this.previous,
    required this.targetQualityIndex,
    required this.targetQualityLabel,
    required this.targetPlayUrls,
    required this.targetPlayHeaders,
    required this.targetLineIndex,
    required this.targetLineLabel,
  });

  factory LiveRoomPlaybackSwitchRequest.forQuality({
    required LiveRoomPlaybackSnapshot previous,
    required int targetQualityIndex,
    required String targetQualityLabel,
    required List<String> targetPlayUrls,
    required Map<String, String>? targetPlayHeaders,
    required String targetLineLabel,
  }) {
    return LiveRoomPlaybackSwitchRequest(
      kind: LiveRoomPlaybackSwitchKind.quality,
      previous: previous,
      targetQualityIndex: targetQualityIndex,
      targetQualityLabel: targetQualityLabel,
      targetPlayUrls: targetPlayUrls,
      targetPlayHeaders: targetPlayHeaders,
      targetLineIndex: 0,
      targetLineLabel: targetLineLabel,
    );
  }

  factory LiveRoomPlaybackSwitchRequest.forLine({
    required LiveRoomPlaybackSnapshot previous,
    required int targetLineIndex,
    required String targetLineLabel,
  }) {
    return LiveRoomPlaybackSwitchRequest(
      kind: LiveRoomPlaybackSwitchKind.line,
      previous: previous,
      targetQualityIndex: previous.qualityIndex,
      targetQualityLabel: previous.qualityLabel,
      targetPlayUrls: List<String>.from(previous.playUrls),
      targetPlayHeaders: previous.playHeaders == null
          ? null
          : Map<String, String>.from(previous.playHeaders!),
      targetLineIndex: targetLineIndex,
      targetLineLabel: targetLineLabel,
    );
  }
}

bool shouldStartPlaybackSwitch({
  required bool isSwitchingPlaybackSource,
  required int currentIndex,
  required int nextIndex,
  required int itemCount,
}) {
  if (isSwitchingPlaybackSource) {
    return false;
  }
  if (nextIndex < 0 || nextIndex >= itemCount) {
    return false;
  }
  return currentIndex != nextIndex;
}

String buildPlaybackSwitchLabel({
  required LiveRoomPlaybackSwitchKind kind,
  required String targetLabel,
}) {
  switch (kind) {
    case LiveRoomPlaybackSwitchKind.quality:
      return '正在切换清晰度至 $targetLabel';
    case LiveRoomPlaybackSwitchKind.line:
      return '正在切换线路至 $targetLabel';
  }
}

String buildPlaybackSwitchRollbackToast(LiveRoomPlaybackSwitchKind kind) {
  switch (kind) {
    case LiveRoomPlaybackSwitchKind.quality:
      return '切换清晰度失败，已回退到上一档';
    case LiveRoomPlaybackSwitchKind.line:
      return '切换线路失败，已回退到上一条';
  }
}

bool canRestorePlaybackSnapshot(LiveRoomPlaybackSnapshot snapshot) {
  return snapshot.playUrls.isNotEmpty &&
      snapshot.lineIndex >= 0 &&
      snapshot.lineIndex < snapshot.playUrls.length;
}

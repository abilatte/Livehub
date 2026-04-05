int resolveInitialQualityIndex({
  required int qualityCount,
  required int qualityLevel,
}) {
  if (qualityCount <= 0) {
    return -1;
  }

  if (qualityLevel == 2) {
    return 0;
  }

  if (qualityLevel == 0) {
    return qualityCount - 1;
  }

  return (qualityCount / 2).floor();
}

String buildLiveRoomLineLabel(int index) {
  return '线路${index + 1}';
}

String normalizePlaybackUrl(
  String url, {
  required bool forceHttps,
}) {
  if (!forceHttps) {
    return url;
  }
  return url.replaceAll('http://', 'https://');
}

List<String> normalizePlaybackUrls(
  Iterable<String> urls, {
  required bool forceHttps,
}) {
  return urls
      .map((url) => normalizePlaybackUrl(url, forceHttps: forceHttps))
      .toList();
}

bool hasNextPlayLine({
  required int currentLineIndex,
  required int playUrlCount,
}) {
  return currentLineIndex >= 0 && currentLineIndex < playUrlCount - 1;
}

bool shouldRetryPlayback({
  required int retryCount,
  int maxRetryCount = 2,
}) {
  return retryCount < maxRetryCount;
}

int nextPlaybackRetryCount(int retryCount) {
  return retryCount + 1;
}

Duration resolvePlaybackRetryDelay(int retryCount) {
  if (retryCount == 1) {
    return const Duration(seconds: 1);
  }
  return Duration.zero;
}

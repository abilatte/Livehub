enum PlayerControlLayoutMode { normal, fullScreen }

PlayerControlLayoutMode resolvePlayerControlLayoutMode({
  required bool nativeFullScreenState,
  required bool enteringFullScreenState,
  required bool smallWindowState,
}) {
  if (nativeFullScreenState ||
      enteringFullScreenState ||
      smallWindowState) {
    return PlayerControlLayoutMode.fullScreen;
  }
  return PlayerControlLayoutMode.normal;
}

bool shouldEnableVerbosePlayerStreamLogging({
  required bool logEnabled,
  required bool isDebugMode,
}) {
  return logEnabled && isDebugMode;
}

bool hasPlayerVideoSizeChanged({
  required num? previousWidth,
  required num? previousHeight,
  required num? nextWidth,
  required num? nextHeight,
}) {
  return previousWidth != nextWidth || previousHeight != nextHeight;
}

bool resolveIsVerticalLiveRoom({
  required num? width,
  required num? height,
  required bool fallback,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return fallback;
  }
  return height > width;
}

bool shouldShowDesktopControlsOnHover({
  required double localDy,
  required double viewportHeight,
  double triggerRatio = 0.25,
}) {
  if (viewportHeight <= 0) {
    return false;
  }
  final triggerHeight = viewportHeight * triggerRatio;
  return localDy <= triggerHeight || localDy >= viewportHeight - triggerHeight;
}

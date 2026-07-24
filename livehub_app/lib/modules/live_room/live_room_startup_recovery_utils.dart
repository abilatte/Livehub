const int kLiveRoomInitialRecoveryMaxAttempts = 2;

bool shouldAttemptInitialLoadRecovery({
  required String errorType,
  required int recoveryCount,
  required bool initialLoadSettled,
  int maxRecoveryCount = kLiveRoomInitialRecoveryMaxAttempts,
}) {
  if (initialLoadSettled || recoveryCount >= maxRecoveryCount) {
    return false;
  }

  switch (errorType) {
    case 'network':
    case 'player':
    case 'unknown':
      return true;
    default:
      return false;
  }
}

Duration resolveInitialLoadRecoveryDelay(int recoveryCount) {
  switch (recoveryCount) {
    case 0:
      return const Duration(milliseconds: 600);
    case 1:
      return const Duration(seconds: 1);
    default:
      return const Duration(seconds: 2);
  }
}

String buildInitialLoadRecoveryLabel({
  required String errorType,
  required int nextAttempt,
  int maxAttempts = kLiveRoomInitialRecoveryMaxAttempts,
}) {
  switch (errorType) {
    case 'network':
      return '网络波动，正在尝试重新连接（$nextAttempt/$maxAttempts）';
    case 'player':
      return '播放器启动异常，正在尝试重新初始化（$nextAttempt/$maxAttempts）';
    default:
      return '首屏加载异常，正在尝试自动恢复（$nextAttempt/$maxAttempts）';
  }
}

bool shouldShowInitialLoadRecoveryOverlay({
  required bool isRecoveringInitialLoad,
  required bool loadError,
  required bool isRoomSwitching,
}) {
  return isRecoveringInitialLoad && !loadError && !isRoomSwitching;
}

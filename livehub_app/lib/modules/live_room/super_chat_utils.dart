import 'package:livehub_core/livehub_core.dart';

String buildSuperChatKey(LiveSuperChatMessage message) {
  return [
    message.userName,
    message.message,
    message.price,
    message.startTime.millisecondsSinceEpoch,
    message.endTime.millisecondsSinceEpoch,
  ].join('|');
}

int remainingSuperChatSeconds(
  LiveSuperChatMessage message, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final remainingSeconds = message.endTime.difference(currentTime).inSeconds;
  return remainingSeconds > 0 ? remainingSeconds : 0;
}

int resolveOverlayDisplaySeconds(
  LiveSuperChatMessage message, {
  required bool keepInOverlay,
  DateTime? now,
  int maxDisplaySeconds = 15,
}) {
  final remainingSeconds = remainingSuperChatSeconds(message, now: now);
  if (remainingSeconds <= 0) {
    return 0;
  }
  if (keepInOverlay) {
    return remainingSeconds;
  }
  return remainingSeconds < maxDisplaySeconds
      ? remainingSeconds
      : maxDisplaySeconds;
}

List<LiveSuperChatMessage> sortSuperChatsForPage(
  Iterable<LiveSuperChatMessage> messages, {
  required bool keepInPage,
}) {
  final sorted = messages.toList();
  if (!keepInPage) {
    return sorted;
  }
  sorted.sort((a, b) => b.startTime.compareTo(a.startTime));
  return sorted;
}

const int kDesktopSidebarMinWidth = 260;
const int kDesktopSidebarMaxWidth = 360;
const int kDesktopSidebarDefaultMinWidth = 280;
const int kDesktopSidebarDefaultMaxWidth = 320;

int clampDesktopSidebarWidth(int width) {
  return width.clamp(
    kDesktopSidebarMinWidth,
    kDesktopSidebarMaxWidth,
  );
}

int resolveDefaultDesktopSidebarWidth(double width) {
  final preferred = (width * 0.19).round();
  return preferred.clamp(
    kDesktopSidebarDefaultMinWidth,
    kDesktopSidebarDefaultMaxWidth,
  );
}

double resolveDesktopSidebarWidth(
  double width, {
  int? customWidth,
}) {
  if (customWidth != null && customWidth > 0) {
    return clampDesktopSidebarWidth(customWidth).toDouble();
  }
  return resolveDefaultDesktopSidebarWidth(width).toDouble();
}

String resolveDesktopSidebarWidthHint(double width) {
  return "默认宽度：${resolveDefaultDesktopSidebarWidth(width)}";
}

bool shouldShowDesktopSidebar({
  required bool fillWindowState,
}) {
  return !fillWindowState;
}

bool shouldUseDesktopLiveRoomLayout({
  required double width,
  required bool isDesktopPlatform,
}) {
  return isDesktopPlatform && width >= 1180;
}

import 'package:flutter/material.dart';

AnimationStyle? resolveChatMessageMenuAnimationStyle({
  required bool isDesktopPlatform,
}) {
  if (!isDesktopPlatform) {
    return null;
  }
  return AnimationStyle.noAnimation;
}

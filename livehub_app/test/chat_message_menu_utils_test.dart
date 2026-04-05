import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/live_room/chat_message_menu_utils.dart';

void main() {
  group('resolveChatMessageMenuAnimationStyle', () {
    test('桌面端使用无动画弹出', () {
      final style = resolveChatMessageMenuAnimationStyle(
        isDesktopPlatform: true,
      );

      expect(style, isNotNull);
      expect(style!.duration, Duration.zero);
      expect(style.reverseDuration, Duration.zero);
    });

    test('非桌面端保持默认动画', () {
      expect(
        resolveChatMessageMenuAnimationStyle(
          isDesktopPlatform: false,
        ),
        isNull,
      );
    });
  });
}

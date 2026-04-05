import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/controller/desktop_window_controller.dart';
import 'package:window_manager/window_manager.dart';

class DesktopWindowTitleBar extends GetView<DesktopWindowController> {
  const DesktopWindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const SizedBox.shrink();
    }

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<DesktopWindowController>()) {
        Get.find<DesktopWindowController>()
            .syncWindowBackgroundColor(backgroundColor);
      }
    });

    // 使用独立 Material 包裹标题栏，避免左上角返回按钮的 hover/ink
    // 效果绘制到外层页面 Material 上，导致顶部整条区域一起变灰。
    return Material(
      color: backgroundColor,
      child: Container(
        height: DesktopWindowController.kDesktopTitleBarHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withAlpha(20)),
          ),
        ),
        child: Row(
          children: [
            if (Get.key.currentState?.canPop() ?? false)
              IconButton(
                tooltip: "返回",
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(Icons.arrow_back),
              )
            else
              const SizedBox(width: 10),
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.live_tv_rounded, size: 18),
                      AppStyle.hGap8,
                      Expanded(
                        child: Obx(
                          () => Text(
                            controller.currentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            WindowCaptionButton.minimize(
              brightness: Theme.of(context).brightness,
              onPressed: controller.minimizeWindow,
            ),
            Obx(
              () => controller.maximized.value
                  ? WindowCaptionButton.unmaximize(
                      brightness: Theme.of(context).brightness,
                      onPressed: controller.toggleMaximize,
                    )
                  : WindowCaptionButton.maximize(
                      brightness: Theme.of(context).brightness,
                      onPressed: controller.toggleMaximize,
                    ),
            ),
            WindowCaptionButton.close(
              brightness: Theme.of(context).brightness,
              onPressed: controller.closeWindow,
            ),
          ],
        ),
      ),
    );
  }
}

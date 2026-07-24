import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/controller/desktop_window_controller.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/modules/live_room/chat_message_menu_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_desktop_layout_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_controller.dart';
import 'package:livehub_app/modules/live_room/live_room_error_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_metric_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_sidebar_tab_utils.dart';
import 'package:livehub_app/modules/live_room/super_chat_utils.dart';
import 'package:livehub_app/modules/live_room/player/player_controls.dart';
import 'package:livehub_app/services/follow_service.dart';
import 'package:livehub_app/widgets/desktop_refresh_button.dart';
import 'package:livehub_app/widgets/follow_user_item.dart';
import 'package:livehub_app/widgets/keep_alive_wrapper.dart';
import 'package:livehub_app/widgets/net_image.dart';
import 'package:livehub_app/widgets/settings/settings_action.dart';
import 'package:livehub_app/widgets/settings/settings_card.dart';
import 'package:livehub_app/widgets/settings/settings_input_number.dart';
import 'package:livehub_app/widgets/settings/settings_number.dart';
import 'package:livehub_app/widgets/settings/settings_switch.dart';
import 'package:livehub_app/widgets/superchat_card.dart';
import 'package:livehub_core/livehub_core.dart';
import 'package:window_manager/window_manager.dart';

class LiveRoomPage extends GetView<LiveRoomController> {
  const LiveRoomPage({Key? key}) : super(key: key);

  List<InlineSpan> _buildChatMessageSpans(
    String message, {
    required TextStyle style,
  }) {
    final isDouyin = controller.site.id == Constant.kDouyin;
    if (!isDouyin) {
      return [TextSpan(text: message, style: style)];
    }
    final segments = splitDouyinChatWithEmoji(message);
    return [
      for (final segment in segments)
        if (segment.isEmoji && segment.assetPath != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.asset(
              segment.assetPath!,
              width: style.fontSize != null ? style.fontSize! + 4 : 16,
              height: style.fontSize != null ? style.fontSize! + 4 : 16,
              errorBuilder: (_, __, ___) => Text(segment.text, style: style),
            ),
          )
        else
          TextSpan(text: segment.text, style: style),
    ];
  }

  Future<void> showChatMessageMenu(
    BuildContext context,
    Offset globalPosition,
    LiveMessage message,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final isSystem = isChatSystemMessage(message.userName);
    final userName = normalizeChatUserName(message.userName);
    final isPlatformShielded = !isSystem &&
        AppSettingsController.instance.isUserShielded(
          userName,
          siteId: controller.site.id,
        );
    final isTempMuted = !isSystem && controller.isTempMutedUser(userName);
    final specs = buildChatMessageMenuItems(
      isSystemMessage: isSystem,
      isPlatformShielded: isPlatformShielded,
      isTempMuted: isTempMuted,
      siteName: controller.site.name,
      hasTempMutes: controller.tempMutedUsers.isNotEmpty,
      hasMessageContent: normalizeChatMessageText(message.message).isNotEmpty,
    );
    final action = await showMenu<ChatMessageMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      popUpAnimationStyle: resolveChatMessageMenuAnimationStyle(
        isDesktopPlatform: true,
      ),
      items: [
        for (final spec in specs)
          PopupMenuItem<ChatMessageMenuAction>(
            value: spec.action,
            enabled: spec.enabled,
            child: spec.subtitle == null
                ? Text(spec.label)
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(spec.label),
                    subtitle: Text(
                      spec.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
      ],
    );
    if (action == null) {
      return;
    }
    await controller.handleChatMessageMenuAction(
      action: action,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Obx(
      () {
        late final Widget content;
        if (controller.loadError.value && !controller.isRoomSwitching.value) {
          final errorPresentation = controller.errorPresentation;
          final errorTips = buildLiveRoomErrorContextTips(
            errorType: errorPresentation.type,
            retryCount: controller.mediaErrorRetryCount,
            playUrlCount: controller.playUrls.length,
            currentLineIndex: controller.currentLineIndex,
            qualityCount: controller.qualites.length,
            currentQuality: controller.currentQualityInfo.value,
            currentLine: controller.currentLineInfo.value,
          );
          final errorBody = Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LottieBuilder.asset(
                  'assets/lotties/error.json',
                  height: 140,
                  repeat: false,
                ),
                Text(
                  errorPresentation.title,
                  textAlign: TextAlign.center,
                ),
                AppStyle.vGap4,
                Text(
                  errorPresentation.summary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                AppStyle.vGap4,
                Text(
                  controller.error?.toString() ?? "未知错误",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                AppStyle.vGap4,
                Text(
                  "${controller.rxSite.value.id} - ${controller.rxRoomId.value}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                AppStyle.vGap8,
                Text(
                  errorPresentation.suggestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                AppStyle.vGap8,
                Container(
                  padding: AppStyle.edgeInsetsA12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: AppStyle.radius8,
                    border: Border.all(color: Colors.grey.withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "建议处理顺序",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      AppStyle.vGap8,
                      ...errorTips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Remix.information_line,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              AppStyle.hGap8,
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppStyle.vGap8,
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (controller.playUrls.length > 1)
                      TextButton.icon(
                        onPressed: controller.showPlayUrlsSheet,
                        icon: const Icon(Remix.route_line),
                        label: const Text("切换线路"),
                      ),
                    if (controller.qualites.length > 1)
                      TextButton.icon(
                        onPressed: controller.showQualitySheet,
                        icon: const Icon(Remix.hd_line),
                        label: const Text("切换清晰度"),
                      ),
                    TextButton.icon(
                      onPressed: controller.copyErrorDetail,
                      icon: const Icon(Remix.file_copy_line),
                      label: const Text("复制详情"),
                    ),
                    TextButton.icon(
                      onPressed: controller.openLogDirectory,
                      icon: const Icon(Remix.folder_open_line),
                      label: const Text("打开日志目录"),
                    ),
                    TextButton.icon(
                      onPressed: controller.exportRoomDiagnosticBundle,
                      icon: const Icon(Remix.download_cloud_2_line),
                      label: const Text("导出诊断包"),
                    ),
                    TextButton.icon(
                      onPressed: controller.refreshRoom,
                      icon: const Icon(Remix.refresh_line),
                      label: const Text("刷新"),
                    ),
                  ],
                ),
              ],
            ),
          );
          content = Scaffold(
            body: Column(
              children: [
                buildDesktopTitleBar(context),
                Expanded(child: errorBody),
              ],
            ),
          );
        } else if (controller.nativeFullScreenState.value) {
          content = PopScope(
            canPop: false,
            onPopInvokedWithResult: (e, r) {
              controller.exitNativeFullScreen();
            },
            child: Scaffold(
              body: buildMediaPlayer(),
            ),
          );
        } else {
          content = buildPageUI();
        }

        if (!controller.isRoomSwitching.value &&
            !controller.showInitialLoadRecoveryOverlay &&
            !controller.showPlaybackSwitchOverlay) {
          return content;
        }

        return Stack(
          children: [
            content,
            if (controller.showInitialLoadRecoveryOverlay)
              buildInitialLoadRecoveryOverlay(context),
            if (controller.showPlaybackSwitchOverlay)
              buildPlaybackSwitchOverlay(context),
            if (controller.isRoomSwitching.value)
              buildRoomSwitchingOverlay(context),
          ],
        );
      },
    );
    return page;
  }

  Widget buildRoomSwitchingOverlay(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(90),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: AppStyle.edgeInsetsH12,
            padding: AppStyle.edgeInsetsA16,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppStyle.radius8,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.switchingSiteLogo.value.isNotEmpty) ...[
                  Image.asset(
                    controller.switchingSiteLogo.value,
                    width: 28,
                    height: 28,
                  ),
                  AppStyle.vGap12,
                ],
                const CircularProgressIndicator(strokeWidth: 2.8),
                AppStyle.vGap12,
                Text(
                  "正在切换直播间",
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                AppStyle.vGap4,
                Text(
                  controller.switchingRoomLabel.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInitialLoadRecoveryOverlay(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: Colors.black.withAlpha(56),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              margin: AppStyle.edgeInsetsH12,
              padding: AppStyle.edgeInsetsA16,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: AppStyle.radius8,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(16),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2.4),
                  AppStyle.vGap12,
                  Text(
                    "正在尝试恢复直播间",
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.initialLoadRecoveryLabel.value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  AppStyle.vGap8,
                  const Text(
                    "如果本轮恢复仍失败，会自动切换到错误页。",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlaybackSwitchOverlay(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(48),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: AppStyle.edgeInsetsH12,
            padding: AppStyle.edgeInsetsA16,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppStyle.radius8,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(14),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 2.2),
                AppStyle.vGap12,
                Text(
                  controller.playbackSwitchingLabel.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                AppStyle.vGap8,
                const Text(
                  "切换成功后会自动提交新状态，失败则回退到上一项。",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPageUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopLayout = shouldUseDesktopLiveRoomLayout(
          width: constraints.maxWidth,
          isDesktopPlatform: true,
        );
        final content = useDesktopLayout
            ? buildDesktopUI(context, constraints.maxWidth)
            : (MediaQuery.of(context).orientation == Orientation.portrait
                ? buildPhoneUI(context)
                : buildTabletUI(context));
        return Scaffold(
          body: Column(
            children: [
              buildDesktopTitleBar(context),
              Expanded(
                child: content,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPhoneUI(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: buildMediaPlayer(),
        ),
        buildUserProfile(context),
        buildMessageArea(),
        buildBottomActions(context),
      ],
    );
  }

  Widget buildTabletUI(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: buildMediaPlayer(),
              ),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    buildUserProfile(context),
                    buildMessageArea(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withAlpha(25),
              ),
            ),
          ),
          padding: AppStyle.edgeInsetsV4.copyWith(
            bottom: AppStyle.bottomBarHeight + 4,
          ),
          child: Row(
            children: [
              Obx(
                () => controller.followed.value
                    ? TextButton.icon(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: controller.removeFollowUser,
                        icon: const Icon(Remix.heart_fill),
                        label: const Text("取消关注"),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: controller.followUser,
                        icon: const Icon(Remix.heart_line),
                        label: const Text("关注"),
                      ),
              ),
              AppStyle.hGap4,
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.saveScreenshot,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("截图"),
              ),
              const Expanded(child: Center()),
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.share,
                icon: const Icon(Remix.share_line),
                label: const Text("浏览器打开"),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.copyUrl,
                icon: const Icon(Remix.file_copy_line),
                label: const Text("复制链接"),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.copyPlayUrl,
                icon: const Icon(Remix.file_copy_line),
                label: const Text("复制播放直链"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDesktopUI(BuildContext context, double pageWidth) {
    return Obx(() {
      final sidebarWidth = resolveDesktopSidebarWidth(
        pageWidth,
        customWidth: AppSettingsController.instance.liveRoomSidebarWidth.value,
      );
      final showSidebar = shouldShowDesktopSidebar(
        fillWindowState: controller.fullScreenState.value,
      );
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: buildMediaPlayer(),
                ),
                buildDesktopBottomActions(context),
              ],
            ),
          ),
          if (showSidebar) ...[
            Container(
              width: 1,
              color: Colors.grey.withAlpha(20),
            ),
            SizedBox(
              width: sidebarWidth,
              child: buildDesktopSidebar(),
            ),
          ],
        ],
      );
    });
  }

  Widget buildDesktopTitleBar(BuildContext context) {
    return Container(
      height: DesktopWindowController.kDesktopTitleBarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withAlpha(20)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: "返回",
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Obx(
                  () => Row(
                    children: [
                      Image.asset(
                        controller.site.logo,
                        width: 18,
                        height: 18,
                      ),
                      AppStyle.hGap8,
                      Expanded(
                        child: Text(
                          "${controller.detail.value?.title ?? "直播间"} - ${controller.detail.value?.userName ?? "--"}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      AppStyle.hGap12,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Remix.fire_fill,
                            size: 16,
                            color: Colors.orange,
                          ),
                          AppStyle.hGap4,
                          Text(
                            controller.detail.value == null
                                ? "--"
                                : _buildLiveMetricText(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          WindowCaptionButton.minimize(
            brightness: Theme.of(context).brightness,
            onPressed: controller.minimizeDesktopWindow,
          ),
          Obx(
            () => controller.desktopWindowMaximized.value
                ? WindowCaptionButton.unmaximize(
                    brightness: Theme.of(context).brightness,
                    onPressed: controller.toggleDesktopWindowMaximize,
                  )
                : WindowCaptionButton.maximize(
                    brightness: Theme.of(context).brightness,
                    onPressed: controller.toggleDesktopWindowMaximize,
                  ),
          ),
          WindowCaptionButton.close(
            brightness: Theme.of(context).brightness,
            onPressed: controller.closeDesktopWindow,
          ),
        ],
      ),
    );
  }

  Widget buildDesktopSidebar() {
    return Column(
      children: [
        Expanded(
          child: buildMessageAreaContent(),
        ),
      ],
    );
  }

  Widget buildDesktopBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
        ),
      ),
      padding: AppStyle.edgeInsetsV4.copyWith(
        bottom: AppStyle.bottomBarHeight + 4,
      ),
      child: Row(
        children: [
          Obx(
            () => controller.followed.value
                ? TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: controller.removeFollowUser,
                    icon: const Icon(Remix.heart_fill),
                    label: const Text("取消关注"),
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: controller.followUser,
                    icon: const Icon(Remix.heart_line),
                    label: const Text("关注"),
                  ),
          ),
          AppStyle.hGap4,
          TextButton.icon(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 14),
            ),
            onPressed: controller.saveScreenshot,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text("截图"),
          ),
          const Expanded(child: SizedBox.shrink()),
          TextButton.icon(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 14),
            ),
            onPressed: controller.share,
            icon: const Icon(Remix.share_line),
            label: const Text("浏览器打开"),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 14),
            ),
            onPressed: controller.copyUrl,
            icon: const Icon(Remix.file_copy_line),
            label: const Text("复制链接"),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 14),
            ),
            onPressed: controller.copyPlayUrl,
            icon: const Icon(Remix.file_copy_line),
            label: const Text("复制播放直链"),
          ),
        ],
      ),
    );
  }

  Widget buildMediaPlayer() {
    var boxFit = BoxFit.contain;
    double? aspectRatio;
    if (AppSettingsController.instance.scaleMode.value == 0) {
      boxFit = BoxFit.contain;
    } else if (AppSettingsController.instance.scaleMode.value == 1) {
      boxFit = BoxFit.fill;
    } else if (AppSettingsController.instance.scaleMode.value == 2) {
      boxFit = BoxFit.cover;
    } else if (AppSettingsController.instance.scaleMode.value == 3) {
      boxFit = BoxFit.contain;
      aspectRatio = 16 / 9;
    } else if (AppSettingsController.instance.scaleMode.value == 4) {
      boxFit = BoxFit.contain;
      aspectRatio = 4 / 3;
    }
    return Stack(
      children: [
        Video(
          key: controller.globalPlayerKey,
          controller: controller.videoController,
          pauseUponEnteringBackgroundMode:
              AppSettingsController.instance.playerAutoPause.value,
          resumeUponEnteringForegroundMode:
              AppSettingsController.instance.playerAutoPause.value,
          controls: (state) {
            return playerControls(state, controller);
          },
          aspectRatio: aspectRatio,
          fit: boxFit,
          // 自己实现
          wakelock: false,
        ),
        Obx(
          () => Visibility(
            visible: !controller.liveStatus.value,
            child: const Center(
              child: Text(
                "未开播",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildUserProfile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
          bottom: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
        ),
      ),
      padding: AppStyle.edgeInsetsA8.copyWith(
        left: 12,
        right: 12,
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withAlpha(50)),
                borderRadius: AppStyle.radius24,
              ),
              child: NetImage(
                controller.detail.value?.userAvatar ?? "",
                width: 48,
                height: 48,
                borderRadius: 24,
              ),
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.detail.value?.userName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Row(
                    children: [
                      Image.asset(
                        controller.site.logo,
                        width: 20,
                      ),
                      AppStyle.hGap4,
                      Text(
                        controller.site.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppStyle.hGap12,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Remix.fire_fill,
                  size: 20,
                  color: Colors.orange,
                ),
                AppStyle.hGap4,
                Text(
                  controller.detail.value == null
                      ? "--"
                      : _buildLiveMetricText(),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildLiveMetricText() {
    final detail = controller.detail.value;
    if (detail == null) {
      return "--";
    }
    if (controller.site.id == Constant.kBiliBili) {
      final captainText = controller.detail.value?.captainText ?? "";
      return buildBilibiliMetricText(
        roomAudienceText: controller.roomAudienceText.value,
        online: controller.online.value,
        captainText: captainText,
      );
    }
    return Utils.onlineToString(controller.online.value);
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: AppStyle.bottomBarHeight),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => controller.followed.value
                  ? TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.removeFollowUser,
                      icon: const Icon(Remix.heart_fill),
                      label: const Text("取消关注"),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.followUser,
                      icon: const Icon(Remix.heart_line),
                      label: const Text("关注"),
                    ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.refreshRoom,
              icon: const Icon(Remix.refresh_line),
              label: const Text("刷新"),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.share,
              icon: const Icon(Remix.share_line),
              label: const Text("浏览器打开"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageArea() {
    return Expanded(
      child: buildMessageAreaContent(),
    );
  }

  Widget buildMessageAreaContent() {
    final hasSuperChatTab = controller.site.id == Constant.kBiliBili;
    final currentSidebarTab = resolveLiveRoomSidebarTabForSite(
      controller.sidebarTab.value,
      hasSuperChatTab: hasSuperChatTab,
    );
    return DefaultTabController(
      key: ValueKey('live-room-sidebar-${controller.site.id}'),
      length: liveRoomSidebarTabCount(hasSuperChatTab: hasSuperChatTab),
      initialIndex: liveRoomSidebarTabToIndex(
        currentSidebarTab,
        hasSuperChatTab: hasSuperChatTab,
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withAlpha(25),
                ),
              ),
            ),
            child: TabBar(
              onTap: controller.setSidebarTabFromIndex,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              indicatorWeight: 1.0,
              tabs: [
                const Tab(
                  text: "聊天",
                ),
                if (hasSuperChatTab)
                  Tab(
                    child: Obx(
                      () => Text(
                        controller.superChats.isNotEmpty
                            ? "SC(${controller.superChats.length})"
                            : "SC",
                      ),
                    ),
                  ),
                const Tab(
                  text: "关注",
                ),
                const Tab(
                  text: "设置",
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Obx(
                  () => Stack(
                    children: [
                      ListView.separated(
                        controller: controller.scrollController,
                        separatorBuilder: (_, i) => Obx(
                          () => SizedBox(
                            // *2与原来的EdgeInsets.symmetric(vertical: )做兼容
                            height: AppSettingsController
                                    .instance.chatTextGap.value *
                                2,
                          ),
                        ),
                        padding: AppStyle.edgeInsetsA12,
                        itemCount: controller.messages.length,
                        itemBuilder: (itemContext, i) {
                          var item = controller.messages[i];
                          return buildMessageItem(itemContext, item);
                        },
                      ),
                      Visibility(
                        visible: controller.disableAutoScroll.value,
                        child: Positioned(
                          right: 12,
                          bottom: 12,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              controller.disableAutoScroll.value = false;
                              controller.chatScrollToBottom();
                            },
                            icon: const Icon(Icons.expand_more),
                            label: const Text("最新"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSuperChatTab) buildSuperChats(),
                buildFollowList(),
                buildSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageItem(BuildContext context, LiveMessage message) {
    final child = message.userName == "LiveSysMessage"
        ? Obx(
            () => Text(
              message.message,
              style: TextStyle(
                color: Colors.grey,
                fontSize: AppSettingsController.instance.chatTextSize.value,
              ),
            ),
          )
        : Obx(
            () => AppSettingsController.instance.chatBubbleStyle.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withAlpha(25),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          padding: AppStyle.edgeInsetsA4
                              .copyWith(left: 12, right: 12),
                          child: Text.rich(
                            TextSpan(
                              text: "${message.userName}：",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: AppSettingsController
                                    .instance.chatTextSize.value,
                              ),
                              children: _buildChatMessageSpans(
                                message.message,
                                style: TextStyle(
                                  color: Get.isDarkMode
                                      ? Colors.white
                                      : AppColors.black333,
                                  fontSize: AppSettingsController
                                      .instance.chatTextSize.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text.rich(
                    TextSpan(
                      text: "${message.userName}：",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize:
                            AppSettingsController.instance.chatTextSize.value,
                      ),
                      children: _buildChatMessageSpans(
                        message.message,
                        style: TextStyle(
                          color: Get.isDarkMode
                              ? Colors.white
                              : AppColors.black333,
                          fontSize: AppSettingsController
                              .instance.chatTextSize.value,
                        ),
                      ),
                    ),
                  ),
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        showChatMessageMenu(context, details.globalPosition, message);
      },
      onSecondaryTapDown: (details) {
        showChatMessageMenu(context, details.globalPosition, message);
      },
      onLongPressStart: (details) {
        showChatMessageMenu(context, details.globalPosition, message);
      },
      child: child,
    );
  }

  Widget buildSuperChats() {
    return KeepAliveWrapper(
      child: Obx(
        () {
          final keepSuperChatInPage =
              AppSettingsController.instance.keepSuperChatInPage.value;
          final items = sortSuperChatsForPage(
            controller.superChats,
            keepInPage: keepSuperChatInPage,
          );
          return ListView.separated(
            key: ValueKey('super-chat-list-$keepSuperChatInPage'),
            padding: AppStyle.edgeInsetsA12,
            itemCount: items.length,
            separatorBuilder: (_, i) => AppStyle.vGap12,
            itemBuilder: (_, i) {
              var item = items[i];
              return SuperChatCard(
                item,
                key: ValueKey(
                  '${buildSuperChatKey(item)}-$keepSuperChatInPage',
                ),
                onExpire: () {
                  controller.removeSuperChats();
                },
                showCountdown: !keepSuperChatInPage,
                trailingText: keepSuperChatInPage
                    ? Utils.parseTime(item.startTime)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildSettings() {
    final sidebarWidthHint = resolveDesktopSidebarWidthHint(Get.width);
    return ListView(
      padding: AppStyle.edgeInsetsA12,
      children: [
        Obx(
          () => Visibility(
            visible: controller.autoExitEnable.value,
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              visualDensity: VisualDensity.compact,
              title: Text("${parseDuration(controller.countdown.value)}后自动关闭"),
            ),
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "聊天区",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsNumber(
                  title: "文字大小",
                  value:
                      AppSettingsController.instance.chatTextSize.value.toInt(),
                  min: 8,
                  max: 36,
                  onChanged: (e) {
                    AppSettingsController.instance
                        .setChatTextSize(e.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsNumber(
                  title: "上下间隔",
                  value:
                      AppSettingsController.instance.chatTextGap.value.toInt(),
                  min: 0,
                  max: 12,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatTextGap(e.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "气泡样式",
                  value: AppSettingsController.instance.chatBubbleStyle.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatBubbleStyle(e);
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "播放器中显示SC",
                  value:
                      AppSettingsController.instance.playershowSuperChat.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setPlayerShowSuperChat(e);
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "SC页保留醒目留言",
                  value:
                      AppSettingsController.instance.keepSuperChatInPage.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setKeepSuperChatInPage(e);
                    if (!e) {
                      controller.removeSuperChats();
                    }
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "播放器浮层保留SC",
                  value: AppSettingsController
                      .instance.keepSuperChatInOverlay.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setKeepSuperChatInOverlay(e);
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsInputNumber(
                  title: "保留弹幕数量",
                  subtitle: "输入 0 或留空时使用默认策略",
                  titleTooltip: "默认数量：跟随 300 / 查看历史 1200",
                  value:
                      AppSettingsController.instance.chatMessageRetentionLimit.value,
                  hintText: "",
                  min: 0,
                  max: 5000,
                  onChanged: (value) {
                    AppSettingsController.instance
                        .setChatMessageRetentionLimit(value);
                    controller.trimMessagesForRetention();
                    controller.scheduleChatScrollToBottom();
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsInputNumber(
                  title: "保留 SC 数量",
                  subtitle: "输入 0 或留空时使用默认策略",
                  titleTooltip: "默认数量：普通 30 / 保留 120",
                  value:
                      AppSettingsController.instance.superChatRetentionLimit.value,
                  hintText: "",
                  min: 0,
                  max: 500,
                  onChanged: (value) {
                    AppSettingsController.instance.setSuperChatRetentionLimit(
                      value,
                    );
                    controller.removeSuperChats();
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsInputNumber(
                  title: "右侧栏宽度",
                  subtitle: "只对 Windows 直播间右侧栏生效",
                  value: AppSettingsController.instance.liveRoomSidebarWidth.value,
                  hintText: sidebarWidthHint,
                  min: kDesktopSidebarMinWidth,
                  max: kDesktopSidebarMaxWidth,
                  onChanged: (value) {
                    AppSettingsController.instance.setLiveRoomSidebarWidth(value);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "更多设置",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsAction(
                  title: "切换清晰度",
                  value: controller.currentQualityInfo.value,
                  onTap: controller.showQualitySheet,
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsAction(
                  title: "切换线路",
                  value: controller.currentLineInfo.value,
                  onTap: controller.showPlayUrlsSheet,
                ),
              ),
              AppStyle.divider,
              SettingsAction(
                title: "画面尺寸",
                onTap: controller.showPlayerSettingsSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "关键词屏蔽",
                onTap: controller.showDanmuShield,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "弹幕设置",
                onTap: controller.showDanmuSettingsSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "定时关闭",
                onTap: controller.showAutoExitSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "播放信息",
                onTap: controller.showDebugInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFollowList() {
    return Obx(
      () => Stack(
        children: [
          RefreshIndicator(
            onRefresh: FollowService.instance.loadData,
            child: ListView.builder(
              itemCount: FollowService.instance.liveList.length,
              itemBuilder: (_, i) {
                var item = FollowService.instance.liveList[i];
                return Obx(
                  () => FollowUserItem(
                    item: item,
                    playing: controller.rxSite.value.id == item.siteId &&
                        controller.rxRoomId.value == item.roomId,
                    onTap: () {
                      controller.resetRoom(
                        Sites.allSites[item.siteId]!,
                        item.roomId,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Obx(
              () => DesktopRefreshButton(
                refreshing: FollowService.instance.updating.value,
                onPressed: FollowService.instance.loadData,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildAppbarActions(BuildContext context) {
    return const [];
  }

  void showMore() {
    showModalBottomSheet(
      context: Get.context!,
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: AppStyle.bottomBarHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text("刷新"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.refreshRoom();
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              trailing: const Icon(Icons.chevron_right),
              title: const Text("切换清晰度"),
              onTap: () {
                Get.back();
                controller.showQualitySheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_video_outlined),
              title: const Text("切换线路"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showPlayUrlsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio_outlined),
              title: const Text("画面尺寸"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showPlayerSettingsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("截图"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.saveScreenshot();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text("定时关闭"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showAutoExitSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_sharp),
              title: const Text("浏览器打开"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.share();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("复制链接"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.copyUrl();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text("播放信息"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showDebugInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  String parseDuration(int sec) {
    // 转为时分秒
    var h = sec ~/ 3600;
    var m = (sec % 3600) ~/ 60;
    var s = sec % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}小时${m.toString().padLeft(2, '0')}分钟${s.toString().padLeft(2, '0')}秒";
    }
    if (m > 0) {
      return "${m.toString().padLeft(2, '0')}分钟${s.toString().padLeft(2, '0')}秒";
    }
    return "${s.toString().padLeft(2, '0')}秒";
  }
}

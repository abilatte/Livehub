import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:remixicon/remixicon.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/modules/live_room/follow_history_panel.dart';
import 'package:livehub_app/modules/live_room/live_room_performance_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_controller.dart';
import 'package:livehub_app/modules/live_room/super_chat_utils.dart';
import 'package:livehub_app/modules/settings/danmu_settings_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:livehub_app/widgets/superchat_card.dart';
import 'dart:async';
import 'package:livehub_core/livehub_core.dart';

Widget playerControls(
  VideoState videoState,
  LiveRoomController controller,
) {
  return _PlayerControlsRoot(
    videoState: videoState,
    controller: controller,
  );
}

class _PlayerControlsRoot extends StatelessWidget {
  final VideoState videoState;
  final LiveRoomController controller;

  const _PlayerControlsRoot({
    required this.videoState,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(),
        buildDanmuView(videoState, controller),
        _PlayerSuperChatLayer(controller: controller),
        _PlayerBufferingLayer(videoState: videoState),
        _PlayerGestureLayer(
          videoState: videoState,
          controller: controller,
        ),
        _PlayerModeControlsLayer(
          videoState: videoState,
          controller: controller,
        ),
        _PlayerGestureTipLayer(controller: controller),
      ],
    );
  }
}

class _PlayerSuperChatLayer extends StatelessWidget {
  final LiveRoomController controller;

  const _PlayerSuperChatLayer({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Visibility(
        visible: AppSettingsController.instance.playershowSuperChat.value,
        child: Positioned(
          left: 24,
          bottom: 24,
          child: PlayerSuperChatOverlay(
            key: ValueKey(
              AppSettingsController.instance.keepSuperChatInOverlay.value,
            ),
            controller: controller,
          ),
        ),
      ),
    );
  }
}

class _PlayerBufferingLayer extends StatelessWidget {
  final VideoState videoState;

  const _PlayerBufferingLayer({
    required this.videoState,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder(
        stream: videoState.widget.controller.player.stream.buffering,
        initialData: videoState.widget.controller.player.state.buffering,
        builder: (_, s) => Visibility(
          visible: s.data ?? false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _PlayerGestureLayer extends StatelessWidget {
  final VideoState videoState;
  final LiveRoomController controller;

  const _PlayerGestureLayer({
    required this.videoState,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Obx(() {
        if (controller.useFullScreenLayout) {
          return DragToMoveArea(
              child: GestureDetector(
                onTap: controller.onTap,
                onDoubleTapDown: controller.onDoubleTap,
                onLongPress: () {
                  if (controller.lockControlsState.value) {
                    return;
                  }
                  showFollowUser(controller);
                },
                child: MouseRegion(
                  onHover: (event) {
                    controller.onHover(event, videoState.context);
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ),
          );
        }
        return GestureDetector(
          onTap: controller.onTap,
          onDoubleTapDown: controller.onDoubleTap,
          child: MouseRegion(
            onEnter: controller.onEnter,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        );
      }),
    );
  }
}

class _PlayerModeControlsLayer extends StatelessWidget {
  final VideoState videoState;
  final LiveRoomController controller;

  const _PlayerModeControlsLayer({
    required this.videoState,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.useFullScreenLayout) {
        return buildFullControls(
          videoState,
          controller,
        );
      }
      return buildControls(
        MediaQuery.of(context).orientation == Orientation.portrait,
        videoState,
        controller,
      );
    });
  }
}

class _PlayerGestureTipLayer extends StatelessWidget {
  final LiveRoomController controller;

  const _PlayerGestureTipLayer({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !controller.showGestureTip.value,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              controller.gestureTipText.value,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildFullControls(
  VideoState videoState,
  LiveRoomController controller,
) {
  var padding = MediaQuery.of(videoState.context).padding;
  GlobalKey volumeButtonkey = GlobalKey();
  return Stack(
    children: [
      // 顶部
      Obx(
        () => AnimatedPositioned(
          left: 0,
          right: 0,
          top: (controller.showControlsState.value &&
                  !controller.lockControlsState.value)
              ? 0
              : -(48 + padding.top),
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 48 + padding.top,
            padding: EdgeInsets.only(
              left: padding.left + 12,
              right: padding.right + 12,
              top: padding.top,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    controller.exitNativeFullScreen();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                AppStyle.hGap12,
                Expanded(
                  child: Text(
                    "${controller.detail.value?.title} - ${controller.detail.value?.userName}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                AppStyle.hGap12,
                IconButton(
                  onPressed: () {
                    controller.saveScreenshot();
                  },
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showFollowUser(controller);
                  },
                  icon: const Icon(
                    Remix.play_list_2_line,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showPlayerSettings(controller);
                  },
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // 底部
      Obx(
        () => AnimatedPositioned(
          left: 0,
          right: 0,
          bottom: (controller.showControlsState.value &&
                  !controller.lockControlsState.value)
              ? 0
              : -(80 + padding.bottom),
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
            padding: EdgeInsets.only(
              left: padding.left + 12,
              right: padding.right + 12,
              bottom: padding.bottom,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    controller.refreshRoom();
                  },
                  icon: const Icon(
                    Remix.refresh_line,
                    color: Colors.white,
                  ),
                ),
                Offstage(
                  offstage: controller.showDanmakuState.value,
                  child: IconButton(
                    onPressed: () => controller.showDanmakuState.value =
                        !controller.showDanmakuState.value,
                    icon: const ImageIcon(
                      AssetImage('assets/icons/icon_danmaku_open.png'),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                Offstage(
                  offstage: !controller.showDanmakuState.value,
                  child: IconButton(
                    onPressed: () => controller.showDanmakuState.value =
                        !controller.showDanmakuState.value,
                    icon: const ImageIcon(
                      AssetImage('assets/icons/icon_danmaku_close.png'),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDanmakuSettings(controller);
                  },
                  icon: const ImageIcon(
                    AssetImage('assets/icons/icon_danmaku_setting.png'),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      controller.liveDuration.value,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const Expanded(child: Center()),
                Visibility(
                  visible: true,
                  child: IconButton(
                    key: volumeButtonkey,
                    onPressed: () {
                      controller
                          .showVolumeSlider(volumeButtonkey.currentContext!);
                    },
                    icon: const Icon(
                      Icons.volume_down,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showQualitesInfo(controller);
                  },
                  child: Obx(
                    () => Text(
                      controller.currentQualityInfo.value,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showLinesInfo(controller);
                  },
                  child: Obx(
                    () => Text(
                      controller.currentLineInfo.value,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
                Tooltip(
                  message: "切换到铺满窗口",
                  child: IconButton(
                    onPressed: () {
                      controller.exitNativeFullScreen();
                    },
                    icon: const Icon(
                      Icons.fit_screen,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.exitNativeFullScreen(keepFillWindow: false);
                  },
                  icon: const Icon(
                    Remix.fullscreen_exit_fill,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // 右侧锁定
      Obx(
        () => AnimatedPositioned(
          top: 0,
          bottom: 0,
          right: controller.showControlsState.value
              ? padding.right + 12
              : -(64 + padding.right),
          duration: const Duration(milliseconds: 200),
          child: buildLockButton(controller),
        ),
      ),
      // 左侧锁定
      Obx(
        () => AnimatedPositioned(
          top: 0,
          bottom: 0,
          left: controller.showControlsState.value
              ? padding.left + 12
              : -(64 + padding.right),
          duration: const Duration(milliseconds: 200),
          child: buildLockButton(controller),
        ),
      ),
    ],
  );
}

Widget buildLockButton(LiveRoomController controller) {
  return Center(
    child: InkWell(
      onTap: () {
        controller.setLockState();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: AppStyle.radius8,
        ),
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            controller.lockControlsState.value
                ? Icons.lock_outline_rounded
                : Icons.lock_open_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    ),
  );
}

Widget buildControls(
  bool isPortrait,
  VideoState videoState,
  LiveRoomController controller,
) {
  GlobalKey volumeButtonkey = GlobalKey();
  return Stack(
    children: [
      Obx(
        () => AnimatedPositioned(
          left: 0,
          right: 0,
          bottom: controller.showControlsState.value ? 0 : -48,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    controller.refreshRoom();
                  },
                  icon: const Icon(
                    Remix.refresh_line,
                    color: Colors.white,
                  ),
                ),
                Offstage(
                  offstage: controller.showDanmakuState.value,
                  child: IconButton(
                    onPressed: () => controller.showDanmakuState.value =
                        !controller.showDanmakuState.value,
                    icon: const ImageIcon(
                      AssetImage('assets/icons/icon_danmaku_open.png'),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                Offstage(
                  offstage: !controller.showDanmakuState.value,
                  child: IconButton(
                    onPressed: () => controller.showDanmakuState.value =
                        !controller.showDanmakuState.value,
                    icon: const ImageIcon(
                      AssetImage('assets/icons/icon_danmaku_close.png'),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.showDanmuSettingsSheet();
                  },
                  icon: const ImageIcon(
                    AssetImage('assets/icons/icon_danmaku_setting.png'),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      controller.liveDuration.value,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const Expanded(child: Center()),
                Visibility(
                  visible: true,
                  child: IconButton(
                    key: volumeButtonkey,
                    onPressed: () {
                      controller.showVolumeSlider(
                        volumeButtonkey.currentContext!,
                      );
                    },
                    icon: const Icon(
                      Icons.volume_down,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                Offstage(
                  offstage: isPortrait,
                  child: TextButton(
                    onPressed: () {
                      controller.showQualitySheet();
                    },
                    child: Obx(
                      () => Text(
                        controller.currentQualityInfo.value,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
                Offstage(
                  offstage: isPortrait,
                  child: TextButton(
                    onPressed: () {
                      controller.showPlayUrlsSheet();
                    },
                    child: Obx(
                      () => Text(
                        controller.currentLineInfo.value,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Tooltip(
                    message: controller.fullScreenState.value ? "退出铺满窗口" : "铺满窗口",
                    child: IconButton(
                      onPressed: () {
                        controller.toggleFillWindow();
                      },
                      icon: Icon(
                        controller.fullScreenState.value
                            ? Icons.close_fullscreen
                            : Icons.fit_screen,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: "全屏",
                  child: IconButton(
                    onPressed: () {
                      controller.enterFullScreen();
                    },
                    icon: const Icon(
                      Remix.fullscreen_line,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildDanmuView(VideoState videoState, LiveRoomController controller) {
  var padding = MediaQuery.of(videoState.context).padding;
  final settings = AppSettingsController.instance;
  controller.danmakuView ??= DanmakuScreen(
    key: controller.globalDanmuKey,
    createdController: controller.initDanmakuController,
    option: DanmakuOption(
      fontSize: settings.danmuSize.value,
      // Pin a CJK font on Windows to avoid per-glyph fallback cost.
      fontFamily: Platform.isWindows ? "Microsoft YaHei" : null,
      area: settings.danmuArea.value,
      duration: settings.danmuSpeed.value,
      opacity: settings.danmuOpacity.value,
      strokeWidth: settings.danmuStrokeWidth.value,
      fontWeight: settings.danmuFontWeight.value,
    ),
  );
  return Positioned.fill(
    top: padding.top,
    bottom: padding.bottom,
    child: Obx(
      () => Offstage(
        offstage: !controller.showDanmakuState.value,
        child: Padding(
          padding: controller.useFullScreenLayout
              ? EdgeInsets.only(
                  top: AppSettingsController.instance.danmuTopMargin.value,
                  bottom:
                      AppSettingsController.instance.danmuBottomMargin.value,
                )
              : EdgeInsets.zero,
          child: controller.danmakuView!,
        ),
      ),
    ),
  );
}

void showLinesInfo(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showPlayUrlsSheet();
    return;
  }
  Utils.showRightDialog(
    title: "线路",
    useSystem: true,
    child: ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.playUrls.length,
      itemBuilder: (_, i) {
        return ListTile(
          selected: controller.currentLineIndex == i,
          title: Text.rich(
            TextSpan(
              text: "线路${i + 1}",
              children: [
                WidgetSpan(
                    child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppStyle.radius4,
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  padding: AppStyle.edgeInsetsH4,
                  margin: AppStyle.edgeInsetsL8,
                  child: Text(
                    controller.playUrls[i].contains(".flv") ? "FLV" : "HLS",
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
            ),
            style: const TextStyle(fontSize: 14),
          ),
          minLeadingWidth: 16,
          onTap: () {
            Utils.hideRightDialog();
            //controller.currentLineIndex = i;
            //controller.setPlayer();
            controller.changePlayLine(i);
          },
        );
      },
    ),
  );
}

void showQualitesInfo(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showQualitySheet();
    return;
  }
  Utils.showRightDialog(
    title: "清晰度",
    useSystem: true,
    child: ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.qualites.length,
      itemBuilder: (_, i) {
        var item = controller.qualites[i];
        return ListTile(
          selected: controller.currentQuality == i,
          title: Text(
            item.quality,
            style: const TextStyle(fontSize: 14),
          ),
          minLeadingWidth: 16,
          onTap: () {
            Utils.hideRightDialog();
            controller.currentQuality = i;
            controller.getPlayUrl();
          },
        );
      },
    ),
  );
}

void showDanmakuSettings(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showDanmuSettingsSheet();
    return;
  }
  Utils.showRightDialog(
    title: "弹幕设置",
    width: 400,
    useSystem: true,
    child: ListView(
      padding: AppStyle.edgeInsetsA12,
      children: [
        DanmuSettingsView(
          danmakuController: controller.danmakuController,
        ),
      ],
    ),
  );
}

void showPlayerSettings(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showPlayerSettingsSheet();
    return;
  }
  Utils.showRightDialog(
    title: "设置",
    width: 320,
    useSystem: true,
    child: Obx(
      () => RadioGroup(
        groupValue: AppSettingsController.instance.scaleMode.value,
        onChanged: (e) {
          AppSettingsController.instance.setScaleMode(e ?? 0);
          controller.updateScaleMode();
        },
        child: ListView(
          padding: AppStyle.edgeInsetsV12,
          children: [
            Padding(
              padding: AppStyle.edgeInsetsH16,
              child: Text(
                "画面尺寸",
                style: Get.textTheme.titleMedium,
              ),
            ),
            const RadioListTile(
              value: 0,
              contentPadding: AppStyle.edgeInsetsH4,
              title: Text("适应"),
              visualDensity: VisualDensity.compact,
            ),
            const RadioListTile(
              value: 1,
              contentPadding: AppStyle.edgeInsetsH4,
              title: Text("拉伸"),
              visualDensity: VisualDensity.compact,
            ),
            const RadioListTile(
              value: 2,
              contentPadding: AppStyle.edgeInsetsH4,
              title: Text("铺满"),
              visualDensity: VisualDensity.compact,
            ),
            const RadioListTile(
              value: 3,
              contentPadding: AppStyle.edgeInsetsH4,
              title: Text("16:9"),
              visualDensity: VisualDensity.compact,
            ),
            const RadioListTile(
              value: 4,
              contentPadding: AppStyle.edgeInsetsH4,
              title: Text("4:3"),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    ),
  );
}

void showFollowUser(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showFollowUserSheet();
    return;
  }

  Utils.showRightDialog(
    title: "关注与历史",
    width: 400,
    useSystem: true,
    child: FollowHistoryPanel(
      controller: controller,
      onClose: Utils.hideRightDialog,
    ),
  );
}

class PlayerSuperChatCard extends StatelessWidget {
  final LiveSuperChatMessage message;
  final int countdown;
  const PlayerSuperChatCard(
      {required this.message, required this.countdown, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.65,
      child: SuperChatCard(
        message,
        onExpire: () {},
        customCountdown: countdown,
      ),
    );
  }
}

class LocalDisplaySC {
  final LiveSuperChatMessage sc;
  final DateTime expireAt;
  LocalDisplaySC(this.sc, this.expireAt);
}

class PlayerSuperChatOverlay extends StatefulWidget {
  final LiveRoomController controller;
  const PlayerSuperChatOverlay({required this.controller, Key? key})
      : super(key: key);
  @override
  State<PlayerSuperChatOverlay> createState() => _PlayerSuperChatOverlayState();
}

class _PlayerSuperChatOverlayState extends State<PlayerSuperChatOverlay> {
  final List<LocalDisplaySC> _displayed = [];
  late Worker _worker;
  Timer? _ticker;

  String _keyOf(LiveSuperChatMessage sc) => buildSuperChatKey(sc);

  bool _containsDisplayed(LiveSuperChatMessage sc) {
    final key = _keyOf(sc);
    return _displayed.any((item) => _keyOf(item.sc) == key);
  }

  void _removeDisplayedSC(LocalDisplaySC localSC) {
    _displayed.remove(localSC);
  }

  void _addSC(LiveSuperChatMessage sc, {int? customSeconds}) {
    if (_containsDisplayed(sc)) {
      return;
    }
    final showSeconds = customSeconds ??
        resolveOverlayDisplaySeconds(
          sc,
          keepInOverlay:
              AppSettingsController.instance.keepSuperChatInOverlay.value,
        );
    if (showSeconds <= 0) {
      return;
    }
    final expireAt = DateTime.now().add(Duration(seconds: showSeconds));
    final localSC = LocalDisplaySC(sc, expireAt);
    _displayed.add(localSC);
    _ensureTicker();
    setState(() {});
  }

  void _pruneExpiredDisplayedSCs() {
    _displayed.removeWhere(
      (item) => remainingOverlaySeconds(item.expireAt) <= 0,
    );
  }

  void _ensureTicker() {
    if (_displayed.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pruneExpiredDisplayedSCs();
      });
      if (_displayed.isEmpty) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    for (var sc in widget.controller.superChats) {
      _addSC(sc);
    }
    _pruneExpiredDisplayedSCs();
    _ensureTicker();
    // 监听SC列表变化
    _worker =
        ever<List<LiveSuperChatMessage>>(widget.controller.superChats, (list) {
      // 新增
      for (var sc in list) {
        if (!_containsDisplayed(sc)) {
          _addSC(sc);
        }
      }
      // 移除
      final keepKeys = list.map(_keyOf).toSet();
      final removedItems = _displayed
          .where((item) => !keepKeys.contains(_keyOf(item.sc)))
          .toList();
      for (final item in removedItems) {
        _removeDisplayedSC(item);
      }
      _pruneExpiredDisplayedSCs();
      _ensureTicker();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _displayed.toList()
      ..sort((a, b) => b.expireAt.compareTo(a.expireAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var localSC in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 240,
              child: PlayerSuperChatCard(
                message: localSC.sc,
                countdown: remainingOverlaySeconds(localSC.expireAt),
              ),
            ),
          ),
      ],
    );
  }
}

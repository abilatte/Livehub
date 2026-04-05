import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/controller/base_controller.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/modules/live_room/player/player_performance_utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

mixin PlayerMixin {
  GlobalKey<VideoState> globalPlayerKey = GlobalKey<VideoState>();
  GlobalKey globalDanmuKey = GlobalKey();

  /// 播放器实例
  late final player = Player(
    configuration: PlayerConfiguration(
      title: "LiveHub Player",
      logLevel: AppSettingsController.instance.logEnable.value
          ? MPVLogLevel.info
          : MPVLogLevel.error,
    ),
  );

  /// 初始化播放器并设置 ao 参数
  Future<void> initializePlayer() async {
    var pp = player.platform as NativePlayer;
    // 设置音频输出驱动
    if (AppSettingsController.instance.customPlayerOutput.value) {
      if (player.platform is NativePlayer) {
        await (player.platform as dynamic).setProperty(
          'ao',
          AppSettingsController.instance.audioOutputDriver.value,
        );
      }
    }
  }

  /// 视频控制器
  late final videoController = VideoController(
    player,
    configuration: AppSettingsController.instance.customPlayerOutput.value
        ? VideoControllerConfiguration(
            vo: AppSettingsController.instance.videoOutputDriver.value,
            hwdec: AppSettingsController.instance.videoHardwareDecoder.value,
          )
        : AppSettingsController.instance.playerCompatMode.value
            ? const VideoControllerConfiguration(
                vo: 'mediacodec_embed',
                hwdec: 'mediacodec',
              )
            : VideoControllerConfiguration(
                enableHardwareAcceleration:
                    AppSettingsController.instance.hardwareDecode.value,
                androidAttachSurfaceAfterVideoParameters: false,
              ),
  );
}

mixin PlayerStateMixin on PlayerMixin {
  ///音量控制条计时器
  Timer? hidevolumeTimer;

  /// 是否显示弹幕
  RxBool showDanmakuState = false.obs;

  /// 是否显示控制器
  RxBool showControlsState = false.obs;

  /// 是否显示设置窗口
  RxBool showSettingState = false.obs;

  /// 是否显示弹幕设置窗口
  RxBool showDanmakuSettingState = false.obs;

  /// 是否处于锁定控制器状态
  RxBool lockControlsState = false.obs;

  /// 是否处于全屏状态
  RxBool fullScreenState = false.obs;

  /// 是否处于系统级真全屏状态
  RxBool nativeFullScreenState = false.obs;

  /// 桌面端正在进入全屏，用于提前切换页面布局
  RxBool enteringFullScreenState = false.obs;

  /// 桌面端窗口是否最大化
  RxBool desktopWindowMaximized = false.obs;

  /// 显示手势Tip
  RxBool showGestureTip = false.obs;

  /// 手势Tip文本
  RxString gestureTipText = "".obs;

  /// 显示提示底部Tip
  RxBool showBottomTip = false.obs;

  /// 提示底部Tip文本
  RxString bottomTipText = "".obs;

  /// 自动隐藏控制器计时器
  Timer? hideControlsTimer;

  /// 自动隐藏提示计时器
  Timer? hideSeekTipTimer;

  /// 是否为竖屏直播间
  var isVertical = false.obs;

  Widget? danmakuView;

  var showQualites = false.obs;
  var showLines = false.obs;

  bool get useFullScreenLayout =>
      resolvePlayerControlLayoutMode(
        nativeFullScreenState: nativeFullScreenState.value,
        enteringFullScreenState: enteringFullScreenState.value,
        smallWindowState: false,
      ) ==
      PlayerControlLayoutMode.fullScreen;

  /// 隐藏控制器
  void hideControls() {
    showControlsState.value = false;
    hideControlsTimer?.cancel();
  }

  void setLockState() {
    lockControlsState.value = !lockControlsState.value;
    if (lockControlsState.value) {
      showControlsState.value = false;
    } else {
      showControlsState.value = true;
    }
  }

  /// 显示控制器
  void showControls() {
    showControlsState.value = true;
    resetHideControlsTimer();
  }

  /// 开始隐藏控制器计时
  /// - 当点击控制器上时功能时需要重新计时
  void resetHideControlsTimer() {
    hideControlsTimer?.cancel();

    hideControlsTimer = Timer(
      const Duration(
        seconds: 5,
      ),
      hideControls,
    );
  }

  void updateScaleMode() {
    var boxFit = BoxFit.contain;
    double? aspectRatio;
    if (player.state.width != null && player.state.height != null) {
      aspectRatio = player.state.width! / player.state.height!;
    }

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
    globalPlayerKey.currentState?.update(
      aspectRatio: aspectRatio,
      fit: boxFit,
    );
  }
}
mixin PlayerDanmakuMixin on PlayerStateMixin {
  /// 弹幕控制器
  DanmakuController? danmakuController;

  void initDanmakuController(DanmakuController e) {
    danmakuController = e;
    // danmakuController?.updateOption(
    //   DanmakuOption(
    //     fontSize: AppSettingsController.instance.danmuSize.value,
    //     area: AppSettingsController.instance.danmuArea.value,
    //     duration: AppSettingsController.instance.danmuSpeed.value,
    //     opacity: AppSettingsController.instance.danmuOpacity.value,
    //     strokeWidth: AppSettingsController.instance.danmuStrokeWidth.value,
    //     fontWeight: FontWeight
    //         .values[AppSettingsController.instance.danmuFontWeight.value],
    //   ),
    // );
  }

  void updateDanmuOption(DanmakuOption? option) {
    if (danmakuController == null || option == null) return;
    danmakuController!.updateOption(option);
  }

  void disposeDanmakuController() {
    danmakuController?.clear();
  }

  void addDanmaku(List<DanmakuContentItem> items) {
    if (!showDanmakuState.value) {
      return;
    }
    for (var item in items) {
      danmakuController?.addDanmaku(item);
    }
  }
}
mixin PlayerSystemMixin on PlayerMixin, PlayerStateMixin, PlayerDanmakuMixin {
  int _desktopFullScreenToken = 0;

  /// 初始化一些系统状态
  void initSystem() async {
    // 开始隐藏计时
    resetHideControlsTimer();

    // 进入全屏模式
    if (AppSettingsController.instance.autoFullScreen.value) {
      enterFullScreen();
    }
  }

  /// 释放一些系统状态
  Future resetSystem() async {
    await WakelockPlus.disable();
  }

  Future<void> _enterDesktopNativeFullScreen(int token) async {
    try {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setFullScreen(true);

      final isNativeFullScreen = await _waitDesktopFullScreenState(
        expected: true,
      );
      if (!_isCurrentDesktopFullScreenToken(token)) {
        return;
      }
      if (!isNativeFullScreen) {
        return;
      }
      nativeFullScreenState.value = true;
      fullScreenState.value = true;
    } catch (e, s) {
      if (_isCurrentDesktopFullScreenToken(token)) {
        Log.e("进入桌面全屏失败：$e", s);
        try {
          await windowManager.setFullScreen(false);
        } catch (_) {}
      }
    } finally {
      if (_isCurrentDesktopFullScreenToken(token)) {
        enteringFullScreenState.value = false;
      }
    }
  }

  Future<void> _exitDesktopNativeFullScreen(
    int token, {
    required bool keepFillWindow,
  }) async {
    try {
      await windowManager.setFullScreen(false);
      nativeFullScreenState.value = false;
      if (!keepFillWindow) {
        fullScreenState.value = false;
      }
    } catch (e, s) {
      if (_isCurrentDesktopFullScreenToken(token)) {
        Log.e("退出桌面全屏失败：$e", s);
      }
    }
  }

  bool _isCurrentDesktopFullScreenToken(int token) {
    return _desktopFullScreenToken == token;
  }

  Future<bool> _waitDesktopFullScreenState({
    required bool expected,
  }) async {
    for (final delay in const <Duration>[
      Duration.zero,
      Duration(milliseconds: 16),
      Duration(milliseconds: 48),
    ]) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      final current = await windowManager.isFullScreen();
      if (current == expected) {
        return true;
      }
      if (delay == const Duration(milliseconds: 16)) {
        await windowManager.setFullScreen(expected);
      }
    }
    return await windowManager.isFullScreen() == expected;
  }

  /// 进入全屏
  Future<void> enterFullScreen() async {
    if (nativeFullScreenState.value || enteringFullScreenState.value) {
      return;
    }

    final token = ++_desktopFullScreenToken;
    enteringFullScreenState.value = true;
    unawaited(_enterDesktopNativeFullScreen(token));
  }

  Future<void> enterFillWindow() async {
    if (fullScreenState.value) {
      return;
    }
    fullScreenState.value = true;
    showControlsState.value = false;
  }

  Future<void> exitFillWindow() async {
    if (nativeFullScreenState.value || enteringFullScreenState.value) {
      await exitNativeFullScreen(keepFillWindow: false);
      return;
    }
    fullScreenState.value = false;
  }

  Future<void> toggleFillWindow() async {
    if (fullScreenState.value) {
      await exitFillWindow();
    } else {
      await enterFillWindow();
    }
  }

  /// 退出页面全屏
  Future<void> exitFull() async {
    if (nativeFullScreenState.value || enteringFullScreenState.value) {
      await exitNativeFullScreen();
      return;
    }

    if (!fullScreenState.value) {
      return;
    }

    fullScreenState.value = false;
  }

  Future<void> exitNativeFullScreen({
    bool keepFillWindow = true,
  }) async {
    if (!nativeFullScreenState.value && !enteringFullScreenState.value) {
      return;
    }

    final token = ++_desktopFullScreenToken;
    enteringFullScreenState.value = false;
    nativeFullScreenState.value = false;
    if (!keepFillWindow) {
      fullScreenState.value = false;
    }
    unawaited(
      _exitDesktopNativeFullScreen(
        token,
        keepFillWindow: keepFillWindow,
      ),
    );
  }

  Future<void> minimizeDesktopWindow() async {
    await windowManager.minimize();
  }

  Future<void> toggleDesktopWindowMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
      desktopWindowMaximized.value = false;
    } else {
      await windowManager.maximize();
      desktopWindowMaximized.value = true;
    }
  }

  Future<void> closeDesktopWindow() async {
    await windowManager.close();
  }

  Future<void> syncDesktopWindowMaximizedState() async {
    desktopWindowMaximized.value = await windowManager.isMaximized();
  }

  Future saveScreenshot() async {
    try {
      SmartDialog.showLoading(msg: "正在保存截图");
      var imageData = await player.screenshot();
      if (imageData == null) {
        SmartDialog.showToast("截图失败,数据为空");
        SmartDialog.dismiss(status: SmartStatus.loading);
        return;
      }

      var path = await FilePicker.platform.saveFile(
        allowedExtensions: ["jpg"],
        type: FileType.image,
        fileName: "${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      if (path == null) {
        SmartDialog.showToast("取消保存");
        SmartDialog.dismiss(status: SmartStatus.loading);
        return;
      }
      var file = File(path);
      await file.writeAsBytes(imageData);
      SmartDialog.showToast("已保存截图至${file.path}");
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast("截图失败");
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

}
mixin PlayerGestureControlMixin
    on PlayerStateMixin, PlayerMixin, PlayerSystemMixin {
  /// 单击显示/隐藏控制器
  void onTap() {
    if (showControlsState.value) {
      hideControls();
    } else {
      showControls();
    }
  }

  //桌面端操控
  void onEnter(PointerEnterEvent event) {
    if (!showControlsState.value) {
      showControls();
    }
  }

  void onExit(PointerExitEvent event) {
    if (showControlsState.value) {
      hideControls();
    }
  }

  void onHover(PointerHoverEvent event, BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    if (shouldShowDesktopControlsOnHover(
      localDy: event.localPosition.dy,
      viewportHeight: viewportHeight,
    )) {
      if (!showControlsState.value) {
        showControls();
      }
    }
  }

  /// 双击全屏/退出全屏
  void onDoubleTap(TapDownDetails details) {
    if (lockControlsState.value || enteringFullScreenState.value) {
      return;
    }
    toggleFillWindow();
  }
}

class PlayerController extends BaseController
    with
        PlayerMixin,
        PlayerStateMixin,
        PlayerDanmakuMixin,
        PlayerSystemMixin,
        PlayerGestureControlMixin {
  @override
  void onInit() {
    initSystem();
    initStream();
    //设置音量
    player.setVolume(AppSettingsController.instance.playerVolume.value);
    super.onInit();
  }

  StreamSubscription<String>? _errorSubscription;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _widthSubscription;
  StreamSubscription? _heightSubscription;
  StreamSubscription? _logSubscription;
  StreamSubscription? _playingSubscription;
  num? _lastVideoWidth;
  num? _lastVideoHeight;

  bool get _verbosePlayerStreamLoggingEnabled =>
      shouldEnableVerbosePlayerStreamLogging(
        logEnabled: AppSettingsController.instance.logEnable.value,
        isDebugMode: kDebugMode,
      );

  void initStream() {
    _errorSubscription = player.stream.error.listen((event) {
      Log.d("播放器错误：$event");
      // 跳过无音频输出的错误
      // Could not open/initialize audio device -> no sound.
      if (event.contains('no sound.')) {
        return;
      }
      //SmartDialog.showToast(event);
      mediaError(event);
    });

    _playingSubscription = player.stream.playing.listen((event) {
      if (event) {
        WakelockPlus.enable();
        if (_verbosePlayerStreamLoggingEnabled) {
          Log.d("播放器开始播放");
        }
      }
    });

    _completedSubscription = player.stream.completed.listen((event) {
      if (event) {
        mediaEnd();
      }
    });
    _logSubscription = _verbosePlayerStreamLoggingEnabled
        ? player.stream.log.listen((event) {
            Log.d("播放器日志：$event");
          })
        : null;
    _widthSubscription = player.stream.width.listen((_) {
      _syncVideoOrientation();
    });
    _heightSubscription = player.stream.height.listen((_) {
      _syncVideoOrientation();
    });
  }

  void disposeStream() {
    _errorSubscription?.cancel();
    _completedSubscription?.cancel();
    _widthSubscription?.cancel();
    _heightSubscription?.cancel();
    _logSubscription?.cancel();
    _playingSubscription?.cancel();
    _lastVideoWidth = null;
    _lastVideoHeight = null;
  }

  void mediaEnd() {
    WakelockPlus.disable();
  }

  void mediaError(String error) {
    WakelockPlus.disable();
  }

  void _syncVideoOrientation() {
    final width = player.state.width;
    final height = player.state.height;
    if (!hasPlayerVideoSizeChanged(
      previousWidth: _lastVideoWidth,
      previousHeight: _lastVideoHeight,
      nextWidth: width,
      nextHeight: height,
    )) {
      return;
    }

    _lastVideoWidth = width;
    _lastVideoHeight = height;

    final nextIsVertical = resolveIsVerticalLiveRoom(
      width: width,
      height: height,
      fallback: isVertical.value,
    );
    if (nextIsVertical != isVertical.value) {
      isVertical.value = nextIsVertical;
    }

    if (_verbosePlayerStreamLoggingEnabled) {
      Log.d("播放器尺寸：${width ?? '-'} x ${height ?? '-'}，竖屏：$nextIsVertical");
    }
  }

  void showDebugInfo() {
    Utils.showBottomSheet(
      title: "播放信息",
      child: ListView(
        children: [
          ListTile(
            title: const Text("Resolution"),
            subtitle: Text('${player.state.width}x${player.state.height}'),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      "Resolution\n${player.state.width}x${player.state.height}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("VideoParams"),
            subtitle: Text(player.state.videoParams.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "VideoParams\n${player.state.videoParams}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("AudioParams"),
            subtitle: Text(player.state.audioParams.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "AudioParams\n${player.state.audioParams}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("Media"),
            subtitle: Text(player.state.playlist.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "Media\n${player.state.playlist}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("AudioTrack"),
            subtitle: Text(player.state.track.audio.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "AudioTrack\n${player.state.track.audio}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("VideoTrack"),
            subtitle: Text(player.state.track.video.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "VideoTrack\n${player.state.track.audio}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("AudioBitrate"),
            subtitle: Text(player.state.audioBitrate.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "AudioBitrate\n${player.state.audioBitrate}",
                ),
              );
            },
          ),
          ListTile(
            title: const Text("Volume"),
            subtitle: Text(player.state.volume.toString()),
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: "Volume\n${player.state.volume}",
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void onClose() async {
    Log.w("播放器关闭");
    disposeStream();
    disposeDanmakuController();
    await resetSystem();
    await player.dispose();
    super.onClose();
  }
}

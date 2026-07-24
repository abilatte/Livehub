import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/event_bus.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/app/version_utils.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/models/db/history.dart';
import 'package:livehub_app/modules/live_room/chat_message_menu_utils.dart';
import 'package:livehub_app/modules/live_room/follow_history_panel.dart';
import 'package:livehub_app/modules/live_room/live_room_diagnostic_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_error_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_metric_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_playback_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_playback_switch_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_performance_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_reset_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_sidebar_tab_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_startup_recovery_utils.dart';
import 'package:livehub_app/modules/live_room/player/player_controller.dart';
import 'package:livehub_app/modules/live_room/super_chat_utils.dart';
import 'package:livehub_app/modules/settings/danmu_settings_page.dart';
import 'package:livehub_app/services/db_service.dart';
import 'package:livehub_app/services/diagnostic_service.dart';
import 'package:livehub_app/services/follow_service.dart';
import 'package:livehub_core/livehub_core.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

class LiveRoomController extends PlayerController
    with WidgetsBindingObserver, WindowListener {
  final Site pSite;
  final String pRoomId;
  late LiveDanmaku liveDanmaku;
  LiveRoomController({
    required this.pSite,
    required this.pRoomId,
  }) {
    rxSite = pSite.obs;
    rxRoomId = pRoomId.obs;
    liveDanmaku = site.liveSite.getDanmaku();
    // 抖音应该默认是竖屏的
    if (site.id == "douyin") {
      isVertical.value = true;
    }
  }

  late Rx<Site> rxSite;
  Site get site => rxSite.value;
  late Rx<String> rxRoomId;
  String get roomId => rxRoomId.value;

  Rx<LiveRoomDetail?> detail = Rx<LiveRoomDetail?>(null);
  var online = 0.obs;
  var roomAudienceText = "".obs;
  var followed = false.obs;
  var liveStatus = false.obs;
  RxList<LiveSuperChatMessage> superChats = RxList<LiveSuperChatMessage>();
  final Set<String> _superChatKeys = <String>{};
  final sidebarTab = LiveRoomSidebarTab.chat.obs;

  /// 滚动控制
  final ScrollController scrollController = ScrollController();

  /// 聊天信息
  RxList<LiveMessage> messages = RxList<LiveMessage>();

  /// 当前直播间会话内的临时禁言用户（不持久化）。
  final tempMutedUsers = <String>{}.obs;

  /// 清晰度数据
  RxList<LivePlayQuality> qualites = RxList<LivePlayQuality>();

  /// 当前清晰度
  var currentQuality = -1;
  var currentQualityInfo = "".obs;

  /// 线路数据
  RxList<String> playUrls = RxList<String>();

  Map<String, String>? playHeaders;

  /// 当前线路
  var currentLineIndex = -1;
  var currentLineInfo = "".obs;

  /// 退出倒计时
  var countdown = 60.obs;

  Timer? autoExitTimer;

  /// 设置的自动关闭时间（分钟）
  var autoExitMinutes = 60.obs;

  ///是否延迟自动关闭
  var delayAutoExit = false.obs;

  /// 是否启用自动关闭
  var autoExitEnable = false.obs;

  /// 是否禁用自动滚动聊天栏
  /// - 当用户向上滚动聊天栏时，不再自动滚动
  var disableAutoScroll = false.obs;

  /// 是否处于后台
  var isBackground = false;

  /// 直播间加载失败
  var loadError = false.obs;
  Object? error;
  StackTrace? errorStackTrace;

  // 开播时长状态变量
  var liveDuration = "00:00:00".obs;
  Timer? _liveDurationTimer;
  int _roomLoadToken = 0;
  bool _chatScrollScheduled = false;
  final isRoomSwitching = false.obs;
  final switchingRoomLabel = ''.obs;
  final switchingSiteLogo = ''.obs;
  final isSwitchingPlaybackSource = false.obs;
  final playbackSwitchingLabel = ''.obs;
  final isRecoveringInitialLoad = false.obs;
  final initialLoadRecoveryLabel = ''.obs;
  int initialLoadRecoveryCount = 0;
  bool _initialLoadSettled = false;
  LiveRoomPlaybackSwitchRequest? _pendingPlaybackSwitch;
  Timer? _pendingPlaybackSwitchTimer;
  bool _isRestoringPlaybackSwitch = false;
  StreamSubscription<bool>? _playerPlayingSubscription;

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_prepareDesktopWindowChrome());
    if (FollowService.instance.followList.isEmpty) {
      FollowService.instance.loadData(updateStatus: false);
    }
    initAutoExit();
    showDanmakuState.value = AppSettingsController.instance.danmuEnable.value;
    followed.value = DBService.instance.getFollowExist(
      buildLiveRoomRecordId(site.id, roomId),
    );
    beginInitialLoadSession();
    _playerPlayingSubscription = player.stream.playing.listen((event) {
      if (event) {
        commitPendingPlaybackSwitch();
        completeInitialLoadSession();
      }
    });
    unawaited(loadData());

    scrollController.addListener(scrollListener);

    super.onInit();
  }

  void scrollListener() {
    if (!scrollController.hasClients) {
      return;
    }
    final extentAfter = scrollController.position.extentAfter;
    if (shouldEnableChatAutoScroll(extentAfter: extentAfter)) {
      if (disableAutoScroll.value) {
        disableAutoScroll.value = false;
      }
      return;
    }
    if (shouldDisableChatAutoScroll(
      extentAfter: extentAfter,
      userScrollDirection: scrollController.position.userScrollDirection,
    )) {
      disableAutoScroll.value = true;
    }
  }

  /// 初始化自动关闭倒计时
  void initAutoExit() {
    if (AppSettingsController.instance.autoExitEnable.value) {
      autoExitEnable.value = true;
      autoExitMinutes.value =
          AppSettingsController.instance.autoExitDuration.value;
      setAutoExit();
    } else {
      autoExitMinutes.value =
          AppSettingsController.instance.roomAutoExitDuration.value;
    }
  }

  void setAutoExit() {
    if (!autoExitEnable.value) {
      autoExitTimer?.cancel();
      return;
    }
    autoExitTimer?.cancel();
    countdown.value = autoExitMinutes.value * 60;
    autoExitTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdown.value -= 1;
      if (countdown.value <= 0) {
        timer = Timer(const Duration(seconds: 10), () async {
          await WakelockPlus.disable();
          await Utils.exitApplication();
        });
        autoExitTimer?.cancel();
        var delay = await Utils.showAlertDialog("定时关闭已到时,是否延迟关闭?",
            title: "延迟关闭", confirm: "延迟", cancel: "关闭", selectable: true);
        if (delay) {
          timer.cancel();
          delayAutoExit.value = true;
          showAutoExitSheet();
          setAutoExit();
        } else {
          delayAutoExit.value = false;
          await WakelockPlus.disable();
          await Utils.exitApplication();
        }
      }
    });
  }
  // 弹窗逻辑

  void refreshRoom() {
    //messages.clear();
    beginInitialLoadSession();
    _roomLoadToken += 1;
    clearSuperChats();
    liveDanmaku.stop();

    unawaited(loadData());
  }

  void resetTransientRoomState() {
    messages.clear();
    clearSuperChats();
    qualites.clear();
    playUrls.clear();
    playHeaders = null;
    currentQuality = -1;
    currentQualityInfo.value = "";
    currentLineIndex = -1;
    currentLineInfo.value = "";
    online.value = 0;
    roomAudienceText.value = "";
    liveStatus.value = false;
    loadError.value = false;
    error = null;
    errorStackTrace = null;
    disableAutoScroll.value = false;
    detail.value = null;
    liveDuration.value = "00:00:00";
    _liveDurationTimer?.cancel();
  }

  void setSidebarTabFromIndex(int index) {
    sidebarTab.value = liveRoomSidebarTabFromIndex(
      index,
      hasSuperChatTab: site.id == Constant.kBiliBili,
    );
  }

  LiveRoomErrorPresentation get errorPresentation =>
      resolveLiveRoomErrorPresentation(error);

  bool get isInitialLoadPending => !_initialLoadSettled;

  bool get showInitialLoadRecoveryOverlay =>
      shouldShowInitialLoadRecoveryOverlay(
        isRecoveringInitialLoad: isRecoveringInitialLoad.value,
        loadError: loadError.value,
        isRoomSwitching: isRoomSwitching.value,
      );

  bool get showPlaybackSwitchOverlay =>
      isSwitchingPlaybackSource.value &&
      !isRoomSwitching.value &&
      !showInitialLoadRecoveryOverlay;

  void beginInitialLoadSession() {
    _initialLoadSettled = false;
    isRecoveringInitialLoad.value = false;
    initialLoadRecoveryLabel.value = '';
    initialLoadRecoveryCount = 0;
    _pendingPlaybackSwitch = null;
    _pendingPlaybackSwitchTimer?.cancel();
    clearPlaybackSwitchingState();
    errorMsg.value = '';
  }

  void completeInitialLoadSession() {
    _initialLoadSettled = true;
    isRecoveringInitialLoad.value = false;
    initialLoadRecoveryLabel.value = '';
    initialLoadRecoveryCount = 0;
  }

  void beginPlaybackSwitching({
    required LiveRoomPlaybackSwitchKind kind,
    required String targetLabel,
  }) {
    isSwitchingPlaybackSource.value = true;
    playbackSwitchingLabel.value = buildPlaybackSwitchLabel(
      kind: kind,
      targetLabel: targetLabel,
    );
    errorMsg.value = '';
  }

  void clearPlaybackSwitchingState() {
    isSwitchingPlaybackSource.value = false;
    playbackSwitchingLabel.value = '';
  }

  void schedulePendingPlaybackSwitchCommit({
    Duration delay = const Duration(milliseconds: 800),
  }) {
    _pendingPlaybackSwitchTimer?.cancel();
    _pendingPlaybackSwitchTimer = Timer(delay, () {
      if (_pendingPlaybackSwitch != null && !_isRestoringPlaybackSwitch) {
        commitPendingPlaybackSwitch();
      }
    });
  }

  LiveRoomPlaybackSnapshot capturePlaybackSnapshot() {
    return LiveRoomPlaybackSnapshot(
      qualityIndex: currentQuality,
      qualityLabel: currentQualityInfo.value,
      playUrls: List<String>.from(playUrls),
      playHeaders:
          playHeaders == null ? null : Map<String, String>.from(playHeaders!),
      lineIndex: currentLineIndex,
      lineLabel: currentLineInfo.value,
    );
  }

  Future<void> openPlaybackSources({
    required List<String> urls,
    Map<String, String>? headers,
    int initialIndex = 0,
  }) async {
    final mediaList = normalizePlaybackUrls(
      urls,
      forceHttps: AppSettingsController.instance.playerForceHttps.value,
    ).map((url) => Media(url, httpHeaders: headers)).toList();

    await initializePlayer();
    await player.open(Playlist(mediaList));
    if (initialIndex > 0) {
      await player.jump(initialIndex);
    }
  }

  void commitPendingPlaybackSwitch() {
    final pending = _pendingPlaybackSwitch;
    if (pending == null) {
      return;
    }
    _pendingPlaybackSwitchTimer?.cancel();
    currentQuality = pending.targetQualityIndex;
    currentQualityInfo.value = pending.targetQualityLabel;
    playUrls.value = List<String>.from(pending.targetPlayUrls);
    playHeaders = pending.targetPlayHeaders == null
        ? null
        : Map<String, String>.from(pending.targetPlayHeaders!);
    currentLineIndex = pending.targetLineIndex;
    currentLineInfo.value = pending.targetLineLabel;
    mediaErrorRetryCount = 0;
    errorMsg.value = '';
    _pendingPlaybackSwitch = null;
    clearPlaybackSwitchingState();
  }

  Future<void> rollbackPendingPlaybackSwitch({
    required Object rawError,
    StackTrace? stackTrace,
  }) async {
    final pending = _pendingPlaybackSwitch;
    if (pending == null) {
      _pendingPlaybackSwitchTimer?.cancel();
      clearPlaybackSwitchingState();
      return;
    }

    _pendingPlaybackSwitchTimer?.cancel();
    _pendingPlaybackSwitch = null;
    clearPlaybackSwitchingState();

    if (!canRestorePlaybackSnapshot(pending.previous)) {
      presentLiveRoomLoadError(rawError, stackTrace);
      return;
    }

    try {
      _isRestoringPlaybackSwitch = true;
      currentQuality = pending.previous.qualityIndex;
      currentQualityInfo.value = pending.previous.qualityLabel;
      playUrls.value = List<String>.from(pending.previous.playUrls);
      playHeaders = pending.previous.playHeaders == null
          ? null
          : Map<String, String>.from(pending.previous.playHeaders!);
      currentLineIndex = pending.previous.lineIndex;
      currentLineInfo.value = pending.previous.lineLabel;
      mediaErrorRetryCount = 0;
      errorMsg.value = '';
      await openPlaybackSources(
        urls: pending.previous.playUrls,
        headers: pending.previous.playHeaders,
        initialIndex: pending.previous.lineIndex,
      );
      SmartDialog.showToast(buildPlaybackSwitchRollbackToast(pending.kind));
    } catch (e, s) {
      Log.e("回退播放切换失败：$e", s);
      presentLiveRoomLoadError(rawError, stackTrace ?? s);
    } finally {
      _isRestoringPlaybackSwitch = false;
    }
  }

  void presentLiveRoomLoadError(
    Object rawError, [
    StackTrace? stackTrace,
  ]) {
    _pendingPlaybackSwitch = null;
    _pendingPlaybackSwitchTimer?.cancel();
    loadError.value = true;
    error = rawError;
    errorStackTrace = stackTrace;
    errorMsg.value = '';
    isRecoveringInitialLoad.value = false;
    initialLoadRecoveryLabel.value = '';
    _initialLoadSettled = true;
    update();
  }

  bool scheduleInitialLoadRecovery({
    required Object rawError,
    required StackTrace? stackTrace,
    required String errorType,
    required int sourceLoadToken,
  }) {
    if (!shouldAttemptInitialLoadRecovery(
      errorType: errorType,
      recoveryCount: initialLoadRecoveryCount,
      initialLoadSettled: _initialLoadSettled,
    )) {
      return false;
    }

    final nextAttempt = initialLoadRecoveryCount + 1;
    final retryDelay = resolveInitialLoadRecoveryDelay(initialLoadRecoveryCount);
    error = rawError;
    errorStackTrace = stackTrace;
    errorMsg.value = '';
    loadError.value = false;
    isRecoveringInitialLoad.value = true;
    initialLoadRecoveryLabel.value = buildInitialLoadRecoveryLabel(
      errorType: errorType,
      nextAttempt: nextAttempt,
    );
    initialLoadRecoveryCount = nextAttempt;
    Log.d('首屏恢复中：$errorType，第 $nextAttempt 次自动重试');

    unawaited(Future<void>(() async {
      if (retryDelay > Duration.zero) {
        await Future.delayed(retryDelay);
      }
      if (!_isCurrentRoomLoadToken(sourceLoadToken)) {
        return;
      }
      await loadData(
        showGlobalLoading: false,
        isInitialRecoveryAttempt: true,
      );
    }));
    return true;
  }

  bool handleInitialLoadFailure({
    required Object rawError,
    StackTrace? stackTrace,
    required int sourceLoadToken,
  }) {
    if (!isInitialLoadPending) {
      return false;
    }

    final presentation = resolveLiveRoomErrorPresentation(rawError);
    if (scheduleInitialLoadRecovery(
      rawError: rawError,
      stackTrace: stackTrace,
      errorType: presentation.type,
      sourceLoadToken: sourceLoadToken,
    )) {
      return true;
    }

    presentLiveRoomLoadError(rawError, stackTrace);
    return true;
  }

  void clearSuperChats() {
    superChats.clear();
    _superChatKeys.clear();
  }

  void trimMessagesForRetention() {
    final trimCount = resolveChatTrimCount(
      nextCount: messages.length,
      autoScrollDisabled: disableAutoScroll.value,
      customLimit:
          AppSettingsController.instance.chatMessageRetentionLimit.value,
    );
    if (trimCount <= 0 || trimCount > messages.length) {
      return;
    }
    messages.removeRange(0, trimCount);
  }

  void trimSuperChatsForRetention() {
    final trimCount = resolveSuperChatTrimCount(
      nextCount: superChats.length,
      keepInPage: AppSettingsController.instance.keepSuperChatInPage.value,
      customLimit: AppSettingsController.instance.superChatRetentionLimit.value,
    );
    if (trimCount <= 0) {
      return;
    }
    superChats.removeRange(0, trimCount);
    syncSuperChatKeys();
  }

  bool addSuperChat(LiveSuperChatMessage message) {
    final key = buildSuperChatKey(message);
    if (_superChatKeys.contains(key)) {
      return false;
    }
    _superChatKeys.add(key);
    superChats.add(message);
    trimSuperChatsForRetention();
    return true;
  }

  void addSuperChats(Iterable<LiveSuperChatMessage> messages) {
    for (final message in messages) {
      addSuperChat(message);
    }
  }

  void syncSuperChatKeys() {
    _superChatKeys
      ..clear()
      ..addAll(superChats.map(buildSuperChatKey));
  }

  void appendRoomMessage(LiveMessage message) {
    final trimCount = resolveChatTrimCount(
      nextCount: messages.length + 1,
      autoScrollDisabled: disableAutoScroll.value,
      customLimit:
          AppSettingsController.instance.chatMessageRetentionLimit.value,
    );
    if (trimCount > 0) {
      messages.removeRange(0, trimCount);
    }
    messages.add(message);
  }

  bool _isCurrentRoomLoadToken(int token) => _roomLoadToken == token;

  /// 聊天栏始终滚动到底部
  void chatScrollToBottom() {
    _chatScrollScheduled = false;
    if (scrollController.hasClients) {
      // 如果手动上拉过，就不自动滚动到底部
      if (disableAutoScroll.value) {
        return;
      }
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      if (maxScrollExtent <= 0) {
        return;
      }
      scrollController.jumpTo(maxScrollExtent);
    }
  }

  void scheduleChatScrollToBottom() {
    if (_chatScrollScheduled || disableAutoScroll.value) {
      return;
    }
    _chatScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        _chatScrollScheduled = false;
        return;
      }
      chatScrollToBottom();
    });
  }

  /// 初始化弹幕接收事件
  void initDanmau() {
    liveDanmaku.onMessage = onWSMessage;
    liveDanmaku.onClose = onWSClose;
    liveDanmaku.onReady = onWSReady;
  }

  /// 接收到WebSocket信息
  void onWSMessage(LiveMessage msg) {
    if (msg.type == LiveMessageType.chat) {
      final userName = normalizeChatUserName(msg.userName);
      if (userName.isNotEmpty &&
          !isChatSystemMessage(userName) &&
          shouldDropChatMessage(
            userName: userName,
            message: msg.message,
            siteId: site.id,
            tempMutedUsers: tempMutedUsers,
          )) {
        return;
      }

      appendRoomMessage(msg);
      scheduleChatScrollToBottom();
      if (!liveStatus.value || isBackground) {
        return;
      }

      addDanmaku([
        DanmakuContentItem(
          msg.message,
          color: Color.fromARGB(
            255,
            msg.color.r,
            msg.color.g,
            msg.color.b,
          ),
        ),
      ]);
    } else if (msg.type == LiveMessageType.online) {
      if (site.id == Constant.kBiliBili) {
        if (msg.data is Map) {
          final data = msg.data as Map;
          if (data["source"] == "audience") {
            final audienceText = data["text"]?.toString() ?? "";
            if (audienceText.isNotEmpty) {
              roomAudienceText.value = audienceText;
            }
            final audienceValue = data["value"];
            if (audienceValue is int) {
              online.value = audienceValue;
            }
          }
        }
        return;
      }
      online.value = msg.data;
    } else if (msg.type == LiveMessageType.superChat) {
      addSuperChat(msg.data as LiveSuperChatMessage);
      removeSuperChats();
    }
  }

  /// 添加一条系统消息
  void addSysMsg(String msg) {
    appendRoomMessage(
      LiveMessage(
        type: LiveMessageType.chat,
        userName: "LiveSysMessage",
        message: msg,
        color: LiveMessageColor.white,
      ),
    );
    scheduleChatScrollToBottom();
  }

  /// 接收到WebSocket关闭信息
  void onWSClose(String msg) {
    addSysMsg(msg);
  }

  /// WebSocket准备就绪
  void onWSReady() {
    addSysMsg("弹幕服务器连接正常");
  }

  /// 加载直播间信息
  Future<void> loadData({
    int? reuseLoadToken,
    LiveRoomDetail? prefetchedDetail,
    bool showGlobalLoading = true,
    bool isInitialRecoveryAttempt = false,
  }) async {
    final loadToken = reuseLoadToken ?? ++_roomLoadToken;
    try {
      if (showGlobalLoading) {
        SmartDialog.showLoading(msg: "");
      }
      if (!isInitialRecoveryAttempt) {
        isRecoveringInitialLoad.value = false;
        initialLoadRecoveryLabel.value = '';
      }
      loadError.value = false;
      error = null;
      errorStackTrace = null;
      update();
      addSysMsg("正在读取直播间信息");
      final roomDetail = prefetchedDetail ??
          await site.liveSite.getRoomDetail(roomId: roomId);
      if (!_isCurrentRoomLoadToken(loadToken)) {
        return;
      }
      detail.value = roomDetail;

      if (site.id == Constant.kDouyin) {
        // 1.6.0之前收藏的WebRid
        // 1.6.0收藏的RoomID
        // 1.6.0之后改回WebRid
        if (detail.value!.roomId != roomId) {
          var oldId = roomId;
          rxRoomId.value = detail.value!.roomId;
          if (followed.value) {
            // 更新关注列表
            DBService.instance.deleteFollow(
              buildLiveRoomRecordId(site.id, oldId),
            );
            DBService.instance.addFollow(
              FollowUser(
                id: buildLiveRoomRecordId(site.id, roomId),
                roomId: roomId,
                siteId: site.id,
                userName: detail.value!.userName,
                face: detail.value!.userAvatar,
                addTime: DateTime.now(),
              ),
            );
          } else {
            followed.value =
                DBService.instance.getFollowExist(
                  buildLiveRoomRecordId(site.id, roomId),
                );
          }
        }
      }

      getSuperChatMessage(loadToken: loadToken);

      addHistory();
      // 确认房间关注状态
      followed.value = DBService.instance.getFollowExist(
        buildLiveRoomRecordId(site.id, roomId),
      );
      if (site.id == Constant.kBiliBili) {
        online.value = detail.value!.online;
        roomAudienceText.value = detail.value!.watchedText ?? "";
      } else {
        online.value = detail.value!.online;
      }
      liveStatus.value = detail.value!.status || detail.value!.isRecord;
      if (liveStatus.value) {
        await getPlayQualitesForInitialLoad(loadToken: loadToken);
      } else {
        completeInitialLoadSession();
      }
      if (detail.value!.isRecord) {
        addSysMsg("当前主播未开播，正在轮播录像");
      }
      if (!_isCurrentRoomLoadToken(loadToken)) {
        return;
      }
      if (detail.value?.danmakuData is BiliBiliDanmakuUnavailable) {
        addSysMsg(resolveDanmakuStatusMessage(detail.value?.danmakuData));
      } else if (shouldStartDanmaku(detail.value?.danmakuData)) {
        addSysMsg("开始连接弹幕服务器");
        initDanmau();
        liveDanmaku.start(detail.value?.danmakuData);
      } else {
        addSysMsg(resolveDanmakuStatusMessage(detail.value?.danmakuData));
      }
      startLiveDurationTimer(); // 启动开播时长定时器
    } catch (e, s) {
      if (!_isCurrentRoomLoadToken(loadToken)) {
        return;
      }
      Log.e(e.toString(), s);
      if (handleInitialLoadFailure(
        rawError: e,
        stackTrace: s,
        sourceLoadToken: loadToken,
      )) {
        return;
      }
      presentLiveRoomLoadError(e, s);
    } finally {
      if (showGlobalLoading && _isCurrentRoomLoadToken(loadToken)) {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    }
  }

  /// 初始化播放器
  Future<void> getPlayQualites({int? loadToken}) async {
    qualites.clear();
    currentQuality = -1;

    try {
      var playQualites =
          await site.liveSite.getPlayQualites(detail: detail.value!);
      if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
        return;
      }

      if (playQualites.isEmpty) {
        SmartDialog.showToast("无法读取播放清晰度");
        return;
      }
      qualites.value = playQualites;
      final qualityLevel = await getQualityLevel();
      currentQuality = resolveInitialQualityIndex(
        qualityCount: playQualites.length,
        qualityLevel: qualityLevel,
      );
      await getPlayUrl(loadToken: loadToken);
    } catch (e) {
      if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
        return;
      }
      Log.logPrint(e);
      SmartDialog.showToast("无法读取播放清晰度");
    }
  }

  Future<int> getQualityLevel() async {
    return AppSettingsController.instance.qualityLevel.value;
  }

  Future<void> getPlayUrl({int? loadToken}) async {
    playUrls.clear();
    currentQualityInfo.value = qualites[currentQuality].quality;
    currentLineInfo.value = "";
    currentLineIndex = -1;
    final currentDetail = detail.value;
    if (currentDetail == null) {
      return;
    }
    var playUrl = await site.liveSite
        .getPlayUrls(detail: currentDetail, quality: qualites[currentQuality]);
    if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
      return;
    }
    if (playUrl.urls.isEmpty) {
      SmartDialog.showToast("无法读取播放地址");
      return;
    }
    playUrls.value = playUrl.urls;
    playHeaders = playUrl.headers;
    currentLineIndex = 0;
    currentLineInfo.value = buildLiveRoomLineLabel(currentLineIndex);
    //重置错误次数
    mediaErrorRetryCount = 0;
    await initPlaylist();
  }

  Future<void> getPlayQualitesForInitialLoad({int? loadToken}) async {
    qualites.clear();
    currentQuality = -1;

    final playQualites =
        await site.liveSite.getPlayQualites(detail: detail.value!);
    if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
      return;
    }
    if (playQualites.isEmpty) {
      throw StateError('player quality unavailable');
    }

    qualites.value = playQualites;
    final qualityLevel = await getQualityLevel();
    currentQuality = resolveInitialQualityIndex(
      qualityCount: playQualites.length,
      qualityLevel: qualityLevel,
    );
    await getPlayUrlForInitialLoad(loadToken: loadToken);
  }

  Future<void> getPlayUrlForInitialLoad({int? loadToken}) async {
    playUrls.clear();
    currentQualityInfo.value = qualites[currentQuality].quality;
    currentLineInfo.value = "";
    currentLineIndex = -1;
    final currentDetail = detail.value;
    if (currentDetail == null) {
      throw StateError('room detail unavailable');
    }

    final playUrl = await site.liveSite
        .getPlayUrls(detail: currentDetail, quality: qualites[currentQuality]);
    if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
      return;
    }
    if (playUrl.urls.isEmpty) {
      throw StateError('player stream unavailable');
    }

    playUrls.value = playUrl.urls;
    playHeaders = playUrl.headers;
    currentLineIndex = 0;
    currentLineInfo.value = buildLiveRoomLineLabel(currentLineIndex);
    mediaErrorRetryCount = 0;
    await initPlaylist();
  }

  Future<void> switchPlaybackQuality(int nextQualityIndex) async {
    if (!shouldStartPlaybackSwitch(
      isSwitchingPlaybackSource: isSwitchingPlaybackSource.value,
      currentIndex: currentQuality,
      nextIndex: nextQualityIndex,
      itemCount: qualites.length,
    )) {
      return;
    }

    final currentDetail = detail.value;
    if (currentDetail == null) {
      return;
    }

    final snapshot = capturePlaybackSnapshot();
    final nextQuality = qualites[nextQualityIndex];
    beginPlaybackSwitching(
      kind: LiveRoomPlaybackSwitchKind.quality,
      targetLabel: nextQuality.quality,
    );

    try {
      final playUrl = await site.liveSite
          .getPlayUrls(detail: currentDetail, quality: nextQuality);
      if (playUrl.urls.isEmpty) {
        throw StateError('player stream unavailable');
      }
      _pendingPlaybackSwitch = LiveRoomPlaybackSwitchRequest.forQuality(
        previous: snapshot,
        targetQualityIndex: nextQualityIndex,
        targetQualityLabel: nextQuality.quality,
        targetPlayUrls: playUrl.urls,
        targetPlayHeaders: playUrl.headers,
        targetLineLabel: buildLiveRoomLineLabel(0),
      );
      await openPlaybackSources(
        urls: playUrl.urls,
        headers: playUrl.headers,
      );
      schedulePendingPlaybackSwitchCommit();
    } catch (e, s) {
      Log.e("切换清晰度失败：$e", s);
      if (_pendingPlaybackSwitch != null) {
        await rollbackPendingPlaybackSwitch(
          rawError: e,
          stackTrace: s,
        );
      } else {
        clearPlaybackSwitchingState();
        if (canRestorePlaybackSnapshot(snapshot)) {
          SmartDialog.showToast(
            buildPlaybackSwitchRollbackToast(
              LiveRoomPlaybackSwitchKind.quality,
            ),
          );
        } else {
          SmartDialog.showToast("切换清晰度失败");
        }
      }
    }
  }

  Future<void> switchPlaybackLine(int nextLineIndex) async {
    if (!shouldStartPlaybackSwitch(
      isSwitchingPlaybackSource: isSwitchingPlaybackSource.value,
      currentIndex: currentLineIndex,
      nextIndex: nextLineIndex,
      itemCount: playUrls.length,
    )) {
      return;
    }

    final snapshot = capturePlaybackSnapshot();
    final targetLineLabel = buildLiveRoomLineLabel(nextLineIndex);
    beginPlaybackSwitching(
      kind: LiveRoomPlaybackSwitchKind.line,
      targetLabel: targetLineLabel,
    );
    _pendingPlaybackSwitch = LiveRoomPlaybackSwitchRequest.forLine(
      previous: snapshot,
      targetLineIndex: nextLineIndex,
      targetLineLabel: targetLineLabel,
    );

    try {
      await player.jump(nextLineIndex);
      schedulePendingPlaybackSwitchCommit();
    } catch (e, s) {
      Log.e("切换线路失败：$e", s);
      await rollbackPendingPlaybackSwitch(
        rawError: e,
        stackTrace: s,
      );
    }
  }

  void changePlayLine(int index) {
    currentLineIndex = index;
    //重置错误次数
    mediaErrorRetryCount = 0;
    setPlayer();
  }

  Future<void> initPlaylist() async {
    currentLineInfo.value = buildLiveRoomLineLabel(currentLineIndex);
    errorMsg.value = "";

    final mediaList = normalizePlaybackUrls(
      playUrls,
      forceHttps: AppSettingsController.instance.playerForceHttps.value,
    ).map((url) => Media(url, httpHeaders: playHeaders)).toList();

    // 初始化播放器并设置 ao 参数
    await initializePlayer();

    await player.open(Playlist(mediaList));
  }

  void setPlayer() async {
    currentLineInfo.value = buildLiveRoomLineLabel(currentLineIndex);
    errorMsg.value = "";

    await player.jump(currentLineIndex);
  }

  @override
  void mediaEnd() async {
    super.mediaEnd();
    if (_pendingPlaybackSwitch != null && !_isRestoringPlaybackSwitch) {
      await rollbackPendingPlaybackSwitch(
        rawError: StateError('player stream ended during playback switch'),
      );
      return;
    }
    final hasRetryBudget =
        shouldRetryPlayback(retryCount: mediaErrorRetryCount);
    if (!hasRetryBudget &&
        !hasNextPlayLine(
          currentLineIndex: currentLineIndex,
          playUrlCount: playUrls.length,
        ) &&
        handleInitialLoadFailure(
          rawError: StateError('player stream ended during initial load'),
          sourceLoadToken: _roomLoadToken,
        )) {
      return;
    }
    if (hasRetryBudget) {
      Log.d("播放结束，尝试第${mediaErrorRetryCount + 1}次刷新");
      final retryDelay = resolvePlaybackRetryDelay(mediaErrorRetryCount);
      if (retryDelay > Duration.zero) {
        await Future.delayed(retryDelay);
      }
      mediaErrorRetryCount = nextPlaybackRetryCount(mediaErrorRetryCount);
      //刷新一次
      setPlayer();
      return;
    }

    Log.d("播放结束");
    // 遍历线路，如果全部链接都断开就是直播结束了
    if (!hasNextPlayLine(
      currentLineIndex: currentLineIndex,
      playUrlCount: playUrls.length,
    )) {
      liveStatus.value = false;
    } else {
      changePlayLine(currentLineIndex + 1);

      //setPlayer();
    }
  }

  int mediaErrorRetryCount = 0;
  @override
  void mediaError(String error) async {
    super.mediaError(error);
    if (_pendingPlaybackSwitch != null && !_isRestoringPlaybackSwitch) {
      await rollbackPendingPlaybackSwitch(
        rawError: Exception(error),
        stackTrace: StackTrace.current,
      );
      return;
    }
    final hasRetryBudget =
        shouldRetryPlayback(retryCount: mediaErrorRetryCount);
    if (!hasRetryBudget &&
        !hasNextPlayLine(
          currentLineIndex: currentLineIndex,
          playUrlCount: playUrls.length,
        ) &&
        handleInitialLoadFailure(
          rawError: Exception(error),
          stackTrace: StackTrace.current,
          sourceLoadToken: _roomLoadToken,
        )) {
      return;
    }
    if (hasRetryBudget) {
      Log.d("播放失败，尝试第${mediaErrorRetryCount + 1}次刷新");
      final retryDelay = resolvePlaybackRetryDelay(mediaErrorRetryCount);
      if (retryDelay > Duration.zero) {
        await Future.delayed(retryDelay);
      }
      mediaErrorRetryCount = nextPlaybackRetryCount(mediaErrorRetryCount);
      //刷新一次
      setPlayer();
      return;
    }

    if (!hasNextPlayLine(
      currentLineIndex: currentLineIndex,
      playUrlCount: playUrls.length,
    )) {
      errorMsg.value = "播放失败";
      SmartDialog.showToast("播放失败:$error");
    } else {
      //currentLineIndex += 1;
      //setPlayer();
      changePlayLine(currentLineIndex + 1);
    }
  }

  /// 读取SC
  void getSuperChatMessage({int? loadToken}) async {
    try {
      final currentDetail = detail.value;
      if (currentDetail == null) {
        return;
      }
      var sc =
          await site.liveSite.getSuperChatMessage(roomId: currentDetail.roomId);
      if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
        return;
      }
      addSuperChats(sc);
      removeSuperChats();
    } catch (e) {
      if (loadToken != null && !_isCurrentRoomLoadToken(loadToken)) {
        return;
      }
      Log.logPrint(e);
      addSysMsg("SC读取失败");
    }
  }

  /// 移除掉已到期的SC
  void removeSuperChats() async {
    if (!AppSettingsController.instance.keepSuperChatInPage.value) {
      var now = DateTime.now().millisecondsSinceEpoch;
      superChats.value = superChats
          .where((x) => x.endTime.millisecondsSinceEpoch > now)
          .toList();
    }
    trimSuperChatsForRetention();
    syncSuperChatKeys();
  }

  /// 添加历史记录
  void addHistory() {
    if (detail.value == null) {
      return;
    }
    var id = buildLiveRoomRecordId(site.id, roomId);
    var history = DBService.instance.getHistory(id);
    if (history != null) {
      history.updateTime = DateTime.now();
    }
    history ??= History(
      id: id,
      roomId: roomId,
      siteId: site.id,
      userName: detail.value?.userName ?? "",
      face: detail.value?.userAvatar ?? "",
      updateTime: DateTime.now(),
    );

    DBService.instance.addOrUpdateHistory(history);
  }

  /// 关注用户
  void followUser() {
    if (detail.value == null) {
      return;
    }
    var id = buildLiveRoomRecordId(site.id, roomId);
    DBService.instance.addFollow(
      FollowUser(
        id: id,
        roomId: roomId,
        siteId: site.id,
        userName: detail.value?.userName ?? "",
        face: detail.value?.userAvatar ?? "",
        addTime: DateTime.now(),
      ),
    );
    followed.value = true;
    EventBus.instance.emit(Constant.kUpdateFollow, id);
  }

  /// 取消关注用户
  void removeFollowUser() async {
    if (detail.value == null) {
      return;
    }
    if (!await Utils.showAlertDialog("确定要取消关注该用户吗？", title: "取消关注")) {
      return;
    }

    var id = buildLiveRoomRecordId(site.id, roomId);
    DBService.instance.deleteFollow(id);
    followed.value = false;
    EventBus.instance.emit(Constant.kUpdateFollow, id);
  }

  Future<void> share() async {
    if (detail.value == null) {
      return;
    }
    await launchUrlString(
      detail.value!.url,
      mode: LaunchMode.externalApplication,
    );
  }

  void copyUrl() {
    if (detail.value == null) {
      return;
    }
    Utils.copyToClipboard(detail.value!.url);
    SmartDialog.showToast("已复制直播间链接");
  }

  /// 复制新生成的直播流
  void copyPlayUrl() async {
    // 未开播不复制
    if (!liveStatus.value) {
      return;
    }
    var playUrl = await site.liveSite
        .getPlayUrls(detail: detail.value!, quality: qualites[currentQuality]);
    if (playUrl.urls.isEmpty) {
      SmartDialog.showToast("无法读取播放地址");
      return;
    }
    Utils.copyToClipboard(playUrl.urls.first);
    SmartDialog.showToast("已复制播放直链");
  }

  /// 底部打开播放器设置
  void showDanmuSettingsSheet() {
    Utils.showBottomSheet(
      title: "弹幕设置",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          DanmuSettingsView(
            danmakuController: danmakuController,
            onTapDanmuShield: () {
              Get.back();
              showDanmuShield();
            },
          ),
        ],
      ),
    );
  }

  void showVolumeSlider(BuildContext targetContext) {
    SmartDialog.showAttach(
      targetContext: targetContext,
      alignment: Alignment.topCenter,
      displayTime: const Duration(seconds: 3),
      maskColor: const Color(0x00000000),
      builder: (_) => _VolumeSliderPopover(player: player),
    );
  }

  void showQualitySheet() {
    Utils.showBottomSheet(
      title: "切换清晰度",
      child: RadioGroup(
        groupValue: currentQuality,
        onChanged: (e) {
          Get.back();
          unawaited(switchPlaybackQuality(e ?? 0));
        },
        child: ListView.builder(
          itemCount: qualites.length,
          itemBuilder: (_, i) {
            var item = qualites[i];
            return RadioListTile(
              value: i,
              title: Text(item.quality),
            );
          },
        ),
      ),
    );
  }

  void showPlayUrlsSheet() {
    Utils.showBottomSheet(
      title: "切换线路",
      child: RadioGroup(
        groupValue: currentLineIndex,
        onChanged: (e) {
          Get.back();
          unawaited(switchPlaybackLine(e ?? 0));
        },
        child: ListView.builder(
          itemCount: playUrls.length,
          itemBuilder: (_, i) {
            return RadioListTile(
              value: i,
              title: Text("线路${i + 1}"),
              secondary: Text(
                playUrls[i].contains(".flv") ? "FLV" : "HLS",
              ),
            );
          },
        ),
      ),
    );
  }

  void showPlayerSettingsSheet() {
    Utils.showBottomSheet(
      title: "画面尺寸",
      child: Obx(
        () => RadioGroup(
          groupValue: AppSettingsController.instance.scaleMode.value,
          onChanged: (e) {
            AppSettingsController.instance.setScaleMode(e ?? 0);
            updateScaleMode();
          },
          child: ListView(
            padding: AppStyle.edgeInsetsV12,
            children: const [
              RadioListTile(
                value: 0,
                title: Text("适应"),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile(
                value: 1,
                title: Text("拉伸"),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile(
                value: 2,
                title: Text("铺满"),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile(
                value: 3,
                title: Text("16:9"),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile(
                value: 4,
                title: Text("4:3"),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isTempMutedUser(String userName) {
    final value = normalizeChatUserName(userName);
    if (value.isEmpty) {
      return false;
    }
    return tempMutedUsers.contains(value);
  }

  void toggleTempMuteUser(String userName) {
    final value = normalizeChatUserName(userName);
    if (value.isEmpty || isChatSystemMessage(value)) {
      SmartDialog.showToast("用户名不能为空");
      return;
    }
    if (tempMutedUsers.contains(value)) {
      tempMutedUsers.remove(value);
      tempMutedUsers.refresh();
      SmartDialog.showToast("已取消临时禁言：$value");
      return;
    }
    tempMutedUsers.add(value);
    tempMutedUsers.refresh();
    SmartDialog.showToast("已加入临时禁言：$value");
  }

  void clearTempMutedUsers() {
    if (tempMutedUsers.isEmpty) {
      SmartDialog.showToast("当前没有临时禁言用户");
      return;
    }
    tempMutedUsers.clear();
    tempMutedUsers.refresh();
    SmartDialog.showToast("已恢复全部临时禁言用户");
  }

  void togglePlatformUserShield(String userName) {
    final value = normalizeChatUserName(userName);
    if (value.isEmpty || isChatSystemMessage(value)) {
      SmartDialog.showToast("用户名不能为空");
      return;
    }
    final shielded = AppSettingsController.instance.toggleUserShield(
      value,
      siteId: site.id,
    );
    SmartDialog.showToast(
      shielded ? "已屏蔽用户：$value（${site.name}）" : "已取消屏蔽用户：$value",
    );
  }

  void copyChatUserName(String userName) {
    final value = normalizeChatUserName(userName);
    if (value.isEmpty || isChatSystemMessage(value)) {
      SmartDialog.showToast("用户名不能为空");
      return;
    }
    Utils.copyToClipboard(value);
  }

  void copyChatMessageContent(String message) {
    final value = normalizeChatMessageText(message);
    if (value.isEmpty) {
      SmartDialog.showToast("弹幕内容为空");
      return;
    }
    Utils.copyToClipboard(value);
  }

  void copyFullChatMessage(LiveMessage message) {
    final text = buildFullChatCopyText(
      userName: message.userName,
      message: message.message,
    );
    if (text.isEmpty) {
      SmartDialog.showToast("内容为空");
      return;
    }
    Utils.copyToClipboard(text);
  }

  void addMessageAsKeywordShield(String message) {
    final value = normalizeChatMessageText(message);
    if (value.isEmpty) {
      SmartDialog.showToast("弹幕内容为空");
      return;
    }
    AppSettingsController.instance.addShieldList(value);
    SmartDialog.showToast("已添加关键词屏蔽");
  }

  Future<void> handleChatMessageMenuAction({
    required ChatMessageMenuAction action,
    required LiveMessage message,
  }) async {
    switch (action) {
      case ChatMessageMenuAction.togglePlatformShield:
        togglePlatformUserShield(message.userName);
        break;
      case ChatMessageMenuAction.toggleTempMute:
        toggleTempMuteUser(message.userName);
        break;
      case ChatMessageMenuAction.copyUserName:
        copyChatUserName(message.userName);
        break;
      case ChatMessageMenuAction.copyMessage:
        copyChatMessageContent(message.message);
        break;
      case ChatMessageMenuAction.copyFull:
        copyFullChatMessage(message);
        break;
      case ChatMessageMenuAction.addKeywordShield:
        addMessageAsKeywordShield(message.message);
        break;
      case ChatMessageMenuAction.clearTempMutes:
        clearTempMutedUsers();
        break;
    }
  }

  /// 平台用户屏蔽 / 临时禁言 / 关键词屏蔽统一过滤。
  bool shouldDropChatMessage({
    required String userName,
    required String message,
    required String siteId,
    required Iterable<String> tempMutedUsers,
  }) {
    final settings = AppSettingsController.instance;
    if (settings.isUserShielded(userName, siteId: siteId)) {
      Log.d("已过滤平台屏蔽用户: $userName");
      return true;
    }
    final muted = tempMutedUsers
        .map(normalizeChatUserName)
        .where((name) => name.isNotEmpty)
        .toSet();
    if (muted.contains(normalizeChatUserName(userName))) {
      Log.d("已过滤临时禁言用户: $userName");
      return true;
    }
    for (final keyword in settings.shieldList) {
      Pattern? pattern;
      if (Utils.isRegexFormat(keyword)) {
        final removedSlash = Utils.removeRegexFormat(keyword);
        try {
          pattern = RegExp(removedSlash);
        } catch (e) {
          Log.d("关键词：$keyword 正则格式错误");
        }
      } else {
        pattern = keyword;
      }
      if (pattern != null && message.contains(pattern)) {
        Log.d("关键词：$keyword\n已屏蔽消息内容：$message");
        return true;
      }
    }
    return false;
  }

  void showDanmuShield() {
    TextEditingController keywordController = TextEditingController();

    void addKeyword() {
      if (keywordController.text.isEmpty) {
        SmartDialog.showToast("请输入关键词");
        return;
      }

      AppSettingsController.instance
          .addShieldList(keywordController.text.trim());
      keywordController.text = "";
    }

    Utils.showBottomSheet(
      title: "关键词屏蔽",
      child: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          TextField(
            controller: keywordController,
            decoration: InputDecoration(
              contentPadding: AppStyle.edgeInsetsH12,
              border: const OutlineInputBorder(),
              hintText: "请输入关键词",
              suffixIcon: TextButton.icon(
                onPressed: addKeyword,
                icon: const Icon(Icons.add),
                label: const Text("添加"),
              ),
            ),
            onSubmitted: (e) {
              addKeyword();
            },
          ),
          AppStyle.vGap12,
          Obx(
            () => Text(
              "已添加${AppSettingsController.instance.shieldList.length}个关键词（点击移除）",
              style: Get.textTheme.titleSmall,
            ),
          ),
          AppStyle.vGap12,
          Obx(
            () => Wrap(
              runSpacing: 12,
              spacing: 12,
              children: AppSettingsController.instance.shieldList
                  .map(
                    (item) => InkWell(
                      borderRadius: AppStyle.radius24,
                      onTap: () {
                        AppSettingsController.instance.removeShieldList(item);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: AppStyle.radius24,
                        ),
                        padding: AppStyle.edgeInsetsH12.copyWith(
                          top: 4,
                          bottom: 4,
                        ),
                        child: Text(
                          item,
                          style: Get.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void showFollowUserSheet() {
    Utils.showBottomSheet(
      title: "关注与历史",
      child: FollowHistoryPanel(
        controller: this,
        onClose: () {
          Get.back();
        },
      ),
    );
  }

  void showAutoExitSheet() {
    if (AppSettingsController.instance.autoExitEnable.value &&
        !delayAutoExit.value) {
      SmartDialog.showToast("已设置了全局定时关闭");
      return;
    }
    Utils.showBottomSheet(
      title: "定时关闭",
      child: ListView(
        children: [
          Obx(
            () => SwitchListTile(
              title: Text(
                "启用定时关闭",
                style: Get.textTheme.titleMedium,
              ),
              value: autoExitEnable.value,
              onChanged: (e) {
                autoExitEnable.value = e;

                setAutoExit();
                //controller.setAutoExitEnable(e);
              },
            ),
          ),
          Obx(
            () => ListTile(
              enabled: autoExitEnable.value,
              title: Text(
                "自动关闭时间：${autoExitMinutes.value ~/ 60}小时${autoExitMinutes.value % 60}分钟",
                style: Get.textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                var value = await showTimePicker(
                  context: Get.context!,
                  initialTime: TimeOfDay(
                    hour: autoExitMinutes.value ~/ 60,
                    minute: autoExitMinutes.value % 60,
                  ),
                  initialEntryMode: TimePickerEntryMode.inputOnly,
                  builder: (_, child) {
                    return MediaQuery(
                      data: Get.mediaQuery.copyWith(
                        alwaysUse24HourFormat: true,
                      ),
                      child: child!,
                    );
                  },
                );
                if (value == null || (value.hour == 0 && value.minute == 0)) {
                  return;
                }
                var duration =
                    Duration(hours: value.hour, minutes: value.minute);
                autoExitMinutes.value = duration.inMinutes;
                AppSettingsController.instance
                    .setRoomAutoExitDuration(autoExitMinutes.value);
                //setAutoExitDuration(duration.inMinutes);
                setAutoExit();
              },
            ),
          ),
        ],
      ),
    );
  }

  void resetRoom(Site site, String roomId) async {
    final switchPlan = resolveLiveRoomSwitchPlan(
      currentSiteId: this.site.id,
      currentRoomId: this.roomId,
      nextSiteId: site.id,
      nextRoomId: roomId,
      currentSidebarTab: sidebarTab.value,
    );
    if (!switchPlan.shouldReset) {
      return;
    }

    _roomLoadToken += 1;
    final loadToken = _roomLoadToken;
    isRoomSwitching.value = true;
    switchingRoomLabel.value = "${site.name} - $roomId";
    switchingSiteLogo.value = site.logo;
    liveDanmaku.stop();

    try {
      final roomDetail = await site.liveSite.getRoomDetail(roomId: roomId);
      if (!_isCurrentRoomLoadToken(loadToken)) {
        return;
      }

      rxSite.value = site;
      rxRoomId.value = roomId;
      sidebarTab.value = switchPlan.nextSidebarTab;
      followed.value = DBService.instance.getFollowExist(
        switchPlan.nextFollowLookupKey,
      );

      beginInitialLoadSession();
      resetTransientRoomState();
      detail.value = roomDetail;
      danmakuController?.clear();
      liveDanmaku = site.liveSite.getDanmaku();
      await player.stop();
      await loadData(
        reuseLoadToken: loadToken,
        prefetchedDetail: roomDetail,
        showGlobalLoading: false,
      );
    } catch (e, s) {
      if (_isCurrentRoomLoadToken(loadToken)) {
        Log.e("切换直播间失败：$e", s);
        SmartDialog.showToast("切换直播间失败");
      }
    } finally {
      if (_isCurrentRoomLoadToken(loadToken)) {
        isRoomSwitching.value = false;
        switchingRoomLabel.value = '';
        switchingSiteLogo.value = '';
      }
    }
  }

  Future<void> _prepareDesktopWindowChrome() async {
    await syncDesktopWindowMaximizedState();
    windowManager.addListener(this);
  }

  Future<void> restoreDesktopWindowChrome() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
  }

  String buildErrorDetailText() {
    final presentation = errorPresentation;
    return buildLiveRoomErrorDetailText(
      appVersion: VersionUtils.buildDetailedVersion(
        Utils.packageInfo.version,
        Utils.packageInfo.buildNumber,
      ),
      generatedAt: DateTime.now(),
      siteName: rxSite.value.name,
      roomId: rxRoomId.value,
      roomTitle: detail.value?.title,
      anchor: detail.value?.userName,
      roomAudienceText: roomAudienceText.value,
      online: online.value,
      errorTitle: presentation.title,
      errorType: presentation.type,
      errorSummary: presentation.summary,
      errorSuggestion: presentation.suggestion,
      rawError: error?.toString(),
      rawStackTrace: errorStackTrace?.toString(),
    );
  }

  void copyErrorDetail() {
    Utils.copyToClipboard(buildErrorDetailText());
  }

  Future<void> openLogDirectory() async {
    await DiagnosticService.openLogDirectory();
  }

  Future<void> exportRoomDiagnosticBundle() async {
    final presentation = errorPresentation;
    final playerSetting = buildLiveRoomPlayerSettingContext(
      customPlayerOutput:
          AppSettingsController.instance.customPlayerOutput.value,
      videoOutputDriver:
          AppSettingsController.instance.videoOutputDriver.value,
      audioOutputDriver:
          AppSettingsController.instance.audioOutputDriver.value,
      videoHardwareDecoder:
          AppSettingsController.instance.videoHardwareDecoder.value,
      logEnabled: AppSettingsController.instance.logEnable.value,
      scaleMode: AppSettingsController.instance.scaleMode.value,
    );

    await DiagnosticService.exportDiagnosticBundle(
      fileNamePrefix: "livehub_room_${site.id}_$roomId",
      contextData: buildLiveRoomDiagnosticContext(
        siteId: site.id,
        siteName: site.name,
        roomId: roomId,
        roomTitle: detail.value?.title,
        anchor: detail.value?.userName,
        url: detail.value?.url,
        liveStatus: liveStatus.value,
        currentQuality: currentQualityInfo.value,
        currentLine: currentLineInfo.value,
        online: online.value,
        roomAudienceText: roomAudienceText.value,
        errorType: presentation.type,
        errorTitle: presentation.title,
        errorSummary: presentation.summary,
        errorSuggestion: presentation.suggestion,
        playerSetting: playerSetting,
        errorDetail: buildErrorDetailText(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      Log.d("进入后台");
      //进入后台，关闭弹幕
      danmakuController?.clear();
      isBackground = true;
    } else
    //返回前台
    if (state == AppLifecycleState.resumed) {
      Log.d("返回前台");
      isBackground = false;
    }
  }

  // 用于启动开播时长计算和更新的函数
  void startLiveDurationTimer() {
    // 如果不是直播状态或者 showTime 为空，则不启动定时器
    final showTime = detail.value?.showTime;
    if (!(detail.value?.status ?? false) ||
        showTime == null ||
        showTime.isEmpty ||
        showTime == "0") {
      liveDuration.value = "00:00:00"; // 未开播时显示 00:00:00
      _liveDurationTimer?.cancel();
      return;
    }

    try {
      int startTimeStamp = int.parse(showTime);
      if (startTimeStamp <= 0) {
        liveDuration.value = "00:00:00";
        _liveDurationTimer?.cancel();
        return;
      }
      // 取消之前的定时器
      _liveDurationTimer?.cancel();
      // 创建新的定时器，每秒更新一次
      _liveDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        int currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int durationInSeconds = currentTimeStamp - startTimeStamp;

        int hours = durationInSeconds ~/ 3600;
        int minutes = (durationInSeconds % 3600) ~/ 60;
        int seconds = durationInSeconds % 60;

        String formattedDuration =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        liveDuration.value = formattedDuration;
      });
    } catch (e) {
      liveDuration.value = "--:--:--"; // 错误时显示 --:--:--
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    unawaited(restoreDesktopWindowChrome());
    _playerPlayingSubscription?.cancel();
    _pendingPlaybackSwitchTimer?.cancel();
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    autoExitTimer?.cancel();

    liveDanmaku.stop();
    danmakuController = null;
    _liveDurationTimer?.cancel(); // 页面关闭时取消定时器
    messages.clear();
    clearSuperChats();
    super.onClose();
  }

  @override
  void onWindowMaximize() {
    desktopWindowMaximized.value = true;
  }

  @override
  void onWindowUnmaximize() {
    desktopWindowMaximized.value = false;
  }

  @override
  void onWindowRestore() {
    desktopWindowMaximized.value = false;
  }

  @override
  void onWindowEnterFullScreen() {
    nativeFullScreenState.value = true;
    fullScreenState.value = true;
  }

  @override
  void onWindowLeaveFullScreen() {
    nativeFullScreenState.value = false;
  }
}

class _VolumeSliderPopover extends StatefulWidget {
  final Player player;

  const _VolumeSliderPopover({required this.player});

  @override
  State<_VolumeSliderPopover> createState() => _VolumeSliderPopoverState();
}

class _VolumeSliderPopoverState extends State<_VolumeSliderPopover> {
  static const double _sliderWidth = 208;
  static const double _sliderHeight = 32;
  static const double _trackHeight = 3;
  static const double _thumbRadius = 5;
  static const double _overlayRadius = 14;

  bool _isHovering = false;

  void _setHovering(bool value) {
    if (_isHovering == value) {
      return;
    }
    setState(() {
      _isHovering = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final borderColor = colorScheme.outline.withAlpha(isDarkMode ? 90 : 36);
    final shadowColor = Colors.black.withAlpha(isDarkMode ? 48 : 18);
    final activeTrackColor = colorScheme.primary.withAlpha(
      _isHovering ? (isDarkMode ? 235 : 216) : (isDarkMode ? 225 : 200),
    );
    final inactiveTrackColor = colorScheme.onSurface.withAlpha(
      _isHovering ? (isDarkMode ? 68 : 52) : (isDarkMode ? 56 : 42),
    );
    final thumbColor = _isHovering
        ? Color.alphaBlend(
            colorScheme.onPrimary.withAlpha(isDarkMode ? 22 : 16),
            colorScheme.primary,
          )
        : colorScheme.primary;
    final overlayColor = colorScheme.primary.withAlpha(
      _isHovering ? (isDarkMode ? 54 : 42) : (isDarkMode ? 30 : 24),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: _sliderWidth + 16,
        padding: AppStyle.edgeInsetsA8.copyWith(top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: AppStyle.radius12,
          border: Border.all(
            color: _isHovering
                ? colorScheme.primary.withAlpha(isDarkMode ? 88 : 64)
                : borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Obx(
          () => SizedBox(
            width: _sliderWidth,
            height: _sliderHeight,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: _trackHeight,
                activeTrackColor: activeTrackColor,
                inactiveTrackColor: inactiveTrackColor,
                thumbColor: thumbColor,
                overlayColor: overlayColor,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: _thumbRadius,
                  pressedElevation: 0,
                  elevation: 0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: _overlayRadius,
                ),
              ),
              child: Slider(
                min: 0,
                max: 100,
                allowedInteraction: SliderInteraction.tapAndSlide,
                value: AppSettingsController.instance.playerVolume.value,
                onChanged: (newValue) {
                  widget.player.setVolume(newValue);
                  AppSettingsController.instance.setPlayerVolume(newValue);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

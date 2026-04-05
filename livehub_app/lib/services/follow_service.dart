import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:get/get.dart';
import 'package:livehub_core/livehub_core.dart';
import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/event_bus.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/services/db_service.dart';

bool syncFollowSnapshotFromDetail(
  FollowUser follow,
  LiveRoomDetail detail,
) {
  var identityChanged = false;
  final nextLiveStartTime = detail.showTime;
  final hasValidLiveStartTime = nextLiveStartTime != null &&
      nextLiveStartTime.isNotEmpty &&
      nextLiveStartTime != "0";

  if (detail.userName.isNotEmpty && follow.userName != detail.userName) {
    follow.userName = detail.userName;
    identityChanged = true;
  }

  if (detail.userAvatar.isNotEmpty && follow.face != detail.userAvatar) {
    follow.face = detail.userAvatar;
    identityChanged = true;
  }

  follow.liveStatus.value = detail.status ? 2 : 1;
  if (detail.status) {
    if (hasValidLiveStartTime) {
      follow.liveStartTime = nextLiveStartTime;
    }
  } else {
    follow.liveStartTime = null;
  }

  return identityChanged;
}

Future<LiveRoomDetail> loadFollowSnapshotForSite({
  required LiveSite liveSite,
  required String roomId,
}) async {
  return liveSite.getFollowRoomSnapshot(roomId: roomId);
}

class FollowService extends GetxService {
  StreamSubscription<dynamic>? subscription;
  static FollowService get instance => Get.find<FollowService>();

  final StreamController _updatedListController = StreamController.broadcast();
  Stream get updatedListStream => _updatedListController.stream;

  /// 关注用户列表
  RxList<FollowUser> followList = RxList<FollowUser>();

  /// 直播中的用户列表
  RxList<FollowUser> liveList = RxList<FollowUser>();

  /// 未直播的用户列表
  RxList<FollowUser> notLiveList = RxList<FollowUser>();

  /// 已经更新状态的数量
  var updatedCount = 0;

  /// 是否正在更新
  var updating = false.obs;

  Timer? updateTimer;

  @override
  void onInit() {
    subscription = EventBus.instance.listen(Constant.kUpdateFollow, (p0) {
      loadData(updateStatus: false);
    });
    initTimer();
    super.onInit();
  }

  // 添加关注
  Future<void> addFollow(FollowUser follow) async {
    await DBService.instance.addFollow(follow);
  }

  void initTimer() {
    if (AppSettingsController.instance.autoUpdateFollowEnable.value) {
      updateTimer?.cancel();
      updateTimer = Timer.periodic(
        Duration(
            minutes:
                AppSettingsController.instance.autoUpdateFollowDuration.value),
        (timer) {
          Log.logPrint("Update Follow Timer");
          loadData();
        },
      );
    } else {
      updateTimer?.cancel();
    }
  }

  Future<void> loadData({bool updateStatus = true}) async {
    var list = DBService.instance.getFollowList();
    if (list.isEmpty) {
      updating.value = false;
      followList.assignAll(list);
      return;
    }
    followList.assignAll(list);
    if (updateStatus) {
      startUpdateStatus();
    }
  }

  /// 获取最优并发数
  /// 根据 CPU 核心数和用户设置自动计算
  int getOptimalConcurrency() {
    var userSetting = AppSettingsController.instance.updateFollowThreadCount.value;

    // 如果用户设置为 0，则自动根据 CPU 核心数计算
    if (userSetting == 0) {
      var cpuCount = Platform.numberOfProcessors;
      // 网络 I/O 密集型任务，并发数可以是 CPU 核心数的 2-3 倍
      var optimal = (cpuCount * 2.5).round();
      // 限制在合理范围内（最少 4，最多 20）
      return optimal.clamp(4, 20);
    }

    return userSetting;
  }

  /// 按平台交错排列，避免单一平台阻塞
  List<FollowUser> interleaveByPlatform(List<FollowUser> list) {
    // 按平台分组
    var grouped = <String, Queue<FollowUser>>{};
    for (var item in list) {
      grouped.putIfAbsent(item.siteId, () => Queue<FollowUser>()).add(item);
    }

    // 交错处理
    var result = <FollowUser>[];
    while (grouped.values.any((queue) => queue.isNotEmpty)) {
      for (var queue in grouped.values) {
        if (queue.isNotEmpty) {
          result.add(queue.removeFirst());
        }
      }
    }

    return result;
  }

  void startUpdateStatus() async {
    updatedCount = 0;
    updating.value = true;

    var concurrency = getOptimalConcurrency();

    Log.logPrint("开始更新关注状态，并发数: $concurrency，总数: ${followList.length}");

    // 按平台交错排列，避免单一平台阻塞
    var interleavedList = interleaveByPlatform(followList);

    // 创建任务队列
    var taskQueue = Queue<FollowUser>.from(interleavedList);

    // 工作函数 - 持续从队列中取任务执行
    Future<void> worker(int workerId) async {
      while (taskQueue.isNotEmpty) {
        var item = taskQueue.removeFirst();
        await updateLiveStatus(item);
      }
    }

    // 启动固定数量的并发 worker
    var workers = <Future>[];
    for (var i = 0; i < concurrency; i++) {
      workers.add(worker(i));
    }

    await Future.wait(workers);

    Log.logPrint("关注状态更新完成");
  }

  Future updateLiveStatus(FollowUser item) async {
    try {
      var site = Sites.allSites[item.siteId]!;
      var detail = await loadFollowSnapshotForSite(
        liveSite: site.liveSite,
        roomId: item.roomId,
      );
      var identityChanged = syncFollowSnapshotFromDetail(item, detail);
      if (identityChanged) {
        await DBService.instance.addFollow(item);
      }
    } catch (e) {
      Log.logPrint(e);
      item.liveStatus.value = 0;
      item.liveStartTime = null;
    } finally {
      updatedCount++;
      if (updatedCount >= followList.length) {
        filterData();
        updating.value = false;
      }
    }
  }

  void filterData() {
    followList.sort((a, b) => b.liveStatus.value.compareTo(a.liveStatus.value));
    liveList.assignAll(followList.where((x) => x.liveStatus.value == 2));
    notLiveList.assignAll(followList.where((x) => x.liveStatus.value == 1));
    _updatedListController.add(0);
  }

  Future<void> importUsers(List<FollowUser> follows) async {
    for (final follow in follows) {
      await DBService.instance.addFollow(follow);
    }
  }

  @override
  void onClose() {
    updateTimer?.cancel();
    subscription?.cancel();
    super.onClose();
  }
}

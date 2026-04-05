import 'dart:async';

import 'package:get/get.dart';
import 'package:livehub_app/app/controller/base_controller.dart';
import 'package:livehub_app/app/event_bus.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/modules/follow_user/follow_user_filter_utils.dart';
import 'package:livehub_app/services/db_service.dart';
import 'package:livehub_app/services/follow_service.dart';

class FollowUserController extends BasePageController<FollowUser> {
  StreamSubscription<dynamic>? onUpdatedIndexedStream;
  StreamSubscription<dynamic>? onUpdatedListStream;

  final filterMode = kDefaultFollowFilters.first.obs;
  final followService = FollowService.instance;

  @override
  void onInit() {
    onUpdatedIndexedStream = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 1) {
          scrollToTopOrRefresh();
        }
      },
    );
    onUpdatedListStream =
        followService.updatedListStream.listen((event) {
      filterData();
    });
    super.onInit();
  }

  @override
  Future refreshData() async {
    await followService.loadData();
    await super.refreshData();
  }

  @override
  Future<List<FollowUser>> getData(int page, int pageSize) async {
    if (page > 1) {
        return Future.value([]);
    }
    return _resolveFilterList(filterMode.value.type);
  }

  void filterData() {
    list.assignAll(_resolveFilterList(filterMode.value.type));
  }

  List<FollowUser> _resolveFilterList(FollowUserFilter type) {
    switch (type) {
      case FollowUserFilter.live:
        return followService.liveList.value;
      case FollowUserFilter.notLive:
        return followService.notLiveList.value;
      case FollowUserFilter.all:
        return followService.followList.value;
    }
  }

  void setFilterMode(FollowUserFilterOption option) {
    filterMode.value = option;
    filterData();
  }

  void removeItem(FollowUser item) async {
    var result =
        await Utils.showAlertDialog("确定要取消关注${item.userName}吗?", title: "取消关注");
    if (!result) {
      return;
    }
    await DBService.instance.followBox.delete(item.id);
    await refreshData();
  }

  @override
  void onClose() {
    onUpdatedIndexedStream?.cancel();
    onUpdatedListStream?.cancel();
    super.onClose();
  }
}

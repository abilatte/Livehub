import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/models/db/history.dart';

class DBService extends GetxService {
  static DBService get instance => Get.find<DBService>();
  late Box<History> historyBox;
  late Box<FollowUser> followBox;
  StreamSubscription<BoxEvent>? _historyBoxSubscription;
  List<History>? _historyCache;

  Future init() async {
    historyBox = await Hive.openBox("History");
    followBox = await Hive.openBox("FollowUser");
    _historyBoxSubscription = historyBox.watch().listen((_) {
      _historyCache = null;
    });
  }

  bool getFollowExist(String id) {
    return followBox.containsKey(id);
  }

  List<FollowUser> getFollowList() {
    return followBox.values.toList();
  }

  Future addFollow(FollowUser follow) async {
    await followBox.put(follow.id, follow);
  }

  Future deleteFollow(String id) async {
    await followBox.delete(id);
  }

  History? getHistory(String id) {
    if (historyBox.containsKey(id)) {
      return historyBox.get(id);
    }
    return null;
  }

  Future addOrUpdateHistory(History history) async {
    await historyBox.put(history.id, history);
    _historyCache = null;
  }

  List<History> getHistores() {
    final cache = _historyCache;
    if (cache != null) {
      return cache;
    }
    final his = historyBox.values.toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
    final nextCache = UnmodifiableListView<History>(his);
    _historyCache = nextCache;
    return nextCache;
  }

  @override
  void onClose() {
    _historyBoxSubscription?.cancel();
    super.onClose();
  }
}

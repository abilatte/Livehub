import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:livehub_app/modules/indexed/indexed_controller.dart';
import 'package:livehub_app/routes/route_path.dart';
import 'package:window_manager/window_manager.dart';

class DesktopWindowController extends GetxController with WindowListener {
  static const double kDesktopTitleBarHeight = 44;
  final RxString currentRoute = RoutePath.kIndex.obs;
  final RxBool maximized = false.obs;
  Color? _lastWindowBackgroundColor;

  bool get isWindowsDesktop => Platform.isWindows;

  bool get showGlobalTitleBar =>
      isWindowsDesktop && !_isLiveRoomRoute(currentRoute.value);

  String get currentTitle {
    if (currentRoute.value == RoutePath.kIndex &&
        Get.isRegistered<IndexedController>()) {
      final indexedController = Get.find<IndexedController>();
      final index = indexedController.index.value;
      if (index >= 0 && index < indexedController.items.length) {
        return indexedController.items[index].title;
      }
    }
    return _routeTitles[currentRoute.value] ?? "LiveHub";
  }

  static const Map<String, String> _routeTitles = {
    RoutePath.kIndex: "LiveHub",
    RoutePath.kHistory: "观看历史",
    RoutePath.kFollowUser: "我的关注",
    RoutePath.kSearch: "搜索",
    RoutePath.kCategoryDetail: "分类详情",
    RoutePath.kSettingsCenter: "设置中心",
    RoutePath.kSettingsPlay: "播放与直播",
    RoutePath.kSettingsDanmu: "弹幕与聊天",
    RoutePath.kSettingsDanmuShield: "关键词屏蔽",
    RoutePath.kSettingsAutoExit: "定时关闭",
    RoutePath.kSettingsIndexed: "主页设置",
    RoutePath.kSettingsFollow: "关注设置",
    RoutePath.kSettingsOther: "日志与高级",
    RoutePath.kSettingsAccount: "账号管理",
    RoutePath.kAppstyleSetting: "外观设置",
    RoutePath.kTools: "工具箱",
  };

  @override
  void onInit() {
    super.onInit();
    if (isWindowsDesktop) {
      windowManager.addListener(this);
      syncWindowState();
      unawaited(ensureCustomWindowChrome());
    }
  }

  @override
  void onClose() {
    if (isWindowsDesktop) {
      windowManager.removeListener(this);
    }
    super.onClose();
  }

  void setCurrentRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) {
      return;
    }
    currentRoute.value = routeName;
  }

  bool _isLiveRoomRoute(String routeName) {
    return routeName == RoutePath.kLiveRoomDetail ||
        routeName.contains(RoutePath.kLiveRoomDetail);
  }

  Future<void> syncWindowState() async {
    if (!isWindowsDesktop) {
      return;
    }
    maximized.value = await windowManager.isMaximized();
  }

  Future<void> minimizeWindow() async {
    await windowManager.minimize();
  }

  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
      maximized.value = false;
      return;
    }
    await windowManager.maximize();
    maximized.value = true;
  }

  Future<void> closeWindow() async {
    await windowManager.close();
  }

  Future<void> syncWindowBackgroundColor(Color color) async {
    if (!isWindowsDesktop) {
      return;
    }
    if (_lastWindowBackgroundColor?.value == color.value) {
      return;
    }
    _lastWindowBackgroundColor = color;
    await windowManager.setBackgroundColor(color);
  }

  Future<void> ensureCustomWindowChrome() async {
    if (!isWindowsDesktop) {
      return;
    }
    await windowManager.setAsFrameless();
    if (_lastWindowBackgroundColor != null) {
      await windowManager.setBackgroundColor(_lastWindowBackgroundColor!);
    }
  }

  @override
  void onWindowMaximize() {
    maximized.value = true;
  }

  @override
  void onWindowUnmaximize() {
    maximized.value = false;
  }

  @override
  void onWindowRestore() {
    maximized.value = false;
  }
}

class DesktopWindowRouteObserver extends NavigatorObserver {
  void _updateCurrentRoute(Route<dynamic>? route) {
    if (!Get.isRegistered<DesktopWindowController>()) {
      return;
    }
    final routeName = route?.settings.name;
    if (routeName == null || routeName.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<DesktopWindowController>()) {
        return;
      }
      Get.find<DesktopWindowController>().setCurrentRoute(routeName);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateCurrentRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateCurrentRoute(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateCurrentRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

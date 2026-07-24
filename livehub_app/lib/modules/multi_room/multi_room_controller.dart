import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:livehub_app/modules/multi_room/multi_room_models.dart';
import 'package:livehub_app/modules/multi_room/multi_room_player_controller.dart';
import 'package:livehub_app/modules/multi_room/multi_room_utils.dart';

class MultiRoomController extends GetxController {
  final List<MultiRoomItem> initialRooms;

  MultiRoomController(this.initialRooms);

  final rooms = <MultiRoomItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    rooms.assignAll(_distinct(initialRooms));
  }

  List<MultiRoomItem> _distinct(Iterable<MultiRoomItem> items) {
    final result = <MultiRoomItem>[];
    final keys = <String>{};
    for (final item in items) {
      if (keys.add(item.key)) {
        result.add(item);
      }
    }
    return MultiRoomUtils.capRooms(result);
  }

  String playerTag(MultiRoomItem item) => item.key;

  MultiRoomPlayerController playerFor(MultiRoomItem item) {
    final tag = playerTag(item);
    if (Get.isRegistered<MultiRoomPlayerController>(tag: tag)) {
      return Get.find<MultiRoomPlayerController>(tag: tag);
    }
    return Get.put(MultiRoomPlayerController(item), tag: tag);
  }

  void addRoom(MultiRoomItem item) {
    if (rooms.any((room) => room.key == item.key)) {
      SmartDialog.showToast("该直播间已在多开列表中");
      return;
    }
    if (rooms.length >= MultiRoomUtils.maxRooms) {
      SmartDialog.showToast("最多同时打开 ${MultiRoomUtils.maxRooms} 路");
      return;
    }
    rooms.add(item);
  }

  void removeRoom(MultiRoomItem item) {
    rooms.removeWhere((room) => room.key == item.key);
    final tag = playerTag(item);
    if (Get.isRegistered<MultiRoomPlayerController>(tag: tag)) {
      Get.delete<MultiRoomPlayerController>(tag: tag);
    }
    if (rooms.isEmpty) {
      SmartDialog.showToast("已关闭全部多开直播间");
      Get.back();
    }
  }

  void stopAll() {
    final snapshot = List<MultiRoomItem>.from(rooms);
    for (final item in snapshot) {
      final tag = playerTag(item);
      if (Get.isRegistered<MultiRoomPlayerController>(tag: tag)) {
        Get.delete<MultiRoomPlayerController>(tag: tag);
      }
    }
    rooms.clear();
  }

  @override
  void onClose() {
    stopAll();
    super.onClose();
  }
}

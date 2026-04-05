import 'package:get/get.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsFollowMixin on GetxController {
  final autoExitEnable = false.obs;
  final autoExitDuration = 60.obs;
  final roomAutoExitDuration = 60.obs;
  final liveRoomPopupShowFollowList = true.obs;
  final autoUpdateFollowEnable = false.obs;
  final autoUpdateFollowDuration = 10.obs;
  final updateFollowThreadCount = 4.obs;

  void initFollowSettings() {
    autoExitEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoExitEnable, false);
    autoExitDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoExitDuration, 60);
    roomAutoExitDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kRoomAutoExitDuration, 60);
    liveRoomPopupShowFollowList.value = LocalStorageService.instance.getValue(
      LocalStorageService.kLiveRoomPopupShowFollowList,
      true,
    );
    autoUpdateFollowEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoUpdateFollowEnable, true);
    autoUpdateFollowDuration.value = LocalStorageService.instance
        .getValue(LocalStorageService.kUpdateFollowDuration, 10);
    updateFollowThreadCount.value = LocalStorageService.instance
        .getValue(LocalStorageService.kUpdateFollowThreadCount, 0);
  }

  void setAutoExitEnable(bool value) {
    autoExitEnable.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kAutoExitEnable,
      value,
    );
  }

  void setAutoExitDuration(int value) {
    autoExitDuration.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kAutoExitDuration,
      value,
    );
  }

  void setRoomAutoExitDuration(int value) {
    roomAutoExitDuration.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kRoomAutoExitDuration,
      value,
    );
  }

  void setLiveRoomPopupShowFollowList(bool value) {
    liveRoomPopupShowFollowList.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kLiveRoomPopupShowFollowList,
      value,
    );
  }

  void setAutoUpdateFollowEnable(bool value) {
    autoUpdateFollowEnable.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kAutoUpdateFollowEnable,
      value,
    );
  }

  void setAutoUpdateFollowDuration(int value) {
    autoUpdateFollowDuration.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kUpdateFollowDuration,
      value,
    );
  }

  void setUpdateFollowThreadCount(int value) {
    updateFollowThreadCount.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kUpdateFollowThreadCount,
      value,
    );
  }
}

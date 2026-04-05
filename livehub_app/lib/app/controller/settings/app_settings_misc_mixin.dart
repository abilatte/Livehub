import 'package:get/get.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsMiscMixin on GetxController {
  final bilibiliLoginTip = true.obs;
  final logEnable = false.obs;

  void initMiscSettings() {
    bilibiliLoginTip.value = LocalStorageService.instance
        .getValue(LocalStorageService.kBilibiliLoginTip, true);
    logEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kLogEnable, false);
    if (logEnable.value) {
      Log.initWriter();
    }
  }

  void setBiliBiliLoginTip(bool value) {
    bilibiliLoginTip.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kBilibiliLoginTip,
      value,
    );
  }

  void setLogEnable(bool value) {
    logEnable.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kLogEnable,
      value,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsAppearanceMixin on GetxController {
  final themeMode = 0.obs;
  var firstRun = false;
  final styleColor = 0xff3498db.obs;
  final isDynamic = false.obs;

  void initAppearanceSettings() {
    themeMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kThemeMode, 0);
    firstRun = LocalStorageService.instance
        .getValue(LocalStorageService.kFirstRun, true);
    styleColor.value = LocalStorageService.instance
        .getValue(LocalStorageService.kStyleColor, 0xff3498db);
    isDynamic.value = LocalStorageService.instance
        .getValue(LocalStorageService.kIsDynamic, false);
  }

  void setNoFirstRun() {
    LocalStorageService.instance.setValue(LocalStorageService.kFirstRun, false);
  }

  void changeTheme() {
    Get.dialog(
      RadioGroup(
        groupValue: themeMode.value,
        onChanged: (e) {
          Get.back();
          setTheme(e ?? 0);
        },
        child: const SimpleDialog(
          title: Text("设置主题"),
          children: [
            RadioListTile<int>(
              title: Text("跟随系统"),
              value: 0,
            ),
            RadioListTile<int>(
              title: Text("浅色模式"),
              value: 1,
            ),
            RadioListTile<int>(
              title: Text("深色模式"),
              value: 2,
            ),
          ],
        ),
      ),
    );
  }

  void setTheme(int i) {
    themeMode.value = i;
    final mode = ThemeMode.values[i];

    LocalStorageService.instance.setValue(LocalStorageService.kThemeMode, i);
    Get.changeThemeMode(mode);
  }

  void setStyleColor(int value) {
    styleColor.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kStyleColor,
      value,
    );
  }

  void setIsDynamic(bool value) {
    isDynamic.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kIsDynamic,
      value,
    );
  }
}

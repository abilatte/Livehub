import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/controller/base_controller.dart';

class DanmuShieldController extends BaseController {
  final TextEditingController textEditingController = TextEditingController();
  final AppSettingsController settingsController =
      Get.find<AppSettingsController>();
  void add() {
    if (textEditingController.text.isEmpty) {
      SmartDialog.showToast("请输入关键词");
      return;
    }

    settingsController.addShieldList(textEditingController.text.trim());
    textEditingController.text = "";
  }

  void remove(String item) {
    settingsController.removeShieldList(item);
  }

  void removeUserShield({
    required String userName,
    required String siteId,
  }) {
    settingsController.removeUserShield(
      userName,
      siteId: siteId,
    );
  }

  Future<void> saveCurrentAsPreset(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      SmartDialog.showToast("请输入预设名称");
      return;
    }
    await settingsController.saveCurrentKeywordsAsPreset(trimmed);
    SmartDialog.showToast("已保存预设：$trimmed");
  }

  Future<void> applyPreset(String name) async {
    await settingsController.applyShieldPreset(name);
    SmartDialog.showToast("已应用预设：$name");
  }

  Future<void> removePreset(String name) async {
    await settingsController.removeShieldPreset(name);
    SmartDialog.showToast("已删除预设：$name");
  }
}

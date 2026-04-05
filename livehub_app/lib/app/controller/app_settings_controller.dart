import 'package:get/get.dart';
import 'package:livehub_app/app/controller/settings/app_settings_appearance_mixin.dart';
import 'package:livehub_app/app/controller/settings/app_settings_collection_mixin.dart';
import 'package:livehub_app/app/controller/settings/app_settings_danmaku_chat_mixin.dart';
import 'package:livehub_app/app/controller/settings/app_settings_follow_mixin.dart';
import 'package:livehub_app/app/controller/settings/app_settings_misc_mixin.dart';
import 'package:livehub_app/app/controller/settings/app_settings_player_mixin.dart';

class AppSettingsController extends GetxController
    with
        AppSettingsAppearanceMixin,
        AppSettingsDanmakuChatMixin,
        AppSettingsPlayerMixin,
        AppSettingsFollowMixin,
        AppSettingsMiscMixin,
        AppSettingsCollectionMixin {
  static AppSettingsController get instance =>
      Get.find<AppSettingsController>();

  @override
  void onInit() {
    initAppearanceSettings();
    initDanmakuAndChatSettings();
    initPlayerSettings();
    initFollowSettings();
    initMiscSettings();
    initCollectionSettings();
    super.onInit();
  }
}

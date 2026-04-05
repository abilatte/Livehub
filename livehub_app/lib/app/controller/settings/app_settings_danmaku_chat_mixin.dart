import 'package:get/get.dart';
import 'package:livehub_app/app/controller/settings/app_settings_utils.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsDanmakuChatMixin on GetxController {
  final chatTextSize = 14.0.obs;
  final chatTextGap = 4.0.obs;
  final chatBubbleStyle = false.obs;
  final chatMessageRetentionLimit = 0.obs;
  final superChatRetentionLimit = 0.obs;
  final liveRoomSidebarWidth = 0.obs;

  final danmuSize = 16.0.obs;
  final danmuSpeed = 10.0.obs;
  final danmuArea = 0.8.obs;
  final danmuOpacity = 1.0.obs;
  final danmuEnable = true.obs;
  final danmuStrokeWidth = 2.0.obs;
  final danmuFontWeight = 4.obs;
  final danmuTopMargin = 0.0.obs;
  final danmuBottomMargin = 0.0.obs;

  void initDanmakuAndChatSettings() {
    danmuSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuSize, 16.0);
    danmuOpacity.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuOpacity, 1.0);
    danmuArea.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuArea, 0.8);
    danmuSpeed.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuSpeed, 10.0);
    danmuEnable.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuEnable, true);
    danmuStrokeWidth.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuStrokeWidth, 2.0);
    danmuTopMargin.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuTopMargin, 0.0);
    danmuBottomMargin.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuBottomMargin, 0.0);
    danmuFontWeight.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDanmuFontWeight, 4);

    chatTextSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kChatTextSize, 14.0);
    chatTextGap.value = LocalStorageService.instance
        .getValue(LocalStorageService.kChatTextGap, 4.0);
    chatBubbleStyle.value = LocalStorageService.instance.getValue(
      LocalStorageService.kChatBubbleStyle,
      false,
    );
    chatMessageRetentionLimit.value = LocalStorageService.instance.getValue(
      LocalStorageService.kChatMessageRetentionLimit,
      0,
    );
    superChatRetentionLimit.value = LocalStorageService.instance.getValue(
      LocalStorageService.kSuperChatRetentionLimit,
      0,
    );
    liveRoomSidebarWidth.value = LocalStorageService.instance.getValue(
      LocalStorageService.kLiveRoomSidebarWidth,
      0,
    );
  }

  void setChatTextSize(double value) {
    chatTextSize.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kChatTextSize,
      value,
    );
  }

  void setChatTextGap(double value) {
    chatTextGap.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kChatTextGap,
      value,
    );
  }

  void setChatBubbleStyle(bool value) {
    chatBubbleStyle.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kChatBubbleStyle,
      value,
    );
  }

  void setChatMessageRetentionLimit(int value) {
    final safeValue = clampNonNegativeInt(value);
    chatMessageRetentionLimit.value = safeValue;
    LocalStorageService.instance.setValue(
      LocalStorageService.kChatMessageRetentionLimit,
      safeValue,
    );
  }

  void setSuperChatRetentionLimit(int value) {
    final safeValue = clampNonNegativeInt(value);
    superChatRetentionLimit.value = safeValue;
    LocalStorageService.instance.setValue(
      LocalStorageService.kSuperChatRetentionLimit,
      safeValue,
    );
  }

  void setLiveRoomSidebarWidth(int value) {
    final safeValue = clampNonNegativeInt(value);
    liveRoomSidebarWidth.value = safeValue;
    LocalStorageService.instance.setValue(
      LocalStorageService.kLiveRoomSidebarWidth,
      safeValue,
    );
  }

  void setDanmuSize(double value) {
    danmuSize.value = value;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuSize, value);
  }

  void setDanmuSpeed(double value) {
    danmuSpeed.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuSpeed,
      value,
    );
  }

  void setDanmuArea(double value) {
    danmuArea.value = value;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuArea, value);
  }

  void setDanmuOpacity(double value) {
    danmuOpacity.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuOpacity,
      value,
    );
  }

  void setDanmuEnable(bool value) {
    danmuEnable.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuEnable,
      value,
    );
  }

  void setDanmuStrokeWidth(double value) {
    danmuStrokeWidth.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuStrokeWidth,
      value,
    );
  }

  void setDanmuFontWeight(int value) {
    danmuFontWeight.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuFontWeight,
      value,
    );
  }

  void setDanmuTopMargin(double value) {
    danmuTopMargin.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuTopMargin,
      value,
    );
  }

  void setDanmuBottomMargin(double value) {
    danmuBottomMargin.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuBottomMargin,
      value,
    );
  }
}

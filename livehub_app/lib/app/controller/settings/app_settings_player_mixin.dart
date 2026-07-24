import 'package:get/get.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsPlayerMixin on GetxController {
  final scaleMode = 0.obs;
  final qualityLevel = 1.obs;
  final hardwareDecode = true.obs;
  final playerCompatMode = false.obs;
  final playerAutoPause = false.obs;
  final playerBufferSize = 32.obs;
  final playerForceHttps = false.obs;
  final autoFullScreen = false.obs;
  final playershowSuperChat = true.obs;
  final keepSuperChatInPage = true.obs;
  final keepSuperChatInOverlay = false.obs;
  final playerVolume = 100.0.obs;
  final customPlayerOutput = false.obs;
  final videoOutputDriver = "".obs;
  final audioOutputDriver = "".obs;
  final videoHardwareDecoder = "".obs;
  final mpvProfile = "balanced".obs;
  final mpvAdvancedOptions = "".obs;

  void initPlayerSettings() {
    qualityLevel.value = LocalStorageService.instance
        .getValue(LocalStorageService.kQualityLevel, 1);
    hardwareDecode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kHardwareDecode, true);
    playerCompatMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerCompatMode, false);
    playerAutoPause.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerAutoPause, false);
    playerForceHttps.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerForceHttps, false);
    autoFullScreen.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAutoFullScreen, false);
    playershowSuperChat.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerShowSuperChat, true);
    keepSuperChatInPage.value = LocalStorageService.instance
        .getValue(LocalStorageService.kKeepSuperChatInPage, true);
    keepSuperChatInOverlay.value = LocalStorageService.instance
        .getValue(LocalStorageService.kKeepSuperChatInOverlay, false);
    scaleMode.value = LocalStorageService.instance.getValue(
      LocalStorageService.kPlayerScaleMode,
      0,
    );
    playerVolume.value = LocalStorageService.instance.getValue(
      LocalStorageService.kPlayerVolume,
      100.0,
    );
    playerBufferSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kPlayerBufferSize, 32);
    customPlayerOutput.value = LocalStorageService.instance
        .getValue(LocalStorageService.kCustomPlayerOutput, false);
    videoOutputDriver.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVideoOutputDriver,
      "libmpv",
    );
    audioOutputDriver.value = LocalStorageService.instance.getValue(
      LocalStorageService.kAudioOutputDriver,
      "wasapi",
    );
    videoHardwareDecoder.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVideoHardwareDecoder,
      "auto",
    );
    // Default to performance on desktop for smoother high-bitrate live streams.
    mpvProfile.value = LocalStorageService.instance.getValue(
      LocalStorageService.kMpvProfile,
      "performance",
    );
    mpvAdvancedOptions.value = LocalStorageService.instance.getValue(
      LocalStorageService.kMpvAdvancedOptions,
      "",
    );
  }

  void setScaleMode(int value) {
    scaleMode.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerScaleMode,
      value,
    );
  }

  void setQualityLevel(int value) {
    qualityLevel.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kQualityLevel,
      value,
    );
  }

  void setHardwareDecode(bool value) {
    hardwareDecode.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kHardwareDecode,
      value,
    );
  }

  void setPlayerCompatMode(bool value) {
    playerCompatMode.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerCompatMode,
      value,
    );
  }

  void setPlayerAutoPause(bool value) {
    playerAutoPause.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerAutoPause,
      value,
    );
  }

  void setPlayerBufferSize(int value) {
    playerBufferSize.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerBufferSize,
      value,
    );
  }

  void setPlayerForceHttps(bool value) {
    playerForceHttps.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerForceHttps,
      value,
    );
  }

  void setAutoFullScreen(bool value) {
    autoFullScreen.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kAutoFullScreen,
      value,
    );
  }

  void setPlayerShowSuperChat(bool value) {
    playershowSuperChat.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerShowSuperChat,
      value,
    );
  }

  void setKeepSuperChatInPage(bool value) {
    keepSuperChatInPage.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kKeepSuperChatInPage,
      value,
    );
  }

  void setKeepSuperChatInOverlay(bool value) {
    keepSuperChatInOverlay.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kKeepSuperChatInOverlay,
      value,
    );
  }

  void setPlayerVolume(double value) {
    playerVolume.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kPlayerVolume,
      value,
    );
  }

  void setCustomPlayerOutput(bool value) {
    customPlayerOutput.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kCustomPlayerOutput,
      value,
    );
  }

  void setVideoOutputDriver(String value) {
    videoOutputDriver.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kVideoOutputDriver,
      value,
    );
  }

  void setAudioOutputDriver(String value) {
    audioOutputDriver.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kAudioOutputDriver,
      value,
    );
  }

  void setVideoHardwareDecoder(String value) {
    videoHardwareDecoder.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kVideoHardwareDecoder,
      value,
    );
  }

  void setMpvProfile(String value) {
    mpvProfile.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kMpvProfile,
      value,
    );
  }

  void setMpvAdvancedOptions(String value) {
    mpvAdvancedOptions.value = value;
    LocalStorageService.instance.setValue(
      LocalStorageService.kMpvAdvancedOptions,
      value,
    );
  }
}

import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/services/mpv_options_utils.dart';

/// Applies merged MPV options to media_kit players.
class MpvOptionsService {
  static Map<String, String> get profileLabels => MpvOptionsUtils.profileLabels;

  static MpvEffectiveOptions effectiveOptionsWithSource() {
    final settings = AppSettingsController.instance;
    return MpvOptionsUtils.mergeOptions(
      profile: settings.mpvProfile.value,
      customPlayerOutput: settings.customPlayerOutput.value,
      videoOutputDriver: settings.videoOutputDriver.value,
      videoHardwareDecoder: settings.videoHardwareDecoder.value,
      audioOutputDriver: settings.audioOutputDriver.value,
      advancedOptionsRaw: settings.mpvAdvancedOptions.value,
      hardwareDecode: settings.hardwareDecode.value,
    );
  }

  static Map<String, String> effectiveOptions() {
    return effectiveOptionsWithSource().options;
  }

  static VideoControllerConfiguration videoControllerConfiguration() {
    final settings = AppSettingsController.instance;
    if (settings.playerCompatMode.value && Platform.isAndroid) {
      return const VideoControllerConfiguration(
        vo: 'mediacodec_embed',
        hwdec: 'mediacodec',
      );
    }
    final effective = effectiveOptionsWithSource();
    if (!Platform.isAndroid) {
      // Desktop: only pass hwdec. Never pass vo=gpu here — that can open a
      // standalone mpv window titled "LiveHub Player" instead of embedding
      // into the Flutter Video widget (same as Simple Live fork behavior).
      final hwdec = effective.options["hwdec"];
      return VideoControllerConfiguration(
        hwdec: (hwdec == null || hwdec.isEmpty) ? null : hwdec,
        enableHardwareAcceleration: settings.hardwareDecode.value,
      );
    }
    return VideoControllerConfiguration(
      vo: effective.options["vo"],
      hwdec: effective.options["hwdec"],
      enableHardwareAcceleration: settings.hardwareDecode.value,
      androidAttachSurfaceAfterVideoParameters: true,
    );
  }

  static Future<void> applyToPlayer(Player player) async {
    if (player.platform is! NativePlayer) {
      return;
    }
    // Match fork: do not set vo/hwdec on the native player.
    // Setting vo=gpu forces an external mpv window ("LiveHub Player").
    final options = Map<String, String>.from(effectiveOptions())
      ..remove("vo")
      ..remove("hwdec");
    for (final entry in options.entries) {
      try {
        await (player.platform as dynamic).setProperty(entry.key, entry.value);
      } catch (e) {
        Log.d("mpv option skipped: ${entry.key}=${entry.value} $e");
      }
    }
  }
}

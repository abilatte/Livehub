import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/controller/base_controller.dart';
import 'package:livehub_app/app/log.dart';
import 'package:path/path.dart' as p;
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/services/diagnostic_service.dart';
import 'package:livehub_app/services/local_storage_service.dart';

class OtherSettingsController extends BaseController {
  RxList<LogFileModel> logFiles = <LogFileModel>[].obs;

  static const Map<String, String> _videoOutputDrivers = {
    "gpu": "gpu",
    "gpu-next": "gpu-next",
    "direct3d": "direct3d",
    "sdl": "sdl",
    "null": "null",
    "libmpv": "libmpv",
  };

  static const Map<String, String> _audioOutputDrivers = {
    "null": "null（静音输出）",
    "directsound": "directsound",
    "wasapi": "wasapi",
    "winmm": "winmm（旧版 Windows 音频接口）",
    "pcm": "pcm",
    "sdl": "sdl",
    "openal": "openal",
    "libao": "libao",
  };

  static const Map<String, String> _hardwareDecoder = {
    "no": "no",
    "auto": "auto",
    "auto-safe": "auto-safe",
    "yes": "yes",
    "auto-copy": "auto-copy",
    "d3d11va": "d3d11va",
    "d3d11va-copy": "d3d11va-copy",
    "dxva2": "dxva2",
    "dxva2-copy": "dxva2-copy",
    "cuda": "cuda",
    "cuda-copy": "cuda-copy",
  };

  late final Map<String, String> videoOutputDrivers =
      _buildVideoOutputDrivers();
  late final Map<String, String> audioOutputDrivers =
      _buildAudioOutputDrivers();
  late final Map<String, String> hardwareDecoder = _buildHardwareDecoder();

  @override
  void onInit() {
    loadLogFiles();
    super.onInit();
  }

  void setLogEnable(e) {
    AppSettingsController.instance.setLogEnable(e);
    if (e) {
      Log.initWriter();
      Future.delayed(const Duration(milliseconds: 100), () {
        loadLogFiles();
      });
    } else {
      Log.disposeWriter();
    }
  }

  void loadLogFiles() async {
    var supportDir = await getApplicationSupportDirectory();
    var logDir = Directory("${supportDir.path}/log");
    if (!await logDir.exists()) {
      await logDir.create();
    }
    logFiles.clear();
    await logDir.list().forEach((element) {
      if (element is! File) {
        return;
      }
      var file = element;
      var name = p.basename(file.path);
      var time = file.lastModifiedSync();
      var size = file.lengthSync();
      logFiles.add(LogFileModel(name, file.path, time, size));
    });
    //logFiles 名称倒序
    logFiles.sort((a, b) => b.time.compareTo(a.time));
  }

  Map<String, String> _pickEntries(
    Map<String, String> source,
    List<String> keys,
  ) {
    return {
      for (final key in keys)
        if (source.containsKey(key)) key: source[key]!,
    };
  }

  Map<String, String> _withCurrentValue(
    Map<String, String> source,
    String currentValue,
  ) {
    if (currentValue.isEmpty || source.containsKey(currentValue)) {
      return source;
    }
    return {
      ...source,
      currentValue: "$currentValue（当前配置）",
    };
  }

  Map<String, String> _buildVideoOutputDrivers() {
    return _withCurrentValue(
      _pickEntries(_videoOutputDrivers, [
        "gpu",
        "gpu-next",
        "direct3d",
        "libmpv",
        "null",
      ]),
      AppSettingsController.instance.videoOutputDriver.value,
    );
  }

  Map<String, String> _buildAudioOutputDrivers() {
    return _withCurrentValue(
      _pickEntries(_audioOutputDrivers, [
        "wasapi",
        "directsound",
        "winmm",
        "null",
        "pcm",
        "sdl",
        "openal",
        "libao",
      ]),
      AppSettingsController.instance.audioOutputDriver.value,
    );
  }

  Map<String, String> _buildHardwareDecoder() {
    return _withCurrentValue(
      _pickEntries(_hardwareDecoder, [
        "no",
        "auto",
        "auto-safe",
        "yes",
        "auto-copy",
        "d3d11va",
        "d3d11va-copy",
        "dxva2",
        "dxva2-copy",
        "cuda",
        "cuda-copy",
      ]),
      AppSettingsController.instance.videoHardwareDecoder.value,
    );
  }

  void cleanLog() async {
    if (AppSettingsController.instance.logEnable.value) {
      SmartDialog.showToast("请先关闭日志记录");
      return;
    }

    var supportDir = await getApplicationSupportDirectory();
    var logDir = Directory("${supportDir.path}/log");
    if (await logDir.exists()) {
      await logDir.delete(recursive: true);
    }
    loadLogFiles();
  }

  Future<void> openLogDirectory() async {
    await DiagnosticService.openLogDirectory();
  }

  Future<void> exportDiagnosticBundle() async {
    await DiagnosticService.exportDiagnosticBundle(
      fileNamePrefix: "livehub_settings",
      contextData: <String, dynamic>{
        'scope': 'settings',
        'logEnabled': AppSettingsController.instance.logEnable.value,
        'logFileCount': logFiles.length,
        'customPlayerOutput':
            AppSettingsController.instance.customPlayerOutput.value,
        'videoOutputDriver':
            AppSettingsController.instance.videoOutputDriver.value,
        'audioOutputDriver':
            AppSettingsController.instance.audioOutputDriver.value,
        'videoHardwareDecoder':
            AppSettingsController.instance.videoHardwareDecoder.value,
      },
    );
  }

  void saveLogFile(LogFileModel item) async {
    var filePath = await FilePicker.platform.saveFile(
      allowedExtensions: ['log'],
      type: FileType.custom,
      fileName: item.name,
      bytes: Uint8List(0),
    );
    if (filePath != null) {
      var file = File(item.path);
      await file.copy(filePath);
      SmartDialog.showToast("保存成功");
    }
  }

  void resetDefaultConfig() {
    Utils.showAlertDialog("是否重置所有配置为默认值?").then((value) {
      if (value) {
        LocalStorageService.instance.settingsBox.clear();
        LocalStorageService.instance.shieldBox.clear();
        SmartDialog.showToast("重置成功,重启生效");
      }
    });
  }
}

class LogFileModel {
  late String name;
  late String path;
  late DateTime time;
  late int size;
  LogFileModel(this.name, this.path, this.time, this.size);
}

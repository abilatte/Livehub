import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/services/db_service.dart';
import 'package:livehub_app/services/follow_service.dart';
import 'package:livehub_app/services/local_storage_service.dart';

class BackupImportSummary {
  final bool configImported;
  final bool shieldImported;
  final int shieldCount;
  final bool followImported;
  final int followCount;

  const BackupImportSummary({
    this.configImported = false,
    this.shieldImported = false,
    this.shieldCount = 0,
    this.followImported = false,
    this.followCount = 0,
  });

  bool get hasChanges => configImported || shieldImported || followImported;

  BackupImportSummary merge(BackupImportSummary other) {
    return BackupImportSummary(
      configImported: configImported || other.configImported,
      shieldImported: shieldImported || other.shieldImported,
      shieldCount: other.shieldImported ? other.shieldCount : shieldCount,
      followImported: followImported || other.followImported,
      followCount: other.followImported ? other.followCount : followCount,
    );
  }

  String toMessage() {
    final parts = <String>[];
    if (configImported) {
      parts.add("配置");
    }
    if (shieldImported) {
      parts.add("屏蔽词 $shieldCount 项");
    }
    if (followImported) {
      parts.add("关注列表 $followCount 项");
    }
    if (parts.isEmpty) {
      return "没有找到可导入的数据";
    }
    return "已导入：${parts.join("、")}";
  }
}

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const int exportVersion = 1;

  static const String configType = "livehub_config";
  static const String shieldType = "livehub_shield_list";
  static const String followType = "livehub_follow_list";
  static const String legacyConfigType = "simple_live";
  static const String legacyConfigFileType = "simple_live_config";
  static const String legacyShieldType = "simple_live_shield_list";
  static const String legacyFollowType = "simple_live_follow_list";

  static const String configFileName = "livehub_config.json";
  static const String shieldFileName = "livehub_shield_list.json";
  static const String followFileName = "livehub_follow_list.json";

  static const String _backupFolderPrefix = "LiveHub_Backup_";

  static Map<String, dynamic> buildConfigPayload({
    required Map<dynamic, dynamic> settings,
    required String platform,
    DateTime? now,
  }) {
    return {
      "type": configType,
      "platform": platform,
      "version": exportVersion,
      "time": (now ?? DateTime.now()).millisecondsSinceEpoch,
      "config": _normalizeSettingsMap(settings),
    };
  }

  static Map<String, dynamic> buildShieldPayload({
    required Iterable<String> shieldWords,
    required String platform,
    DateTime? now,
  }) {
    return {
      "type": shieldType,
      "platform": platform,
      "version": exportVersion,
      "time": (now ?? DateTime.now()).millisecondsSinceEpoch,
      "shield": normalizeShieldWords(shieldWords),
    };
  }

  static Map<String, dynamic> buildFollowPayload({
    required Iterable<FollowUser> follows,
    required String platform,
    DateTime? now,
  }) {
    return {
      "type": followType,
      "platform": platform,
      "version": exportVersion,
      "time": (now ?? DateTime.now()).millisecondsSinceEpoch,
      "follow": follows.map((item) => item.toJson()).toList(),
    };
  }

  static Map<String, String> buildAllExportFiles({
    required Map<dynamic, dynamic> settings,
    required Iterable<String> shieldWords,
    required Iterable<FollowUser> follows,
    required String platform,
    DateTime? now,
  }) {
    return {
      configFileName: jsonEncode(
        buildConfigPayload(settings: settings, platform: platform, now: now),
      ),
      shieldFileName: jsonEncode(
        buildShieldPayload(
          shieldWords: shieldWords,
          platform: platform,
          now: now,
        ),
      ),
      followFileName: jsonEncode(
        buildFollowPayload(
          follows: follows,
          platform: platform,
          now: now,
        ),
      ),
    };
  }

  static Map<String, dynamic> decodePayloadMap(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException("备份文件格式不正确");
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  static Map<String, dynamic> extractConfigEntries(Map<String, dynamic> payload) {
    final type = payload["type"]?.toString();
    if (type != configType &&
        type != legacyConfigType &&
        type != legacyConfigFileType) {
      throw const FormatException("不是配置文件");
    }
    final config = payload["config"];
    if (config is! Map) {
      throw const FormatException("配置内容缺失");
    }
    return Map<String, dynamic>.from(config.map(
      (key, value) => MapEntry(key.toString(), value),
    ));
  }

  static List<String> extractShieldWords(Map<String, dynamic> payload) {
    final type = payload["type"]?.toString();
    if (type != shieldType &&
        type != legacyConfigType &&
        type != legacyShieldType) {
      throw const FormatException("不是屏蔽词文件");
    }

    final shield = payload["shield"];
    if (shield is Map) {
      return normalizeShieldWords(shield.values);
    }
    if (shield is List) {
      return normalizeShieldWords(shield);
    }
    if (shield == null) {
      return <String>[];
    }
    throw const FormatException("屏蔽词内容缺失");
  }

  static List<FollowUser> extractFollowUsers(String content) {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return _mapFollowEntries(decoded);
    }
    if (decoded is! Map) {
      throw const FormatException("关注列表文件格式不正确");
    }

    final payload = Map<String, dynamic>.from(decoded as Map);
    final type = payload["type"]?.toString();
    if (type != followType && type != legacyFollowType) {
      throw const FormatException("不是关注列表文件");
    }
    final follow = payload["follow"];
    if (follow is! List) {
      throw const FormatException("关注列表内容缺失");
    }
    return _mapFollowEntries(follow);
  }

  static List<String> normalizeShieldWords(Iterable<dynamic> words) {
    final result = <String>[];
    final seen = <String>{};
    for (final item in words) {
      final value = item.toString().trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      result.add(value);
    }
    return result;
  }

  static String buildBackupFolderName({DateTime? now}) {
    final time = now ?? DateTime.now();
    String pad(int value) => value.toString().padLeft(2, '0');
    return "$_backupFolderPrefix"
        "${time.year}${pad(time.month)}${pad(time.day)}_"
        "${pad(time.hour)}${pad(time.minute)}${pad(time.second)}";
  }

  Future<String?> exportAll() async {
    final rootPath = await FilePicker.platform.getDirectoryPath();
    if (rootPath == null || rootPath.isEmpty) {
      return null;
    }

    final backupDir = Directory(
      p.join(rootPath, buildBackupFolderName()),
    );
    await backupDir.create(recursive: true);

    final files = buildAllExportFiles(
      settings: LocalStorageService.instance.settingsBox.toMap(),
      shieldWords: _readShieldWords(),
      follows: DBService.instance.getFollowList(),
      platform: Platform.operatingSystem,
    );

    for (final entry in files.entries) {
      await File(p.join(backupDir.path, entry.key)).writeAsString(entry.value);
    }

    return backupDir.path;
  }

  Future<String?> exportConfigFile() async {
    return _saveJsonFile(
      fileName: configFileName,
      content: jsonEncode(
        buildConfigPayload(
          settings: LocalStorageService.instance.settingsBox.toMap(),
          platform: Platform.operatingSystem,
        ),
      ),
    );
  }

  Future<String?> exportShieldFile() async {
    return _saveJsonFile(
      fileName: shieldFileName,
      content: jsonEncode(
        buildShieldPayload(
          shieldWords: _readShieldWords(),
          platform: Platform.operatingSystem,
        ),
      ),
    );
  }

  Future<String?> exportFollowFile() async {
    return _saveJsonFile(
      fileName: followFileName,
      content: jsonEncode(
        buildFollowPayload(
          follows: DBService.instance.getFollowList(),
          platform: Platform.operatingSystem,
        ),
      ),
    );
  }

  Future<BackupImportSummary?> importAll() async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null || dirPath.isEmpty) {
      return null;
    }
    return importAllFromDirectory(dirPath);
  }

  Future<BackupImportSummary> importAllFromDirectory(String dirPath) async {
    final files = await _scanBackupDirectory(dirPath);
    if (files.isEmpty) {
      throw Exception("所选目录里没有可识别的备份文件");
    }

    var summary = const BackupImportSummary();

    if (files.configContent != null) {
      summary = summary.merge(
        await _applyConfigContent(
          files.configContent!,
          importLegacyShield: files.shieldContent == null,
        ),
      );
    }

    if (files.shieldContent != null) {
      summary = summary.merge(
        await _applyShieldContent(files.shieldContent!),
      );
    }

    if (files.followContent != null) {
      summary = summary.merge(
        await _applyFollowContent(files.followContent!, refreshFollow: false),
      );
      await FollowService.instance.loadData();
    }

    return summary;
  }

  Future<BackupImportSummary?> importConfigFile() async {
    final filePath = await _pickJsonFile();
    if (filePath == null) {
      return null;
    }
    return _applyConfigFile(filePath);
  }

  Future<BackupImportSummary?> importShieldFile() async {
    final filePath = await _pickJsonFile();
    if (filePath == null) {
      return null;
    }
    return _applyShieldFile(filePath);
  }

  Future<BackupImportSummary?> importFollowFile() async {
    final filePath = await _pickJsonFile();
    if (filePath == null) {
      return null;
    }
    return _applyFollowFile(filePath);
  }

  Future<BackupImportSummary> _applyConfigFile(String filePath) async {
    final content = await File(filePath).readAsString();
    return _applyConfigContent(content, importLegacyShield: true);
  }

  Future<BackupImportSummary> _applyShieldFile(String filePath) async {
    final content = await File(filePath).readAsString();
    return _applyShieldContent(content);
  }

  Future<BackupImportSummary> _applyFollowFile(String filePath) async {
    final content = await File(filePath).readAsString();
    return _applyFollowContent(content);
  }

  Future<BackupImportSummary> _applyConfigContent(
    String content, {
    required bool importLegacyShield,
  }) async {
    final payload = decodePayloadMap(content);
    final type = payload["type"]?.toString();
    final config = extractConfigEntries(payload);
    await LocalStorageService.instance.settingsBox.clear();
    await LocalStorageService.instance.settingsBox.putAll(config);

    var summary = const BackupImportSummary(configImported: true);

    final hasLegacyShield = type == legacyConfigType && payload.containsKey("shield");
    if (importLegacyShield && hasLegacyShield) {
      final shieldWords = extractShieldWords(payload);
      await AppSettingsController.instance.replaceShieldList(shieldWords);
      summary = summary.merge(
        BackupImportSummary(
          shieldImported: true,
          shieldCount: shieldWords.length,
        ),
      );
    }

    return summary;
  }

  Future<BackupImportSummary> _applyShieldContent(String content) async {
    final payload = decodePayloadMap(content);
    final shieldWords = extractShieldWords(payload);
    await AppSettingsController.instance.replaceShieldList(shieldWords);
    return BackupImportSummary(
      shieldImported: true,
      shieldCount: shieldWords.length,
    );
  }

  Future<BackupImportSummary> _applyFollowContent(
    String content, {
    bool refreshFollow = true,
  }) async {
    final follows = extractFollowUsers(content);
    await FollowService.instance.importUsers(follows);
    if (refreshFollow) {
      await FollowService.instance.loadData();
    }
    return BackupImportSummary(
      followImported: true,
      followCount: follows.length,
    );
  }

  Future<String?> _saveJsonFile({
    required String fileName,
    required String content,
  }) async {
    final filePath = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      fileName: fileName,
    );
    if (filePath == null || filePath.isEmpty) {
      return null;
    }
    await File(filePath).writeAsString(content);
    return filePath;
  }

  Future<String?> _pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return result?.files.single.path;
  }

  List<String> _readShieldWords() {
    return LocalStorageService.instance.shieldBox.values
        .map((item) => item.toString())
        .toList();
  }

  Future<_BackupFileContents> _scanBackupDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      throw Exception("备份目录不存在");
    }

    final result = _BackupFileContents();
    final entities = directory
        .listSync()
        .whereType<File>()
        .where((item) => p.extension(item.path).toLowerCase() == '.json')
        .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    for (final file in entities) {
      final content = await file.readAsString();
      final kind = detectBackupKind(content);
      if (kind == null) {
        continue;
      }

      if ((kind == configType ||
              kind == legacyConfigType ||
              kind == legacyConfigFileType) &&
          result.configContent == null) {
        result.configContent = content;
        continue;
      }

      if ((kind == shieldType || kind == legacyShieldType) &&
          result.shieldContent == null) {
        result.shieldContent = content;
        continue;
      }

      if ((kind == followType || kind == legacyFollowType) &&
          result.followContent == null) {
        result.followContent = content;
      }
    }

    return result;
  }

  static String? detectBackupKind(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return followType;
      }
      if (decoded is! Map) {
        return null;
      }
      final type = decoded["type"]?.toString();
      if ({
        configType,
        shieldType,
        followType,
        legacyConfigType,
        legacyConfigFileType,
        legacyShieldType,
        legacyFollowType,
      }.contains(type)) {
        return type;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _normalizeSettingsMap(
    Map<dynamic, dynamic> settings,
  ) {
    return settings.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static List<FollowUser> _mapFollowEntries(List<dynamic> entries) {
    return entries
        .map((item) => FollowUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class _BackupFileContents {
  String? configContent;
  String? shieldContent;
  String? followContent;

  bool get isEmpty =>
      configContent == null && shieldContent == null && followContent == null;
}

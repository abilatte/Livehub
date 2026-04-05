import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/app/utils.dart';

class DiagnosticService {
  static Future<Directory> ensureLogDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory(p.join(supportDir.path, 'log'));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return logDir;
  }

  static Future<List<File>> getLogFiles({int maxCount = 5}) async {
    final logDir = await ensureLogDirectory();
    final entities = await logDir.list().toList();
    final files = entities.whereType<File>().toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (files.length <= maxCount) {
      return files;
    }
    return files.take(maxCount).toList();
  }

  static Future<void> openLogDirectory() async {
    final logDir = await ensureLogDirectory();
    await Utils.openDirectory(logDir.path);
  }

  static Future<String?> exportDiagnosticBundle({
    required String fileNamePrefix,
    Map<String, dynamic>? contextData,
    int maxLogFiles = 5,
  }) async {
    try {
      final archive = Archive();
      final payload = await _buildDiagnosticPayload(
        contextData: contextData ?? <String, dynamic>{},
        maxLogFiles: maxLogFiles,
      );
      final jsonBytes = Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert(payload),
        ),
      );
      archive.addFile(
        ArchiveFile('diagnostic.json', jsonBytes.length, jsonBytes),
      );

      final logFiles = await getLogFiles(maxCount: maxLogFiles);
      for (final file in logFiles) {
        final bytes = await file.readAsBytes();
        archive.addFile(
          ArchiveFile('logs/${p.basename(file.path)}', bytes.length, bytes),
        );
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        SmartDialog.showToast("导出诊断包失败");
        return null;
      }

      final fileName =
          "${fileNamePrefix}_${DateFormat("yyyy-MM-dd_HH-mm-ss").format(DateTime.now())}.zip";
      final savePath = await FilePicker.platform.saveFile(
        allowedExtensions: ['zip'],
        type: FileType.custom,
        fileName: fileName,
      );
      if (savePath == null || savePath.isEmpty) {
        SmartDialog.showToast("已取消导出");
        return null;
      }

      await File(savePath).writeAsBytes(zipBytes, flush: true);
      SmartDialog.showToast("诊断包已导出");
      return savePath;
    } catch (e, s) {
      Log.e("导出诊断包失败：$e", s);
      SmartDialog.showToast("导出诊断包失败");
      return null;
    }
  }

  static Future<Map<String, dynamic>> _buildDiagnosticPayload({
    required Map<String, dynamic> contextData,
    required int maxLogFiles,
  }) async {
    final logFiles = await getLogFiles(maxCount: maxLogFiles);
    final logDir = await ensureLogDirectory();
    return <String, dynamic>{
      'createdAt': DateTime.now().toIso8601String(),
      'app': <String, dynamic>{
        'version': Utils.packageInfo.version,
        'buildNumber': Utils.packageInfo.buildNumber,
      },
      'system': await _buildSystemInfo(),
      'logDirectory': logDir.path,
      'context': contextData,
      'logs': logFiles
          .map(
            (file) => <String, dynamic>{
              'name': p.basename(file.path),
              'size': file.lengthSync(),
              'updatedAt': file.lastModifiedSync().toIso8601String(),
              'tailPreview': _readLogTailPreview(file),
            },
          )
          .toList(),
    };
  }

  static Future<Map<String, dynamic>> _buildSystemInfo() async {
    final baseInfo = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isWindows) {
        baseInfo['deviceInfo'] = (await deviceInfo.windowsInfo).data.toString();
      } else {
        baseInfo['deviceInfo'] = '当前平台暂不支持读取设备信息';
      }
    } catch (e, s) {
      Log.e("读取系统信息失败：$e", s);
    }
    return baseInfo;
  }

  static List<String> _readLogTailPreview(File file, {int maxLines = 20}) {
    try {
      final lines = file.readAsLinesSync();
      if (lines.length <= maxLines) {
        return lines;
      }
      return lines.sublist(lines.length - maxLines);
    } catch (e, s) {
      Log.e("读取日志预览失败：$e", s);
      return const <String>[];
    }
  }
}

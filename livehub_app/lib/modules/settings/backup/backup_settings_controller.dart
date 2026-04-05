import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:livehub_app/services/backup_service.dart';

class BackupSettingsController extends GetxController {
  Future<void> exportAll() async {
    await _runAction(
      action: BackupService.instance.exportAll,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast("已导出到：$result");
        }
      },
      errorPrefix: "导出全部失败",
    );
  }

  Future<void> importAll() async {
    await _runAction(
      action: BackupService.instance.importAll,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast(result.toMessage());
        }
      },
      errorPrefix: "导入全部失败",
    );
  }

  Future<void> exportConfig() async {
    await _runAction(
      action: BackupService.instance.exportConfigFile,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast("配置已导出");
        }
      },
      errorPrefix: "导出配置失败",
    );
  }

  Future<void> importConfig() async {
    await _runAction(
      action: BackupService.instance.importConfigFile,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast("${result.toMessage()}，部分设置需要重启后生效");
        }
      },
      errorPrefix: "导入配置失败",
    );
  }

  Future<void> exportFollow() async {
    await _runAction(
      action: BackupService.instance.exportFollowFile,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast("关注列表已导出");
        }
      },
      errorPrefix: "导出关注列表失败",
    );
  }

  Future<void> importFollow() async {
    await _runAction(
      action: BackupService.instance.importFollowFile,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast(result.toMessage());
        }
      },
      errorPrefix: "导入关注列表失败",
    );
  }

  Future<void> exportShield() async {
    await _runAction(
      action: BackupService.instance.exportShieldFile,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast("屏蔽词已导出");
        }
      },
      errorPrefix: "导出屏蔽词失败",
    );
  }

  Future<void> importShield() async {
    await _runAction(
      action: BackupService.instance.importShieldFile,
      onSuccess: (result) {
        if (result != null) {
          SmartDialog.showToast(result.toMessage());
        }
      },
      errorPrefix: "导入屏蔽词失败",
    );
  }

  Future<void> _runAction<T>({
    required Future<T?> Function() action,
    required void Function(T? result) onSuccess,
    required String errorPrefix,
  }) async {
    try {
      final result = await action();
      onSuccess(result);
    } catch (e) {
      SmartDialog.showToast("$errorPrefix：$e");
    }
  }
}

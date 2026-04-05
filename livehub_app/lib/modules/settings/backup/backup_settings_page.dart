import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/modules/settings/backup/backup_settings_controller.dart';
import 'package:livehub_app/services/backup_service.dart';
import 'package:livehub_app/widgets/settings/settings_card.dart';

class BackupSettingsPage extends GetView<BackupSettingsController> {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("备份与迁移"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsA12.copyWith(top: 4),
            child: const Text(
              "把配置、关注列表和屏蔽词集中管理。导出全部时会创建一个备份文件夹，里面分开存放三份 JSON。",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _buildSection(
            title: "一键操作",
            child: SettingsCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text("导出全部"),
                    subtitle: const Text("一次导出配置、关注列表和屏蔽词，分别写入同一个备份目录"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.exportAll();
                    },
                  ),
                  AppStyle.divider,
                  ListTile(
                    leading: const Icon(Icons.restore_page_outlined),
                    title: const Text("导入全部"),
                    subtitle: const Text("选择备份目录后自动识别可导入的文件，并兼容旧版配置格式"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      controller.importAll();
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildSection(
            title: "单独处理",
            child: SettingsCard(
              child: Column(
                children: [
                  _buildTransferItem(
                    icon: Remix.settings_3_line,
                    title: "配置",
                    subtitle: "主题、播放器、账号和常用设置。导入后部分设置需要重启生效。",
                    onExport: () {
                      controller.exportConfig();
                    },
                    onImport: () {
                      controller.importConfig();
                    },
                  ),
                  AppStyle.divider,
                  _buildTransferItem(
                    icon: Remix.heart_line,
                    title: "关注列表",
                    subtitle: "导出或导入当前关注数据。导入时沿用现有的非破坏式合并逻辑。",
                    onExport: () {
                      controller.exportFollow();
                    },
                    onImport: () {
                      controller.importFollow();
                    },
                  ),
                  AppStyle.divider,
                  _buildTransferItem(
                    icon: Remix.forbid_2_line,
                    title: "屏蔽词",
                    subtitle: "单独备份弹幕屏蔽词，迁移到另一台电脑时更方便。",
                    onExport: () {
                      controller.exportShield();
                    },
                    onImport: () {
                      controller.importShield();
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildSection(
            title: "文件说明",
            child: SettingsCard(
              child: Padding(
                padding: AppStyle.edgeInsetsA16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "导出全部会创建类似下面这样的目录：",
                      style: TextStyle(fontSize: 13),
                    ),
                    AppStyle.vGap8,
                    Text(
                      "${BackupService.buildBackupFolderName(now: DateTime(2026, 3, 21, 15, 0, 0))}\\\n"
                      "  ├─ ${BackupService.configFileName}\n"
                      "  ├─ ${BackupService.followFileName}\n"
                      "  └─ ${BackupService.shieldFileName}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    AppStyle.vGap12,
                    const Text(
                      "导入全部时会优先读取这三份文件；如果目录里只有旧版配置文件，也会尽量兼容旧格式。",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppStyle.edgeInsetsA12.copyWith(top: 16),
          child: Text(
            title,
            style: Get.textTheme.titleSmall,
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildTransferItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onExport,
    required VoidCallback onImport,
  }) {
    return Padding(
      padding: AppStyle.edgeInsetsA16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              AppStyle.hGap8,
              Text(
                title,
                style: Get.textTheme.titleSmall,
              ),
            ],
          ),
          AppStyle.vGap4,
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          AppStyle.vGap12,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Remix.export_line, size: 16),
                  label: const Text("导出"),
                ),
              ),
              AppStyle.hGap12,
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Remix.import_line, size: 16),
                  label: const Text("导入"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

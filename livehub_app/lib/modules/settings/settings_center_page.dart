import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/routes/route_path.dart';
import 'package:livehub_app/widgets/settings/settings_card.dart';

class SettingsCenterPage extends StatelessWidget {
  const SettingsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置中心"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          _buildSection(
            title: "播放与直播",
            children: [
              _buildSettingsItem(
                icon: Remix.play_circle_line,
                title: "直播设置",
                subtitle: "画面比例、播放器和直播间相关设置",
                route: RoutePath.kSettingsPlay,
              ),
              _buildSettingsItem(
                icon: Remix.timer_2_line,
                title: "定时关闭",
                subtitle: "定时关闭软件或结束观看",
                route: RoutePath.kSettingsAutoExit,
              ),
            ],
          ),
          _buildSection(
            title: "弹幕与聊天",
            children: [
              _buildSettingsItem(
                icon: Remix.text,
                title: "弹幕设置",
                subtitle: "弹幕显示、样式和播放器内弹幕相关选项",
                route: RoutePath.kSettingsDanmu,
              ),
              _buildSettingsItem(
                icon: Remix.forbid_2_line,
                title: "关键词屏蔽",
                subtitle: "管理弹幕屏蔽词",
                route: RoutePath.kSettingsDanmuShield,
              ),
            ],
          ),
          _buildSection(
            title: "关注与主页",
            children: [
              _buildSettingsItem(
                icon: Remix.home_2_line,
                title: "主页设置",
                subtitle: "调整首页显示内容和默认站点",
                route: RoutePath.kSettingsIndexed,
              ),
              _buildSettingsItem(
                icon: Remix.heart_line,
                title: "关注设置",
                subtitle: "管理关注列表相关行为",
                route: RoutePath.kSettingsFollow,
              ),
            ],
          ),
          _buildSection(
            title: "数据与迁移",
            children: [
              _buildSettingsItem(
                icon: Icons.backup_outlined,
                title: "备份与迁移",
                subtitle: "集中管理配置、关注列表和屏蔽词的导入导出",
                route: RoutePath.kSettingsBackup,
              ),
            ],
          ),
          _buildSection(
            title: "外观与账号",
            children: [
              _buildSettingsItem(
                icon: Remix.moon_line,
                title: "外观设置",
                subtitle: "主题、颜色和界面外观",
                route: RoutePath.kAppstyleSetting,
              ),
              _buildSettingsItem(
                icon: Remix.account_circle_line,
                title: "账号管理",
                subtitle: "管理各平台登录状态",
                route: RoutePath.kSettingsAccount,
              ),
            ],
          ),
          _buildSection(
            title: "日志与高级设置",
            children: [
              _buildSettingsItem(
                icon: Remix.apps_line,
                title: "其他设置",
                subtitle: "日志、诊断和播放器高级选项",
                route: RoutePath.kSettingsOther,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
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
        SettingsCard(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: () {
        Get.toNamed(route);
      },
    );
  }
}

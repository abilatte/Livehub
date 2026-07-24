import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/widgets/net_image.dart';
import 'package:livehub_core/livehub_core.dart';

/// Empty-safe contribution rank list for the live room sidebar / sheet.
class LiveContributionRankPanel extends StatelessWidget {
  final List<LiveContributionRankItem> items;
  final bool loading;
  final String? errorText;
  final VoidCallback? onRetry;

  const LiveContributionRankPanel({
    super.key,
    required this.items,
    this.loading = false,
    this.errorText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (errorText != null && errorText!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: AppStyle.edgeInsetsA16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorText!, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                AppStyle.vGap12,
                TextButton(onPressed: onRetry, child: const Text("重试")),
              ],
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          "暂无贡献榜数据",
          style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: AppStyle.edgeInsetsA12,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  "${item.rank > 0 ? item.rank : index + 1}",
                  textAlign: TextAlign.center,
                  style: Get.textTheme.titleSmall,
                ),
              ),
              AppStyle.hGap8,
              ClipOval(
                child: NetImage(
                  item.avatar,
                  width: 36,
                  height: 36,
                ),
              ),
            ],
          ),
          title: Text(item.userName.isEmpty ? "匿名用户" : item.userName),
          trailing: Text(
            item.scoreText,
            style: Get.textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

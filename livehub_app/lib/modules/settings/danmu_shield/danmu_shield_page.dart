import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/modules/settings/danmu_shield/danmu_shield_controller.dart';

class DanmuShieldPage extends GetView<DanmuShieldController> {
  const DanmuShieldPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("弹幕屏蔽"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          TextField(
            controller: controller.textEditingController,
            decoration: InputDecoration(
              contentPadding: AppStyle.edgeInsetsH12,
              border: const OutlineInputBorder(),
              hintText: "请输入关键词或正则表达式",
              suffixIcon: TextButton.icon(
                onPressed: controller.add,
                icon: const Icon(Icons.add),
                label: const Text("添加"),
              ),
            ),
            onSubmitted: (e) {
              controller.add();
            },
          ),
          AppStyle.vGap4,
          Text(
            '以"/"开头和结尾将视作正则表达式, 如"/\\d+/"表示屏蔽所有数字',
            style: Get.textTheme.bodySmall,
          ),
          AppStyle.vGap12,
          Obx(
            () => Text(
              "已添加${controller.settingsController.shieldList.length}个关键词（点击移除）",
              style: Get.textTheme.titleSmall,
            ),
          ),
          AppStyle.vGap12,
          Obx(
            () => Wrap(
              runSpacing: 12,
              spacing: 12,
              children: controller.settingsController.shieldList
                  .map(
                    (item) => InkWell(
                      borderRadius: AppStyle.radius24,
                      onTap: () {
                        controller.remove(item);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: AppStyle.radius24,
                        ),
                        padding: AppStyle.edgeInsetsH12.copyWith(
                          top: 4,
                          bottom: 4,
                        ),
                        child: Text(
                          item,
                          style: Get.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          AppStyle.vGap24,
          Obx(
            () {
              final entries =
                  controller.settingsController.allUserShieldEntries;
              return Text(
                "平台用户屏蔽（${entries.length}，来自弹幕菜单，点击移除）",
                style: Get.textTheme.titleSmall,
              );
            },
          ),
          AppStyle.vGap8,
          Text(
            "仅对指定直播平台生效，不会误伤其他平台同名用户。",
            style: Get.textTheme.bodySmall,
          ),
          AppStyle.vGap12,
          Obx(
            () {
              final entries =
                  controller.settingsController.allUserShieldEntries;
              if (entries.isEmpty) {
                return Text(
                  "暂无平台屏蔽用户。在直播间点击弹幕可添加。",
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                );
              }
              return Wrap(
                runSpacing: 12,
                spacing: 12,
                children: entries.map((entry) {
                  final siteName =
                      Sites.allSites[entry.siteId]?.name ?? entry.siteId;
                  return InkWell(
                    borderRadius: AppStyle.radius24,
                    onTap: () {
                      controller.removeUserShield(
                        userName: entry.userName,
                        siteId: entry.siteId,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: AppStyle.radius24,
                      ),
                      padding: AppStyle.edgeInsetsH12.copyWith(
                        top: 4,
                        bottom: 4,
                      ),
                      child: Text(
                        "$siteName · ${entry.userName}",
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/modules/search/douyin/douyin_search_controller.dart';
import 'package:livehub_app/widgets/keep_alive_wrapper.dart';
import 'package:livehub_app/widgets/status/app_loadding_widget.dart';

class DouyinSearchView extends StatelessWidget {
  const DouyinSearchView({Key? key}) : super(key: key);
  DouyinSearchController get controller => Get.find<DouyinSearchController>();

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Padding(
                padding: AppStyle.edgeInsetsA12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "暂不支持抖音搜索，请打开浏览器搜索，然后复制直播间链接进行解析",
                      textAlign: TextAlign.center,
                    ),
                    TextButton.icon(
                      onPressed: controller.openBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text("打开浏览器"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(
            () => Visibility(
              visible: controller.pageLoadding.value,
              child: const AppLoaddingWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

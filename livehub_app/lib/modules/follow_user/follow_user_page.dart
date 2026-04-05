import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/modules/follow_user/follow_user_controller.dart';
import 'package:livehub_app/modules/follow_user/follow_user_filter_utils.dart';
import 'package:livehub_app/routes/app_navigation.dart';
import 'package:livehub_app/widgets/filter_button.dart';
import 'package:livehub_app/widgets/follow_user_item.dart';
import 'package:livehub_app/widgets/page_grid_view.dart';

class FollowUserPage extends GetView<FollowUserController> {
  const FollowUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    var count = MediaQuery.of(context).size.width ~/ 500;
    if (count < 1) count = 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text("关注用户"),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Obx(
            () => controller.followService.updating.value
                ? const IconButton(
                    onPressed: null,
                    icon: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: controller.refreshData,
                    icon: const Icon(Icons.refresh),
                  ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsL8,
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 12,
                        children: kDefaultFollowFilters.map((option) {
                          return FilterButton(
                            text: option.label,
                            selected: controller.filterMode.value == option,
                            onTap: () {
                              controller.setFilterMode(option);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageGridView(
              crossAxisSpacing: 12,
              crossAxisCount: count,
              pageController: controller,
              firstRefresh: true,
              showPCRefreshButton: false,
              itemBuilder: (_, i) {
                final item = controller.list[i];
                final site = Sites.allSites[item.siteId]!;
                return FollowUserItem(
                  item: item,
                  onRemove: () {
                    controller.removeItem(item);
                  },
                  onTap: () {
                    AppNavigator.toLiveRoomDetail(
                      site: site,
                      roomId: item.roomId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

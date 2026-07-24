import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/modules/multi_room/multi_room_controller.dart';
import 'package:livehub_app/modules/multi_room/multi_room_models.dart';
import 'package:livehub_app/modules/multi_room/multi_room_player_controller.dart';
import 'package:livehub_app/modules/multi_room/multi_room_utils.dart';

class MultiRoomPage extends GetView<MultiRoomController> {
  const MultiRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Obx(() => Text("多开同屏（${controller.rooms.length}）")),
        actions: [
          IconButton(
            tooltip: "全部刷新",
            onPressed: () {
              for (final room in controller.rooms) {
                controller.playerFor(room).refreshRoom();
              }
            },
            icon: const Icon(Remix.refresh_line),
          ),
          IconButton(
            tooltip: "全部关闭",
            onPressed: () {
              controller.stopAll();
              Get.back();
            },
            icon: const Icon(Remix.close_circle_line),
          ),
        ],
      ),
      body: Obx(
        () {
          if (controller.rooms.isEmpty) {
            return const Center(
              child: Text(
                "请从关注列表选择至少 2 个直播间",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final count = MultiRoomUtils.gridColumnCount(
                roomCount: controller.rooms.length,
                maxWidth: constraints.maxWidth,
              );
              const gap = 8.0;
              return GridView.builder(
                padding: const EdgeInsets.all(gap),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  childAspectRatio: 16 / 9,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                ),
                itemCount: controller.rooms.length,
                itemBuilder: (context, index) {
                  final room = controller.rooms[index];
                  return _MultiRoomTile(
                    item: room,
                    controller: controller.playerFor(room),
                    onRemove: () => controller.removeRoom(room),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MultiRoomTile extends StatelessWidget {
  final MultiRoomItem item;
  final MultiRoomPlayerController controller;
  final VoidCallback onRemove;

  const _MultiRoomTile({
    required this.item,
    required this.controller,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppStyle.radius8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white24),
          borderRadius: AppStyle.radius8,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: controller.videoController,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),
            Positioned.fill(
              child: Obx(
                () {
                  if (controller.loading.value) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (controller.errorText.value.isNotEmpty) {
                    return _CenterText(controller.errorText.value);
                  }
                  if (!controller.liveStatus.value) {
                    return const _CenterText("未开播");
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "静音切换",
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.toggleMute,
                    icon: Obx(
                      () => Icon(
                        controller.muted.value
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "移除",
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterText extends StatelessWidget {
  final String text;
  const _CenterText(this.text);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

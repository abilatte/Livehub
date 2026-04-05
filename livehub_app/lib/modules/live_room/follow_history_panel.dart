import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/controller/app_settings_controller.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/models/db/history.dart';
import 'package:livehub_app/modules/live_room/follow_history_tab_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_performance_utils.dart';
import 'package:livehub_app/modules/live_room/live_room_controller.dart';
import 'package:livehub_app/services/db_service.dart';
import 'package:livehub_app/services/follow_service.dart';
import 'package:livehub_app/services/history_live_status_service.dart';
import 'package:livehub_app/widgets/desktop_refresh_button.dart';
import 'package:livehub_app/widgets/follow_user_item.dart';
import 'package:livehub_app/widgets/net_image.dart';

const int _historyPageSize = 20;

class FollowHistoryPanel extends StatefulWidget {
  final LiveRoomController controller;
  final VoidCallback onClose;

  const FollowHistoryPanel({
    required this.controller,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  State<FollowHistoryPanel> createState() => _FollowHistoryPanelState();
}

class _FollowHistoryPanelState extends State<FollowHistoryPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, HistoryLiveState> _historyLiveStates =
      <String, HistoryLiveState>{};
  final Set<String> _historyStatusRequestedIds = <String>{};
  final ScrollController _historyScrollController = ScrollController();
  List<History> _historyList = const <History>[];
  Map<String, FollowUser> _followLookup = const <String, FollowUser>{};
  bool _historyStatusLoading = false;
  bool _historyStatusLoadScheduled = false;
  bool _historyVisibleExpandScheduled = false;
  bool _historyStatusReloadRequested = false;
  int _visibleHistoryCount = 0;

  bool get _showFollowList =>
      AppSettingsController.instance.liveRoomPopupShowFollowList.value;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: followHistoryTabToIndex(
        _showFollowList ? FollowHistoryTab.follow : FollowHistoryTab.history,
      ),
    );
    _tabController.addListener(_handleTabChanged);
    _historyScrollController.addListener(_handleHistoryScroll);
    _refreshHistoryCache();
    _syncVisibleHistoryStates();
    if (!_showFollowList) {
      _scheduleHistoryStatusLoad();
    }
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    AppSettingsController.instance
        .setLiveRoomPopupShowFollowList(isFollowTabIndex(_tabController.index));
    if (!isFollowTabIndex(_tabController.index)) {
      _scheduleHistoryStatusLoad();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleHistoryStatusLoad() {
    if (_historyStatusLoadScheduled) {
      return;
    }
    _historyStatusLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyStatusLoadScheduled = false;
      _loadHistoryStatusesIfNeeded();
    });
  }

  void _handleHistoryScroll() {
    if (!_historyScrollController.hasClients) {
      return;
    }
    if (!shouldLoadMoreHistory(
      extentAfter: _historyScrollController.position.extentAfter,
    )) {
      return;
    }
    _scheduleHistoryVisibleExpand();
  }

  void _scheduleHistoryVisibleExpand() {
    if (_historyVisibleExpandScheduled) {
      return;
    }
    _historyVisibleExpandScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyVisibleExpandScheduled = false;
      final nextVisibleCount = expandHistoryVisibleCount(
        totalCount: _historyList.length,
        currentCount: _visibleHistoryCount,
        pageSize: _historyPageSize,
      );
      if (nextVisibleCount == _visibleHistoryCount) {
        return;
      }
      if (mounted) {
        setState(() {
          _visibleHistoryCount = nextVisibleCount;
        });
      } else {
        _visibleHistoryCount = nextVisibleCount;
      }
      _scheduleHistoryStatusLoad();
    });
  }

  void _refreshHistoryCache() {
    _historyList = DBService.instance.getHistores();
    _followLookup = {
      for (final follow in FollowService.instance.followList)
        buildLiveRoomLookupKey(follow.siteId, follow.roomId): follow,
    };
    if (_historyList.isEmpty) {
      _visibleHistoryCount = 0;
      return;
    }
    if (_visibleHistoryCount <= 0) {
      _visibleHistoryCount = expandHistoryVisibleCount(
        totalCount: _historyList.length,
        currentCount: 0,
        pageSize: _historyPageSize,
      );
      return;
    }
    if (_visibleHistoryCount > _historyList.length) {
      _visibleHistoryCount = _historyList.length;
    }
  }

  FollowUser? _findFollowUser(History item) {
    return _followLookup[buildLiveRoomLookupKey(item.siteId, item.roomId)];
  }

  void _syncVisibleHistoryStates() {
    final visibleHistoryList = _historyList.take(_visibleHistoryCount);
    for (final item in visibleHistoryList) {
      final cachedState = HistoryLiveStatusService.instance.getCachedState(
        item,
        followUser: _findFollowUser(item),
      );
      if (cachedState != null) {
        _historyLiveStates[item.id] = cachedState;
      }
    }
  }

  Future<void> _loadHistoryStatusesIfNeeded() async {
    if (_historyStatusLoading) {
      _historyStatusReloadRequested = true;
      return;
    }
    _refreshHistoryCache();
    if (_historyList.isEmpty) {
      return;
    }

    final visibleHistoryList = _historyList.take(_visibleHistoryCount).toList();
    _syncVisibleHistoryStates();
    if (mounted) {
      setState(() {});
    }

    final pendingItems = visibleHistoryList.where((item) {
      final state = _historyLiveStates[item.id];
      return (state == null || state.liveStatus == 0) &&
          !_historyStatusRequestedIds.contains(item.id);
    }).toList();
    if (pendingItems.isEmpty) {
      return;
    }

    for (final item in pendingItems) {
      _historyStatusRequestedIds.add(item.id);
    }

    _historyStatusLoading = true;
    final loadedStates = await HistoryLiveStatusService.instance.loadStates(
      pendingItems,
    );
    _historyLiveStates.addAll(loadedStates);
    _historyStatusLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (_historyStatusReloadRequested) {
      _historyStatusReloadRequested = false;
      _scheduleHistoryStatusLoad();
    }
  }

  void _openRoom({
    required String siteId,
    required String roomId,
  }) {
    final site = Sites.allSites[siteId];
    if (site == null) {
      return;
    }
    widget.onClose();
    widget.controller.resetRoom(site, roomId);
  }

  Widget _buildFollowListView() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: FollowService.instance.loadData,
          child: ListView.builder(
            itemCount: FollowService.instance.liveList.length,
            itemBuilder: (_, i) {
              final item = FollowService.instance.liveList[i];
              return Obx(
                () => FollowUserItem(
                  item: item,
                  playing: widget.controller.rxSite.value.id == item.siteId &&
                      widget.controller.rxRoomId.value == item.roomId,
                  onTap: () {
                    _openRoom(siteId: item.siteId, roomId: item.roomId);
                  },
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Obx(
            () => DesktopRefreshButton(
              refreshing: FollowService.instance.updating.value,
              onPressed: FollowService.instance.loadData,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryListView() {
    if (_historyList.isEmpty) {
      return Center(
        child: Text(
          '暂无观看历史',
          style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _historyScrollController,
      itemCount: _visibleHistoryCount,
      itemBuilder: (_, i) {
        final item = _historyList[i];
        final state = _historyLiveStates[item.id];
        return _HistoryListItem(
          item: item,
          liveStatus: state?.liveStatus ?? 0,
          liveStartTime: state?.liveStartTime,
          playing: widget.controller.rxSite.value.id == item.siteId &&
              widget.controller.rxRoomId.value == item.roomId,
          onTap: () {
            _openRoom(siteId: item.siteId, roomId: item.roomId);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '关注列表'),
              Tab(text: '观看历史'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Obx(() => _buildFollowListView()),
              _buildHistoryListView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final History item;
  final int liveStatus;
  final String? liveStartTime;
  final bool playing;
  final VoidCallback onTap;

  const _HistoryListItem({
    required this.item,
    required this.liveStatus,
    required this.liveStartTime,
    required this.playing,
    required this.onTap,
  });

  String getStatus(int status) {
    if (status == 1) {
      return '未开播';
    }
    if (status == 2) {
      return '直播中';
    }
    return '读取中';
  }

  String formatLiveDuration(String? startTimeStampString) {
    if (startTimeStampString == null ||
        startTimeStampString.isEmpty ||
        startTimeStampString == '0') {
      return '';
    }
    try {
      final startTimeStamp = int.parse(startTimeStampString);
      final currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final durationInSeconds = currentTimeStamp - startTimeStamp;
      final hours = durationInSeconds ~/ 3600;
      final minutes = (durationInSeconds % 3600) ~/ 60;

      final hourText = hours > 0 ? '$hours小时' : '';
      final minuteText = minutes > 0 ? '$minutes分钟' : '';

      if (hours == 0 && minutes == 0) {
        return '不足1分钟';
      }
      return '$hourText$minuteText';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = Sites.allSites[item.siteId];
    if (site == null) {
      return const SizedBox.shrink();
    }

    return ListTile(
      contentPadding: AppStyle.edgeInsetsL16.copyWith(right: 4),
      leading: NetImage(
        item.face,
        width: 48,
        height: 48,
        borderRadius: 24,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (liveStatus != 0) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: liveStatus == 2 ? Colors.green : Colors.grey,
                borderRadius: AppStyle.radius12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              getStatus(liveStatus),
              style: TextStyle(
                fontSize: 12,
                color: liveStatus == 2 ? null : Colors.grey,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Image.asset(
            site.logo,
            width: 20,
          ),
          AppStyle.hGap4,
          Text(
            site.name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (playing)
            Padding(
              padding: AppStyle.edgeInsetsL8,
              child: Text(
                '正在观看',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (liveStatus == 2 && (liveStartTime?.isNotEmpty ?? false))
            Padding(
              padding: AppStyle.edgeInsetsL8,
              child: Text(
                '开播了${formatLiveDuration(liveStartTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
      trailing: playing
          ? const SizedBox(
              width: 64,
              child: Center(
                child: Icon(Icons.play_arrow),
              ),
            )
          : Text(
              Utils.parseTime(item.updateTime),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
      onTap: onTap,
    );
  }
}

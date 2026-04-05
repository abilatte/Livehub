import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/modules/live_room/live_room_sidebar_tab_utils.dart';

String buildLiveRoomRecordId(String siteId, String roomId) {
  return '${siteId}_$roomId';
}

String buildLiveRoomFollowLookupKey(String siteId, String roomId) {
  return buildLiveRoomRecordId(siteId, roomId);
}

class LiveRoomSwitchPlan {
  final bool shouldReset;
  final LiveRoomSidebarTab nextSidebarTab;
  final String nextFollowLookupKey;

  const LiveRoomSwitchPlan({
    required this.shouldReset,
    required this.nextSidebarTab,
    required this.nextFollowLookupKey,
  });
}

LiveRoomSwitchPlan resolveLiveRoomSwitchPlan({
  required String currentSiteId,
  required String currentRoomId,
  required String nextSiteId,
  required String nextRoomId,
  required LiveRoomSidebarTab currentSidebarTab,
}) {
  return LiveRoomSwitchPlan(
    shouldReset: currentSiteId != nextSiteId || currentRoomId != nextRoomId,
    nextSidebarTab: resolveLiveRoomSidebarTabForSite(
      currentSidebarTab,
      hasSuperChatTab: nextSiteId == Constant.kBiliBili,
    ),
    nextFollowLookupKey: buildLiveRoomRecordId(nextSiteId, nextRoomId),
  );
}

import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/modules/multi_room/multi_room_utils.dart';

class MultiRoomItem {
  final Site site;
  final String roomId;
  final String userName;
  final String face;

  const MultiRoomItem({
    required this.site,
    required this.roomId,
    required this.userName,
    required this.face,
  });

  factory MultiRoomItem.fromFollow(FollowUser item) {
    return MultiRoomItem(
      site: Sites.allSites[item.siteId]!,
      roomId: item.roomId,
      userName: item.userName,
      face: item.face,
    );
  }

  String get key => MultiRoomUtils.roomKey(siteId: site.id, roomId: roomId);
}

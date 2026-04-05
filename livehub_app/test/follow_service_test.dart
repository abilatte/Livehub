import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/services/follow_service.dart';
import 'package:livehub_core/livehub_core.dart';

class _FakeBiliBiliFollowSite extends BiliBiliSite {
  int followSnapshotCalls = 0;
  int roomDetailCalls = 0;

  @override
  Future<LiveRoomDetail> getFollowRoomSnapshot({required String roomId}) async {
    followSnapshotCalls++;
    return LiveRoomDetail(
      roomId: roomId,
      title: '轻量快照',
      cover: '',
      userName: '测试主播',
      userAvatar: 'https://example.com/avatar.png',
      online: 123,
      status: true,
      url: 'https://live.bilibili.com/$roomId',
      showTime: '1774096800',
    );
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    roomDetailCalls++;
    return LiveRoomDetail(
      roomId: roomId,
      title: '完整详情',
      cover: '',
      userName: '测试主播',
      userAvatar: 'https://example.com/avatar.png',
      online: 123,
      status: true,
      url: 'https://live.bilibili.com/$roomId',
      showTime: '1774096800',
    );
  }
}

class _FakeLiveSite extends LiveSite {
  int roomDetailCalls = 0;

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    roomDetailCalls++;
    return LiveRoomDetail(
      roomId: roomId,
      title: '完整详情',
      cover: '',
      userName: '其他平台主播',
      userAvatar: 'https://example.com/avatar.png',
      online: 321,
      status: false,
      url: 'https://example.com/$roomId',
    );
  }
}

void main() {
  group('关注头像与昵称刷新', () {
    test('房间详情会同步最新头像昵称和直播状态', () {
      final follow = FollowUser(
        id: 'bilibili_13308358',
        roomId: '13308358',
        siteId: 'bilibili',
        userName: '旧昵称',
        face: 'https://old.example/avatar.png',
        addTime: DateTime(2026, 3, 21, 18, 0, 0),
      );

      final detail = LiveRoomDetail(
        roomId: '13308358',
        title: '直播标题',
        cover: 'https://example.com/cover.png',
        userName: '新昵称',
        userAvatar: 'https://new.example/avatar.png',
        online: 1234,
        status: true,
        url: 'https://example.com/room/13308358',
        showTime: '1774096800',
      );

      final changed = syncFollowSnapshotFromDetail(follow, detail);

      expect(changed, isTrue);
      expect(follow.userName, '新昵称');
      expect(follow.face, 'https://new.example/avatar.png');
      expect(follow.liveStatus.value, 2);
      expect(follow.liveStartTime, '1774096800');
    });

    test('详情缺少头像昵称时不覆盖本地值但会更新未开播状态', () {
      final follow = FollowUser(
        id: 'douyu_999',
        roomId: '999',
        siteId: 'douyu',
        userName: '保留昵称',
        face: 'https://keep.example/avatar.png',
        addTime: DateTime(2026, 3, 21, 18, 30, 0),
      );

      final detail = LiveRoomDetail(
        roomId: '999',
        title: '直播标题',
        cover: 'https://example.com/cover.png',
        userName: '',
        userAvatar: '',
        online: 0,
        status: false,
        url: 'https://example.com/room/999',
        showTime: '1774096800',
      );

      final changed = syncFollowSnapshotFromDetail(follow, detail);

      expect(changed, isFalse);
      expect(follow.userName, '保留昵称');
      expect(follow.face, 'https://keep.example/avatar.png');
      expect(follow.liveStatus.value, 1);
      expect(follow.liveStartTime, isNull);
    });

    test('B站关注刷新优先走轻量快照避免完整房间详情', () async {
      final site = _FakeBiliBiliFollowSite();

      await loadFollowSnapshotForSite(
        liveSite: site,
        roomId: '22637261',
      );

      expect(site.followSnapshotCalls, 1);
      expect(site.roomDetailCalls, 0);
    });

    test('非B站关注刷新仍走原有房间详情链路', () async {
      final site = _FakeLiveSite();

      await loadFollowSnapshotForSite(
        liveSite: site,
        roomId: '999',
      );

      expect(site.roomDetailCalls, 1);
    });
  });
}

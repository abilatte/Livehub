import 'dart:async';
import 'dart:collection';

import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/models/db/history.dart';

const Duration _historyStatusCacheTtl = Duration(minutes: 5);

class HistoryLiveState {
  final int liveStatus;
  final String? liveStartTime;

  const HistoryLiveState({
    required this.liveStatus,
    this.liveStartTime,
  });
}

class _HistoryLiveCacheEntry {
  final HistoryLiveState state;
  final DateTime updatedAt;

  const _HistoryLiveCacheEntry({
    required this.state,
    required this.updatedAt,
  });

  bool get isFresh =>
      DateTime.now().difference(updatedAt) < _historyStatusCacheTtl;
}

class HistoryLiveStatusService {
  HistoryLiveStatusService._();

  static final HistoryLiveStatusService instance = HistoryLiveStatusService._();

  final Map<String, _HistoryLiveCacheEntry> _cache =
      <String, _HistoryLiveCacheEntry>{};

  HistoryLiveState? getCachedState(
    History item, {
    FollowUser? followUser,
  }) {
    if (followUser != null && followUser.liveStatus.value != 0) {
      final state = HistoryLiveState(
        liveStatus: followUser.liveStatus.value,
        liveStartTime: followUser.liveStartTime,
      );
      _cache[item.id] = _HistoryLiveCacheEntry(
        state: state,
        updatedAt: DateTime.now(),
      );
      return state;
    }

    final cache = _cache[item.id];
    if (cache != null && cache.isFresh) {
      return cache.state;
    }
    return null;
  }

  Future<Map<String, HistoryLiveState>> loadStates(
    Iterable<History> items, {
    int concurrency = 3,
  }) async {
    final queue = Queue<History>.from(items);
    final nextStates = <String, HistoryLiveState>{};

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final item = queue.removeFirst();
        final site = Sites.allSites[item.siteId];
        if (site == null) {
          continue;
        }

        try {
          final isLiving =
              await site.liveSite.getLiveStatus(roomId: item.roomId);
          String? liveStartTime;
          final liveStatus = isLiving ? 2 : 1;
          if (isLiving) {
            final detail =
                await site.liveSite.getRoomDetail(roomId: item.roomId);
            liveStartTime = detail.showTime;
          }
          final state = HistoryLiveState(
            liveStatus: liveStatus,
            liveStartTime: liveStartTime,
          );
          nextStates[item.id] = state;
          _cache[item.id] = _HistoryLiveCacheEntry(
            state: state,
            updatedAt: DateTime.now(),
          );
        } catch (_) {
          const state = HistoryLiveState(liveStatus: 0);
          nextStates[item.id] = state;
          _cache[item.id] = _HistoryLiveCacheEntry(
            state: state,
            updatedAt: DateTime.now(),
          );
        }
      }
    }

    final workerCount = queue.length < concurrency ? queue.length : concurrency;
    if (workerCount <= 0) {
      return nextStates;
    }
    await Future.wait(List.generate(workerCount, (_) => worker()));
    return nextStates;
  }
}

enum FollowHistoryTab {
  follow,
  history,
}

int followHistoryTabToIndex(FollowHistoryTab tab) {
  return tab == FollowHistoryTab.follow ? 0 : 1;
}

FollowHistoryTab followHistoryTabFromIndex(int index) {
  return index == 1 ? FollowHistoryTab.history : FollowHistoryTab.follow;
}

bool isFollowTabIndex(int index) {
  return followHistoryTabFromIndex(index) == FollowHistoryTab.follow;
}

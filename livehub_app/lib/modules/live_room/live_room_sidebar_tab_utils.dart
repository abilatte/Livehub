enum LiveRoomSidebarTab {
  chat,
  superChat,
  follow,
  settings,
}

int liveRoomSidebarTabCount({required bool hasSuperChatTab}) {
  return hasSuperChatTab ? 4 : 3;
}

int liveRoomSidebarTabToIndex(
  LiveRoomSidebarTab tab, {
  required bool hasSuperChatTab,
}) {
  switch (tab) {
    case LiveRoomSidebarTab.chat:
      return 0;
    case LiveRoomSidebarTab.superChat:
      return hasSuperChatTab ? 1 : 0;
    case LiveRoomSidebarTab.follow:
      return hasSuperChatTab ? 2 : 1;
    case LiveRoomSidebarTab.settings:
      return hasSuperChatTab ? 3 : 2;
  }
}

LiveRoomSidebarTab liveRoomSidebarTabFromIndex(
  int index, {
  required bool hasSuperChatTab,
}) {
  if (hasSuperChatTab) {
    switch (index) {
      case 1:
        return LiveRoomSidebarTab.superChat;
      case 2:
        return LiveRoomSidebarTab.follow;
      case 3:
        return LiveRoomSidebarTab.settings;
      default:
        return LiveRoomSidebarTab.chat;
    }
  }
  switch (index) {
    case 1:
      return LiveRoomSidebarTab.follow;
    case 2:
      return LiveRoomSidebarTab.settings;
    default:
      return LiveRoomSidebarTab.chat;
  }
}

LiveRoomSidebarTab resolveLiveRoomSidebarTabForSite(
  LiveRoomSidebarTab tab, {
  required bool hasSuperChatTab,
}) {
  if (!hasSuperChatTab && tab == LiveRoomSidebarTab.superChat) {
    return LiveRoomSidebarTab.chat;
  }
  return tab;
}

import 'package:flutter/material.dart';

/// 聊天消息右键/点击菜单动作。
enum ChatMessageMenuAction {
  /// 按当前直播平台屏蔽/取消屏蔽用户名（持久化）。
  togglePlatformShield,

  /// 当前直播间会话内临时禁言/取消。
  toggleTempMute,

  /// 复制用户名。
  copyUserName,

  /// 复制弹幕正文。
  copyMessage,

  /// 复制「用户名：弹幕」。
  copyFull,

  /// 将弹幕正文加入关键词屏蔽。
  addKeywordShield,

  /// 清空本房间全部临时禁言。
  clearTempMutes,
}

class ChatMessageMenuItemSpec {
  final ChatMessageMenuAction action;
  final String label;
  final String? subtitle;
  final bool enabled;

  const ChatMessageMenuItemSpec({
    required this.action,
    required this.label,
    this.subtitle,
    this.enabled = true,
  });
}

class PlatformUserShieldEntry {
  final String siteId;
  final String userName;

  const PlatformUserShieldEntry({
    required this.siteId,
    required this.userName,
  });
}

const String kChatSystemUserName = "LiveSysMessage";
const String kUserShieldStoragePrefix = "user:";

AnimationStyle? resolveChatMessageMenuAnimationStyle({
  required bool isDesktopPlatform,
}) {
  if (!isDesktopPlatform) {
    return null;
  }
  return AnimationStyle.noAnimation;
}

bool isChatSystemMessage(String? userName) {
  return normalizeChatUserName(userName) == kChatSystemUserName;
}

String normalizeChatUserName(String? userName) {
  return userName?.trim() ?? "";
}

String normalizeChatMessageText(String? message) {
  return message?.trim() ?? "";
}

/// 平台用户屏蔽在 Hive 中的存储键：`user:{siteId}:{userName}`。
String buildUserShieldStorageKey({
  required String siteId,
  required String userName,
}) {
  final safeSiteId = siteId.trim();
  final safeUserName = normalizeChatUserName(userName);
  return "$kUserShieldStoragePrefix$safeSiteId:$safeUserName";
}

bool isUserShieldStorageKey(String value) {
  return value.trim().startsWith(kUserShieldStoragePrefix);
}

PlatformUserShieldEntry? parseUserShieldStorageKey(String rawValue) {
  final value = rawValue.trim();
  if (!value.startsWith(kUserShieldStoragePrefix)) {
    return null;
  }
  final body = value.substring(kUserShieldStoragePrefix.length).trim();
  if (body.isEmpty) {
    return null;
  }
  final separatorIndex = body.indexOf(":");
  if (separatorIndex <= 0 || separatorIndex >= body.length - 1) {
    return null;
  }
  final siteId = body.substring(0, separatorIndex).trim();
  final userName = body.substring(separatorIndex + 1).trim();
  if (siteId.isEmpty || userName.isEmpty) {
    return null;
  }
  return PlatformUserShieldEntry(siteId: siteId, userName: userName);
}

/// 从混合存储值中拆出关键词屏蔽列表。
List<String> extractKeywordShieldValues(Iterable<dynamic> values) {
  final words = <String>[];
  final seen = <String>{};
  for (final item in values) {
    final value = item.toString().trim();
    if (value.isEmpty || isUserShieldStorageKey(value)) {
      continue;
    }
    if (seen.add(value)) {
      words.add(value);
    }
  }
  return words;
}

/// 从混合存储值中拆出平台用户屏蔽：siteId -> 用户名列表。
Map<String, List<String>> extractUserShieldGroups(Iterable<dynamic> values) {
  final groups = <String, Set<String>>{};
  for (final item in values) {
    final parsed = parseUserShieldStorageKey(item.toString());
    if (parsed == null) {
      continue;
    }
    groups.putIfAbsent(parsed.siteId, () => <String>{}).add(parsed.userName);
  }
  return {
    for (final entry in groups.entries)
      entry.key: (entry.value.toList()..sort()),
  };
}

bool isUserShieldedInGroups({
  required Map<String, List<String>> groups,
  required String siteId,
  required String userName,
}) {
  final safeUserName = normalizeChatUserName(userName);
  if (safeUserName.isEmpty) {
    return false;
  }
  final list = groups[siteId.trim()] ?? const <String>[];
  return list.contains(safeUserName);
}

/// 构建弹幕点击菜单项（顺序固定，便于桌面右键/左键共用）。
List<ChatMessageMenuItemSpec> buildChatMessageMenuItems({
  required bool isSystemMessage,
  required bool isPlatformShielded,
  required bool isTempMuted,
  required String siteName,
  required bool hasTempMutes,
  required bool hasMessageContent,
}) {
  if (isSystemMessage) {
    return const [
      ChatMessageMenuItemSpec(
        action: ChatMessageMenuAction.copyMessage,
        label: "复制消息内容",
      ),
    ];
  }

  final items = <ChatMessageMenuItemSpec>[
    ChatMessageMenuItemSpec(
      action: ChatMessageMenuAction.togglePlatformShield,
      label: isPlatformShielded ? "取消平台屏蔽" : "屏蔽当前平台",
      subtitle: isPlatformShielded
          ? "恢复显示该用户在 $siteName 的弹幕"
          : "仅对 $siteName 生效，不影响其他平台同名用户",
    ),
    ChatMessageMenuItemSpec(
      action: ChatMessageMenuAction.toggleTempMute,
      label: isTempMuted ? "取消临时禁言" : "加入临时禁言",
      subtitle: "只在当前直播间本次会话内有效",
    ),
    const ChatMessageMenuItemSpec(
      action: ChatMessageMenuAction.copyUserName,
      label: "复制用户名",
    ),
  ];

  if (hasMessageContent) {
    items.add(
      const ChatMessageMenuItemSpec(
        action: ChatMessageMenuAction.copyMessage,
        label: "复制弹幕内容",
      ),
    );
    items.add(
      const ChatMessageMenuItemSpec(
        action: ChatMessageMenuAction.copyFull,
        label: "复制整条消息",
      ),
    );
    items.add(
      const ChatMessageMenuItemSpec(
        action: ChatMessageMenuAction.addKeywordShield,
        label: "添加为关键词屏蔽",
        subtitle: "将该弹幕全文加入关键词列表",
      ),
    );
  }

  items.add(
    ChatMessageMenuItemSpec(
      action: ChatMessageMenuAction.clearTempMutes,
      label: "批量恢复临时禁言",
      subtitle: hasTempMutes ? null : "当前没有临时禁言用户",
      enabled: hasTempMutes,
    ),
  );

  return items;
}

String buildFullChatCopyText({
  required String userName,
  required String message,
}) {
  final safeUserName = normalizeChatUserName(userName);
  final safeMessage = normalizeChatMessageText(message);
  if (isChatSystemMessage(safeUserName) || safeUserName.isEmpty) {
    return safeMessage;
  }
  if (safeMessage.isEmpty) {
    return safeUserName;
  }
  return "$safeUserName：$safeMessage";
}

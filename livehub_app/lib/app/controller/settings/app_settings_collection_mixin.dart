import 'package:get/get.dart';
import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/app/controller/settings/app_settings_utils.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/models/danmu_shield_preset.dart';
import 'package:livehub_app/modules/live_room/chat_message_menu_utils.dart';
import 'package:livehub_app/modules/settings/danmu_shield/danmu_shield_preset_utils.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsCollectionMixin on GetxController {
  /// 关键词屏蔽（不含平台用户屏蔽）。
  final shieldList = <String>{}.obs;

  /// 平台用户屏蔽：siteId -> 用户名列表。
  final userShieldGroups = <String, List<String>>{}.obs;

  /// 命名屏蔽词预设。
  final shieldPresets = <DanmuShieldPreset>[].obs;

  /// 当前选中的预设名（空表示未选预设）。
  final activeShieldPresetName = "".obs;

  final siteSort = RxList<String>();
  final homeSort = RxList<String>();

  void initCollectionSettings() {
    final storedValues = LocalStorageService.instance.shieldBox.values;
    // ignore: invalid_use_of_protected_member
    shieldList.value = extractKeywordShieldValues(storedValues).toSet();
    userShieldGroups
      ..clear()
      ..addAll(extractUserShieldGroups(storedValues));
    final presetRaw = LocalStorageService.instance.getValue(
      LocalStorageService.kDanmuShieldPresets,
      "[]",
    );
    shieldPresets
      ..clear()
      ..addAll(DanmuShieldPresetUtils.decodePresets(presetRaw));
    activeShieldPresetName.value = LocalStorageService.instance.getValue(
      LocalStorageService.kDanmuShieldActivePreset,
      "",
    );
    initSiteSort();
    initHomeSort();
  }

  void initSiteSort() {
    final stored = LocalStorageService.instance
        .getValue(
          LocalStorageService.kSiteSort,
          Sites.allSites.keys.join(","),
        )
        .split(",");
    siteSort.value = normalizeOrderedKeys(
      storedKeys: stored,
      validKeys: Sites.allSites.keys,
    );
  }

  void initHomeSort() {
    final stored = LocalStorageService.instance
        .getValue(
          LocalStorageService.kHomeSort,
          Constant.allHomePages.keys.join(","),
        )
        .split(",");
    homeSort.value = normalizeOrderedKeys(
      storedKeys: stored,
      validKeys: Constant.allHomePages.keys,
    );
  }

  void addShieldList(String value) {
    final word = value.trim();
    if (word.isEmpty || isUserShieldStorageKey(word)) {
      return;
    }
    shieldList.add(word);
    LocalStorageService.instance.shieldBox.put(word, word);
  }

  void removeShieldList(String value) {
    shieldList.remove(value);
    LocalStorageService.instance.shieldBox.delete(value);
  }

  Future<void> clearShieldList() async {
    final keywords = shieldList.toList();
    shieldList.clear();
    for (final word in keywords) {
      await LocalStorageService.instance.shieldBox.delete(word);
    }
  }

  Future<void> replaceShieldList(Iterable<String> values) async {
    final words = normalizeShieldWords(values)
        .where((word) => !isUserShieldStorageKey(word))
        .toList();

    final previous = shieldList.toList();
    for (final word in previous) {
      await LocalStorageService.instance.shieldBox.delete(word);
    }

    shieldList
      ..clear()
      ..addAll(words);

    if (words.isNotEmpty) {
      await LocalStorageService.instance.shieldBox.putAll({
        for (final word in words) word: word,
      });
    }
  }

  bool isUserShielded(String userName, {required String siteId}) {
    return isUserShieldedInGroups(
      groups: userShieldGroups,
      siteId: siteId,
      userName: userName,
    );
  }

  List<String> getUserShieldList({required String siteId}) {
    final list = userShieldGroups[siteId.trim()] ?? const <String>[];
    return List<String>.from(list);
  }

  /// 全部平台屏蔽用户条目，用于设置页展示。
  List<PlatformUserShieldEntry> get allUserShieldEntries {
    final entries = <PlatformUserShieldEntry>[];
    for (final entry in userShieldGroups.entries) {
      for (final userName in entry.value) {
        entries.add(
          PlatformUserShieldEntry(
            siteId: entry.key,
            userName: userName,
          ),
        );
      }
    }
    entries.sort((a, b) {
      final siteCompare = a.siteId.compareTo(b.siteId);
      if (siteCompare != 0) {
        return siteCompare;
      }
      return a.userName.compareTo(b.userName);
    });
    return entries;
  }

  void addUserShield(String userName, {required String siteId}) {
    final safeUserName = normalizeChatUserName(userName);
    final safeSiteId = siteId.trim();
    if (safeUserName.isEmpty || safeSiteId.isEmpty) {
      return;
    }
    final current = List<String>.from(
      userShieldGroups[safeSiteId] ?? const <String>[],
    );
    if (current.contains(safeUserName)) {
      return;
    }
    current.add(safeUserName);
    current.sort();
    userShieldGroups[safeSiteId] = current;
    userShieldGroups.refresh();
    final key = buildUserShieldStorageKey(
      siteId: safeSiteId,
      userName: safeUserName,
    );
    LocalStorageService.instance.shieldBox.put(key, key);
  }

  void removeUserShield(String userName, {required String siteId}) {
    final safeUserName = normalizeChatUserName(userName);
    final safeSiteId = siteId.trim();
    if (safeUserName.isEmpty || safeSiteId.isEmpty) {
      return;
    }
    final current = List<String>.from(
      userShieldGroups[safeSiteId] ?? const <String>[],
    );
    if (!current.remove(safeUserName)) {
      return;
    }
    if (current.isEmpty) {
      userShieldGroups.remove(safeSiteId);
    } else {
      userShieldGroups[safeSiteId] = current;
    }
    userShieldGroups.refresh();
    final key = buildUserShieldStorageKey(
      siteId: safeSiteId,
      userName: safeUserName,
    );
    LocalStorageService.instance.shieldBox.delete(key);
  }

  bool toggleUserShield(String userName, {required String siteId}) {
    if (isUserShielded(userName, siteId: siteId)) {
      removeUserShield(userName, siteId: siteId);
      return false;
    }
    addUserShield(userName, siteId: siteId);
    return true;
  }

  void _persistShieldPresets() {
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuShieldPresets,
      DanmuShieldPresetUtils.encodePresets(shieldPresets.toList()),
    );
  }

  /// Save current keyword list as a named preset (upsert by name).
  Future<void> saveCurrentKeywordsAsPreset(String name) async {
    final preset = DanmuShieldPresetUtils.snapshotFromKeywords(
      name: name,
      keywords: shieldList,
    );
    if (preset.name.isEmpty) {
      return;
    }
    shieldPresets
      ..assignAll(DanmuShieldPresetUtils.upsertPreset(shieldPresets, preset));
    _persistShieldPresets();
  }

  /// Apply preset keywords as the active shield set used by chat filtering.
  Future<void> applyShieldPreset(String name) async {
    DanmuShieldPreset? preset;
    for (final item in shieldPresets) {
      if (item.name == name) {
        preset = item;
        break;
      }
    }
    if (preset == null) {
      return;
    }
    final keywords = DanmuShieldPresetUtils.applyPresetKeywords(preset);
    await replaceShieldList(keywords);
    activeShieldPresetName.value = name;
    LocalStorageService.instance.setValue(
      LocalStorageService.kDanmuShieldActivePreset,
      name,
    );
  }

  Future<void> removeShieldPreset(String name) async {
    shieldPresets
      ..assignAll(DanmuShieldPresetUtils.removePresetByName(shieldPresets, name));
    _persistShieldPresets();
    if (activeShieldPresetName.value == name) {
      activeShieldPresetName.value = "";
      LocalStorageService.instance.setValue(
        LocalStorageService.kDanmuShieldActivePreset,
        "",
      );
    }
  }

  void setSiteSort(List<String> values) {
    siteSort.value = normalizeOrderedKeys(
      storedKeys: values,
      validKeys: Sites.allSites.keys,
    );
    LocalStorageService.instance.setValue(
      LocalStorageService.kSiteSort,
      siteSort.join(","),
    );
  }

  void setHomeSort(List<String> values) {
    homeSort.value = normalizeOrderedKeys(
      storedKeys: values,
      validKeys: Constant.allHomePages.keys,
    );
    LocalStorageService.instance.setValue(
      LocalStorageService.kHomeSort,
      homeSort.join(","),
    );
  }
}

import 'package:get/get.dart';
import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/app/controller/settings/app_settings_utils.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/services/local_storage_service.dart';

mixin AppSettingsCollectionMixin on GetxController {
  final shieldList = <String>{}.obs;
  final siteSort = RxList<String>();
  final homeSort = RxList<String>();

  void initCollectionSettings() {
    // ignore: invalid_use_of_protected_member
    shieldList.value = normalizeShieldWords(
      LocalStorageService.instance.shieldBox.values,
    ).toSet();
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
    shieldList.add(value);
    LocalStorageService.instance.shieldBox.put(value, value);
  }

  void removeShieldList(String value) {
    shieldList.remove(value);
    LocalStorageService.instance.shieldBox.delete(value);
  }

  Future<void> clearShieldList() async {
    shieldList.clear();
    await LocalStorageService.instance.shieldBox.clear();
  }

  Future<void> replaceShieldList(Iterable<String> values) async {
    final words = normalizeShieldWords(values);

    shieldList.clear();
    shieldList.addAll(words);

    await LocalStorageService.instance.shieldBox.clear();
    if (words.isNotEmpty) {
      await LocalStorageService.instance.shieldBox.putAll({
        for (final word in words) word: word,
      });
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

import 'package:get/get.dart';
import 'package:livehub_app/app/constant.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_app/services/local_storage_service.dart';
import 'package:livehub_core/livehub_core.dart';

class DouyinAccountService extends GetxService {
  static DouyinAccountService get instance =>
      Get.find<DouyinAccountService>();

  var cookie = "";
  var hasCookie = false.obs;

  @override
  void onInit() {
    cookie = LocalStorageService.instance
        .getValue(LocalStorageService.kDouyinCookie, "");
    hasCookie.value = cookie.isNotEmpty;
    setSite();
    super.onInit();
  }

  void setSite() {
    var site = (Sites.allSites[Constant.kDouyin]!.liveSite as DouyinSite);
    if (cookie.isEmpty) {
      site.cookie = "";
    } else {
      site.setCookieFromInput(cookie);
    }
  }

  void setCookie(String cookie) {
    final normalized = cookie.trim().isEmpty
        ? ""
        : DouyinCookieHelper.normalizeInput(cookie);
    this.cookie = normalized;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDouyinCookie, normalized);
    hasCookie.value = normalized.isNotEmpty;
    setSite();
  }

  void clearCookie() {
    cookie = "";
    LocalStorageService.instance
        .setValue(LocalStorageService.kDouyinCookie, "");
    hasCookie.value = false;
    setSite();
  }
}

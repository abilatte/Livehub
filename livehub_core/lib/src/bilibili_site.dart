import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:livehub_core/src/common/convert_helper.dart';
import 'package:livehub_core/src/common/core_log.dart';
import 'package:livehub_core/src/common/core_error.dart';
import 'package:livehub_core/src/common/http_client.dart';
import 'package:livehub_core/src/danmaku/bilibili_danmaku.dart';
import 'package:livehub_core/src/interface/live_danmaku.dart';
import 'package:livehub_core/src/interface/live_site.dart';
import 'package:livehub_core/src/model/live_anchor_item.dart';
import 'package:livehub_core/src/model/live_category.dart';
import 'package:livehub_core/src/model/live_message.dart';
import 'package:livehub_core/src/model/live_play_url.dart';
import 'package:livehub_core/src/model/live_room_item.dart';
import 'package:livehub_core/src/model/live_search_result.dart';
import 'package:livehub_core/src/model/live_room_detail.dart';
import 'package:livehub_core/src/model/live_play_quality.dart';
import 'package:livehub_core/src/model/live_category_result.dart';
import 'package:livehub_core/src/model/live_contribution_rank.dart';

String normalizeBilibiliImageUrl(String url) {
  if (url.isEmpty) {
    return "";
  }
  if (url.startsWith("//")) {
    return "https:$url";
  }
  return url;
}

String buildBilibiliAvatarUrl(String url) {
  final normalizedUrl = normalizeBilibiliImageUrl(url);
  if (normalizedUrl.isEmpty) {
    return "";
  }
  if (normalizedUrl.contains("@")) {
    return normalizedUrl;
  }
  return "$normalizedUrl@400w.jpg";
}

String resolveBilibiliAnchorAvatar({
  required Map<String, dynamic> roomInfo,
  required Map<String, dynamic> roomBaseInfo,
  required Map<String, dynamic> accountInfo,
}) {
  return buildBilibiliAvatarUrl(
    asT<String?>(accountInfo["face"]) ??
        roomInfo["anchor_info"]?["base_info"]?["face"]?.toString() ??
        asT<String?>(roomBaseInfo["face"]) ??
        "",
  );
}

String resolveBilibiliAnchorName({
  required Map<String, dynamic> roomInfo,
  required Map<String, dynamic> accountInfo,
}) {
  return asT<String?>(accountInfo["name"]) ??
      roomInfo["anchor_info"]?["base_info"]?["uname"]?.toString() ??
      "";
}

String? normalizeBilibiliLiveStartTime(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == "0") {
    return null;
  }
  return text;
}

Map<String, dynamic> normalizeBilibiliDataMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

bool shouldRetryBilibiliRoomDetailRequest(Object error) {
  return error is CoreError && error.statusCode == 412;
}

const int _bilibiliDanmuInfoMaxAttempts = 3;
const Duration _bilibiliDanmuInfoRetryDelay = Duration(milliseconds: 350);

List<String> extractBilibiliDanmuHosts(Map<String, dynamic> danmuInfo) {
  final rawHosts = danmuInfo["host_list"];
  if (rawHosts is! List) {
    return const <String>[];
  }
  return rawHosts
      .map((item) => item is Map ? item["host"]?.toString() ?? "" : "")
      .where((host) => host.isNotEmpty)
      .toList();
}

bool hasValidBilibiliDanmuInfo(Map<String, dynamic> danmuInfo) {
  final token = danmuInfo["token"]?.toString() ?? "";
  final serverHosts = extractBilibiliDanmuHosts(danmuInfo);
  return token.isNotEmpty && serverHosts.isNotEmpty;
}

bool isSemanticEmptyBilibiliDanmuInfo(Map<String, dynamic> danmuInfo) {
  final token = danmuInfo["token"]?.toString() ?? "";
  final serverHosts = extractBilibiliDanmuHosts(danmuInfo);
  return token.isEmpty && serverHosts.isEmpty;
}

dynamic buildBilibiliDanmakuPayload({
  required String roomId,
  required int uid,
  required String buvid,
  required String cookie,
  required Map<String, dynamic> danmuInfo,
  required int retryCount,
}) {
  final token = danmuInfo["token"]?.toString() ?? "";
  final serverHosts = extractBilibiliDanmuHosts(danmuInfo);
  if (token.isEmpty || serverHosts.isEmpty) {
    return BiliBiliDanmakuUnavailable(
      roomId: int.tryParse(roomId) ?? 0,
      reason: "弹幕参数读取失败，本次仅播放视频",
      retryCount: retryCount,
    );
  }
  return BiliBiliDanmakuArgs(
    roomId: int.tryParse(roomId) ?? 0,
    uid: uid,
    token: token,
    serverHost: serverHosts.first,
    buvid: buvid,
    cookie: cookie,
  );
}

String? resolveBilibiliWatchedText(Map<String, dynamic> roomInfo) {
  final watchedShow = normalizeBilibiliDataMap(
    normalizeBilibiliDataMap(roomInfo["room_info"])["watched_show"],
  );
  final textLarge = watchedShow["text_large"]?.toString() ?? "";
  if (textLarge.isNotEmpty) {
    return textLarge;
  }
  final textSmall = watchedShow["text_small"]?.toString() ?? "";
  if (textSmall.isNotEmpty) {
    return textSmall;
  }
  return null;
}

Map<String, dynamic> buildBilibiliRoomInfoFallback({
  required Map<String, dynamic> roomBaseInfo,
  required String fallbackRoomId,
}) {
  final roomId =
      asT<int?>(roomBaseInfo["room_id"]) ?? int.tryParse(fallbackRoomId) ?? 0;
  final uid = asT<int?>(roomBaseInfo["uid"]) ?? 0;
  return <String, dynamic>{
    "room_info": <String, dynamic>{
      "room_id": roomId,
      "title": roomBaseInfo["title"]?.toString() ?? "",
      "cover": normalizeBilibiliImageUrl(
        roomBaseInfo["user_cover"]?.toString() ??
            roomBaseInfo["cover"]?.toString() ??
            roomBaseInfo["keyframe"]?.toString() ??
            "",
      ),
      "description": roomBaseInfo["description"]?.toString() ?? "",
      "online": asT<int?>(roomBaseInfo["online"]) ?? 0,
      "live_status": asT<int?>(roomBaseInfo["live_status"]) ?? 0,
      "live_start_time": asT<int?>(roomBaseInfo["live_start_time"]) ?? 0,
    },
    "anchor_info": <String, dynamic>{
      "base_info": <String, dynamic>{
        "uid": uid,
        "uname": roomBaseInfo["uname"]?.toString() ?? "",
        "face": normalizeBilibiliImageUrl(
          roomBaseInfo["face"]?.toString() ?? "",
        ),
      },
    },
    "guard_info": roomBaseInfo["guard_info"] is Map
        ? Map<String, dynamic>.from(roomBaseInfo["guard_info"])
        : <String, dynamic>{},
  };
}

Map<String, dynamic> ensureBilibiliRoomInfo({
  required Map<String, dynamic> roomInfo,
  required Map<String, dynamic> roomBaseInfo,
  required String fallbackRoomId,
}) {
  final safeRoomInfo = normalizeBilibiliDataMap(roomInfo);
  final roomSection = normalizeBilibiliDataMap(safeRoomInfo["room_info"]);
  if (roomSection.isEmpty) {
    return buildBilibiliRoomInfoFallback(
      roomBaseInfo: roomBaseInfo,
      fallbackRoomId: fallbackRoomId,
    );
  }
  if (safeRoomInfo["anchor_info"] is! Map) {
    safeRoomInfo["anchor_info"] = <String, dynamic>{
      "base_info": <String, dynamic>{
        "uid": asT<int?>(roomBaseInfo["uid"]) ?? 0,
        "uname": roomBaseInfo["uname"]?.toString() ?? "",
        "face": normalizeBilibiliImageUrl(
          roomBaseInfo["face"]?.toString() ?? "",
        ),
      },
    };
  }
  return safeRoomInfo;
}

Map<String, dynamic> ensureBilibiliDanmuInfo(dynamic value) {
  final safeData = normalizeBilibiliDataMap(value);
  return <String, dynamic>{
    "token": safeData["token"]?.toString() ?? "",
    "host_list": safeData["host_list"] is List
        ? List<Map<String, dynamic>>.from(
            (safeData["host_list"] as List).map<Map<String, dynamic>>(
              (e) => normalizeBilibiliDataMap(e),
            ),
          )
        : <Map<String, dynamic>>[],
  };
}

class BiliBiliSite implements LiveSite {
  @override
  String id = "bilibili";

  @override
  String name = "哔哩哔哩直播";

  String cookie = "";
  int userId = 0;

  @override
  LiveDanmaku getDanmaku() => BiliBiliDanmaku();

  static const String kDefaultUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0";
  static const String kDefaultReferer = "https://live.bilibili.com/";

  String buvid3 = "";
  String buvid4 = "";
  String accessId = "";
  Future<Map<String, String>> getHeader() async {
    if (buvid3.isEmpty) {
      var buvidInfo = await getBuvid();
      buvid3 = buvidInfo["b_3"] ?? "";
      buvid4 = buvidInfo["b_4"] ?? "";
    }
    return cookie.isEmpty
        ? {
            "user-agent": kDefaultUserAgent,
            "referer": kDefaultReferer,
            "cookie": 'buvid3=$buvid3;buvid4=$buvid4;',
          }
        : {
            "cookie": cookie.contains("buvid3")
                ? cookie
                : "$cookie;buvid3=$buvid3;buvid4=$buvid4;",
            "user-agent": kDefaultUserAgent,
            "referer": kDefaultReferer,
          };
  }

  Future<Map<String, String>> getPublicHeader() async {
    if (buvid3.isEmpty) {
      var buvidInfo = await getBuvid();
      buvid3 = buvidInfo["b_3"] ?? "";
      buvid4 = buvidInfo["b_4"] ?? "";
    }
    return {
      "user-agent": kDefaultUserAgent,
      "referer": kDefaultReferer,
      "cookie": 'buvid3=$buvid3;buvid4=$buvid4;',
    };
  }

  @override
  Future<List<LiveCategory>> getCategores() async {
    List<LiveCategory> categories = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Area/getList",
      queryParameters: {"need_entrance": 1, "parent_id": 0},
      header: await getHeader(),
    );
    for (var item in result["data"]) {
      List<LiveSubCategory> subs = [];
      for (var subItem in item["list"]) {
        var subCategory = LiveSubCategory(
          id: subItem["id"].toString(),
          name: asT<String?>(subItem["name"]) ?? "",
          parentId: asT<String?>(subItem["parent_id"]) ?? "",
          pic: "${asT<String?>(subItem["pic"]) ?? ""}@100w.png",
        );
        subs.add(subCategory);
      }
      var category = LiveCategory(
        children: subs,
        id: item["id"].toString(),
        name: asT<String?>(item["name"]) ?? "",
      );
      categories.add(category);
    }
    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(
    LiveSubCategory category, {
    int page = 1,
  }) async {
    const baseUrl =
        "https://api.live.bilibili.com/xlive/web-interface/v1/second/getList";

    var url =
        "$baseUrl?platform=web&parent_area_id=${category.parentId}&area_id=${category.id}&sort_type=&page=$page&w_webid=${await getAccessId()}";

    var queryParams = await getWbiSign(url);

    var result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: queryParams,
      header: await getHeader(),
    );

    var hasMore = result["data"]["has_more"] == 1;
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoomItem(
        roomId: item["roomid"].toString(),
        title: item["title"].toString(),
        cover: "${item["cover"]}@400w.jpg",
        userName: item["uname"].toString(),
        online: int.tryParse(item["online"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({
    required LiveRoomDetail detail,
  }) async {
    List<LivePlayQuality> qualities = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo",
      queryParameters: {
        "room_id": detail.roomId,
        "protocol": "0,1",
        "format": "0,1,2",
        "codec": "0,1",
        "platform": "web",
      },
      header: await getHeader(),
    );
    var qualitiesMap = <int, String>{};
    for (var item in result["data"]["playurl_info"]["playurl"]["g_qn_desc"]) {
      qualitiesMap[int.tryParse(item["qn"].toString()) ?? 0] = item["desc"]
          .toString();
    }

    for (var item
        in result["data"]["playurl_info"]["playurl"]["stream"][0]["format"][0]["codec"][0]["accept_qn"]) {
      var qualityItem = LivePlayQuality(
        quality: qualitiesMap[item] ?? "未知清晰度",
        data: item,
      );
      qualities.add(qualityItem);
    }
    return qualities;
  }

  @override
  Future<LivePlayUrl> getPlayUrls({
    required LiveRoomDetail detail,
    required LivePlayQuality quality,
  }) async {
    List<String> urls = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo",
      queryParameters: {
        "room_id": detail.roomId,
        "protocol": "0,1",
        "format": "0,2",
        "codec": "0",
        "platform": "web",
        "qn": quality.data,
      },
      header: await getHeader(),
    );
    var streamList = result["data"]["playurl_info"]["playurl"]["stream"];
    for (var streamItem in streamList) {
      var formatList = streamItem["format"];
      for (var formatItem in formatList) {
        var codecList = formatItem["codec"];
        for (var codecItem in codecList) {
          var urlList = codecItem["url_info"];
          var baseUrl = codecItem["base_url"].toString();
          for (var urlItem in urlList) {
            urls.add("${urlItem["host"]}$baseUrl${urlItem["extra"]}");
          }
        }
      }
    }
    // 对链接进行排序，包含mcdn的在后
    urls.sort((a, b) {
      if (a.contains("mcdn")) {
        return 1;
      } else {
        return -1;
      }
    });
    return LivePlayUrl(
      urls: urls,
      headers: {
        "referer": "https://live.bilibili.com",
        "user-agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 Edg/115.0.1901.188",
      },
    );
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    const baseUrl =
        "https://api.live.bilibili.com/xlive/web-interface/v1/second/getListByArea";
    var url = "$baseUrl?platform=web&sort=online&page_size=30&page=$page";

    var queryParams = await getWbiSign(url);

    var result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: queryParams,
      header: await getHeader(),
    );

    var hasMore = (result["data"]["list"] as List).isNotEmpty;
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoomItem(
        roomId: item["roomid"].toString(),
        title: item["title"].toString(),
        cover: "${item["cover"]}@400w.jpg",
        userName: item["uname"].toString(),
        online: int.tryParse(item["online"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  Future<LiveRoomDetail> getFollowRoomSnapshot({required String roomId}) async {
    final rawRoomInfo = await getRoomInfo(roomId: roomId);
    final preliminaryRoomId =
        asT<int?>(rawRoomInfo["room_info"]?["room_id"])?.toString() ??
        asT<int?>(rawRoomInfo["room_id"])?.toString() ??
        roomId;
    final roomBaseInfo = await getRoomBaseInfo(roomId: preliminaryRoomId);
    final roomInfo = ensureBilibiliRoomInfo(
      roomInfo: rawRoomInfo,
      roomBaseInfo: roomBaseInfo,
      fallbackRoomId: preliminaryRoomId,
    );
    final realRoomId = roomInfo["room_info"]["room_id"].toString();
    final anchorUid =
        asT<int?>(roomBaseInfo["uid"])?.toString() ??
        asT<int?>(roomInfo["anchor_info"]?["base_info"]?["uid"])?.toString() ??
        roomInfo["anchor_info"]?["base_info"]?["uid"]?.toString() ??
        "";
    final anchorProfileInfo = await getAnchorProfileInfo(uid: anchorUid);
    final liveStartTime =
        normalizeBilibiliLiveStartTime(
          roomInfo["room_info"]?["live_start_time"],
        ) ??
        normalizeBilibiliLiveStartTime(roomBaseInfo["live_start_time"]);

    return LiveRoomDetail(
      roomId: realRoomId,
      title: roomInfo["room_info"]["title"].toString(),
      cover: roomInfo["room_info"]["cover"].toString(),
      userName: resolveBilibiliAnchorName(
        roomInfo: roomInfo,
        accountInfo: anchorProfileInfo,
      ),
      userAvatar: resolveBilibiliAnchorAvatar(
        roomInfo: roomInfo,
        roomBaseInfo: roomBaseInfo,
        accountInfo: anchorProfileInfo,
      ),
      online:
          asT<int?>(roomBaseInfo["online"]) ??
          asT<int?>(roomInfo["room_info"]["online"]) ??
          0,
      watchedText: resolveBilibiliWatchedText(roomInfo),
      captainText: null,
      status: (asT<int?>(roomInfo["room_info"]["live_status"]) ?? 0) == 1,
      url: "https://live.bilibili.com/$roomId",
      introduction: roomInfo["room_info"]["description"].toString(),
      notice: "",
      showTime: liveStartTime,
    );
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    final rawRoomInfo = await getRoomInfo(roomId: roomId);
    final preliminaryRoomId =
        asT<int?>(rawRoomInfo["room_info"]?["room_id"])?.toString() ??
        asT<int?>(rawRoomInfo["room_id"])?.toString() ??
        roomId;
    final roomBaseInfo = await getRoomBaseInfo(roomId: preliminaryRoomId);
    final roomInfo = ensureBilibiliRoomInfo(
      roomInfo: rawRoomInfo,
      roomBaseInfo: roomBaseInfo,
      fallbackRoomId: preliminaryRoomId,
    );
    var realRoomId = roomInfo["room_info"]["room_id"].toString();
    final anchorUid =
        asT<int?>(roomBaseInfo["uid"])?.toString() ??
        asT<int?>(roomInfo["anchor_info"]?["base_info"]?["uid"])?.toString() ??
        roomInfo["anchor_info"]?["base_info"]?["uid"]?.toString() ??
        "";
    final anchorProfileInfo = await getAnchorProfileInfo(uid: anchorUid);
    final guardTotalCount =
        asT<int?>(roomInfo["guard_info"]?["count"]) ??
        asT<int?>(roomBaseInfo["guard_info"]?["count"]) ??
        0;
    final captainText = await getCaptainText(
      roomId: realRoomId,
      anchorUid: anchorUid,
      guardTotalCount: guardTotalCount,
    );

    final roomDanmakuResult = await getStableRoomDanmuInfo(roomId: realRoomId);
    final danmakuData = buildBilibiliDanmakuPayload(
      roomId: realRoomId,
      uid: userId,
      buvid: buvid3,
      cookie: cookie,
      danmuInfo: roomDanmakuResult,
      retryCount: _bilibiliDanmuInfoMaxAttempts,
    );
    if (danmakuData is BiliBiliDanmakuUnavailable) {
      CoreLog.w(
        "B站弹幕已降级为仅播放视频：roomId=$realRoomId retryCount=${danmakuData.retryCount}",
      );
    }

    //var buvid = await getBuvid();
    // 从 roomInfo 中提取 live_start_time
    final liveStartTime =
        normalizeBilibiliLiveStartTime(
          roomInfo["room_info"]?["live_start_time"],
        ) ??
        normalizeBilibiliLiveStartTime(roomBaseInfo["live_start_time"]);

    // 计算开播时长并打印到控制台 (参考斗鱼的实现)
    if (liveStartTime != null &&
        liveStartTime.isNotEmpty &&
        liveStartTime != "0") {
      // 检查是否为0，0可能表示未开播或无此信息
      try {
        int startTimeStamp = int.parse(liveStartTime);
        int currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int durationInSeconds = currentTimeStamp - startTimeStamp;

        int hours = durationInSeconds ~/ 3600;
        int minutes = (durationInSeconds % 3600) ~/ 60;
        int seconds = durationInSeconds % 60;

        String formattedDuration =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        print('Bilibili直播间 $roomId 开播时长: $formattedDuration');
      } catch (e) {
        print('计算 Bilibili 开播时长出错: $e');
      }
    }

    return LiveRoomDetail(
      roomId: realRoomId,
      title: roomInfo["room_info"]["title"].toString(),
      cover: roomInfo["room_info"]["cover"].toString(),
      userName: resolveBilibiliAnchorName(
        roomInfo: roomInfo,
        accountInfo: anchorProfileInfo,
      ),
      userAvatar: resolveBilibiliAnchorAvatar(
        roomInfo: roomInfo,
        roomBaseInfo: roomBaseInfo,
        accountInfo: anchorProfileInfo,
      ),
      online:
          asT<int?>(roomBaseInfo["online"]) ??
          asT<int?>(roomInfo["room_info"]["online"]) ??
          0,
      watchedText: resolveBilibiliWatchedText(roomInfo),
      captainText: captainText,
      status: (asT<int?>(roomInfo["room_info"]["live_status"]) ?? 0) == 1,
      url: "https://live.bilibili.com/$roomId",
      introduction: roomInfo["room_info"]["description"].toString(),
      notice: "",
      danmakuData: danmakuData,
      showTime: liveStartTime, // 将 liveStartTime 赋值给 showTime 字段
    );
  }

  Future<String?> getCaptainText({
    required String roomId,
    required String anchorUid,
    required int guardTotalCount,
  }) async {
    try {
      if (anchorUid.isEmpty) {
        return guardTotalCount > 0 ? "大航海 $guardTotalCount" : null;
      }
      final result = await HttpClient.instance.getJson(
        "https://api.live.bilibili.com/xlive/general-interface/v1/guard/GuardActive",
        queryParameters: {
          "roomid": roomId,
          "ruid": anchorUid,
          "platform": "android",
        },
        header: await getHeader(),
      );
      final captainCount = asT<int?>(result["data"]?["guard_num_3"]) ?? 0;
      final commanderCount = asT<int?>(result["data"]?["guard_num_2"]) ?? 0;
      final admiralCount = asT<int?>(result["data"]?["guard_num_1"]) ?? 0;
      final resolvedGuardTotalCount = guardTotalCount > 0
          ? guardTotalCount
          : captainCount + commanderCount + admiralCount;
      final detailParts = <String>[];
      if (captainCount > 0) {
        detailParts.add("舰长 $captainCount");
      }
      if (commanderCount > 0) {
        detailParts.add("提督 $commanderCount");
      }
      if (admiralCount > 0) {
        detailParts.add("总督 $admiralCount");
      }
      if (resolvedGuardTotalCount <= 0 && detailParts.isEmpty) {
        return null;
      }
      if (detailParts.isEmpty) {
        return "大航海 $resolvedGuardTotalCount";
      }
      return "大航海 $resolvedGuardTotalCount（${detailParts.join(" / ")}）";
    } catch (_) {
      return guardTotalCount > 0 ? "大航海 $guardTotalCount" : null;
    }
  }

  Future<Map<String, dynamic>> getRoomInfo({required String roomId}) async {
    final baseUrl =
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getInfoByRoom";
    final header = await getHeader();
    try {
      var url = "$baseUrl?room_id=$roomId";
      var queryParams = await getWbiSign(url);
      var result = await HttpClient.instance.getJson(
        baseUrl,
        queryParameters: queryParams,
        header: header,
      );
      return normalizeBilibiliDataMap(result["data"]);
    } catch (error) {
      if (!shouldRetryBilibiliRoomDetailRequest(error)) {
        rethrow;
      }
      var result = await HttpClient.instance.getJson(
        baseUrl,
        queryParameters: {"room_id": roomId},
        header: await getPublicHeader(),
      );
      return normalizeBilibiliDataMap(result["data"]);
    }
  }

  Future<Map<String, dynamic>> getRoomDanmuInfo({
    required String roomId,
  }) async {
    const baseUrl =
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo";
    final header = await getHeader();
    try {
      final signedUrl = "$baseUrl?id=$roomId";
      final queryParams = await getWbiSign(signedUrl);
      final result = await HttpClient.instance.getJson(
        baseUrl,
        queryParameters: queryParams,
        header: header,
      );
      return ensureBilibiliDanmuInfo(result["data"]);
    } catch (error) {
      if (!shouldRetryBilibiliRoomDetailRequest(error)) {
        rethrow;
      }
      final result = await HttpClient.instance.getJson(
        baseUrl,
        queryParameters: {"id": roomId},
        header: await getPublicHeader(),
      );
      return ensureBilibiliDanmuInfo(result["data"]);
    }
  }

  Future<Map<String, dynamic>> getAlternateRoomDanmuInfo({
    required String roomId,
  }) async {
    const baseUrl =
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo";
    final result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: {"id": roomId},
      header: await getPublicHeader(),
    );
    return ensureBilibiliDanmuInfo(result["data"]);
  }

  Future<Map<String, dynamic>> getStableRoomDanmuInfo({
    required String roomId,
    int maxAttempts = _bilibiliDanmuInfoMaxAttempts,
  }) async {
    Map<String, dynamic> lastResult = ensureBilibiliDanmuInfo(null);
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await getRoomDanmuInfo(roomId: roomId);
        lastResult = result;
        final serverHosts = extractBilibiliDanmuHosts(result);
        final tokenLength = result["token"]?.toString().length ?? 0;
        CoreLog.i(
          "B站弹幕参数：roomId=$roomId hostCount=${serverHosts.length} tokenLength=$tokenLength attempt=$attempt/$maxAttempts",
        );
        if (hasValidBilibiliDanmuInfo(result)) {
          return result;
        }
        CoreLog.w(
          "B站弹幕参数异常：roomId=$roomId hostCount=${serverHosts.length} tokenEmpty=${tokenLength == 0} attempt=$attempt/$maxAttempts",
        );
      } catch (error) {
        lastError = error;
        CoreLog.w(
          "B站弹幕参数请求失败：roomId=$roomId attempt=$attempt/$maxAttempts error=$error",
        );
      }

      if (attempt < maxAttempts) {
        await Future.delayed(_bilibiliDanmuInfoRetryDelay);
      }
    }
    if (lastError == null && isSemanticEmptyBilibiliDanmuInfo(lastResult)) {
      CoreLog.w("B站弹幕参数语义空结果耗尽：roomId=$roomId retries=$maxAttempts");
      CoreLog.i("B站弹幕参数备用路径开始：roomId=$roomId");
      try {
        final alternateResult = await getAlternateRoomDanmuInfo(roomId: roomId);
        if (hasValidBilibiliDanmuInfo(alternateResult)) {
          final alternateHosts = extractBilibiliDanmuHosts(alternateResult);
          final tokenLength = alternateResult["token"]?.toString().length ?? 0;
          CoreLog.i(
            "B站弹幕参数备用路径恢复：roomId=$roomId hostCount=${alternateHosts.length} tokenLength=$tokenLength",
          );
          return alternateResult;
        }
        final alternateHosts = extractBilibiliDanmuHosts(alternateResult);
        final tokenLength = alternateResult["token"]?.toString().length ?? 0;
        CoreLog.w(
          "B站弹幕参数备用路径最终失败：roomId=$roomId hostCount=${alternateHosts.length} tokenEmpty=${tokenLength == 0}",
        );
      } catch (error) {
        CoreLog.w("B站弹幕参数备用路径最终失败：roomId=$roomId error=$error");
      }
    }
    if (lastError != null) {
      CoreLog.w("B站弹幕参数最终降级：roomId=$roomId error=$lastError");
    } else {
      CoreLog.w("B站弹幕参数最终降级：roomId=$roomId retries=$maxAttempts");
    }
    return lastResult;
  }

  Future<Map<String, dynamic>> getRoomBaseInfo({required String roomId}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Room/get_info",
      queryParameters: {"room_id": roomId},
      header: await getHeader(),
    );
    return result["data"] ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getAnchorProfileInfo({
    required String uid,
  }) async {
    if (uid.isEmpty) {
      return <String, dynamic>{};
    }
    const baseUrl = "https://api.bilibili.com/x/space/wbi/acc/info";
    final url = "$baseUrl?mid=$uid";
    try {
      final queryParams = await getWbiSign(url);
      final result = await HttpClient.instance.getJson(
        baseUrl,
        queryParameters: queryParams,
        header: await getHeader(),
      );
      return result["data"] ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(
    String keyword, {
    int page = 1,
  }) async {
    var result = await HttpClient.instance.getJson(
      "https://api.bilibili.com/x/web-interface/search/type?context=&search_type=live&cover_type=user_cover",
      queryParameters: {
        "order": "",
        "keyword": keyword,
        "category_id": "",
        "__refresh__": "",
        "_extra": "",
        "highlight": 0,
        "single_column": 0,
        "page": page,
      },
      header: await getHeader(),
    );

    var items = <LiveRoomItem>[];
    for (var item in result["data"]["result"]["live_room"] ?? []) {
      var title = item["title"].toString();
      //移除title中的<em></em>标签
      title = title.replaceAll(RegExp(r"<.*?em.*?>"), "");
      var roomItem = LiveRoomItem(
        roomId: item["roomid"].toString(),
        title: title,
        cover: "https:${item["cover"]}@400w.jpg",
        userName: item["uname"].toString(),
        online: int.tryParse(item["online"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: items.length >= 40, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(
    String keyword, {
    int page = 1,
  }) async {
    var result = await HttpClient.instance.getJson(
      "https://api.bilibili.com/x/web-interface/search/type?context=&search_type=live_user&cover_type=user_cover",
      queryParameters: {
        "order": "",
        "keyword": keyword,
        "category_id": "",
        "__refresh__": "",
        "_extra": "",
        "highlight": 0,
        "single_column": 0,
        "page": page,
      },
      header: await getHeader(),
    );

    var items = <LiveAnchorItem>[];
    for (var item in result["data"]["result"] ?? []) {
      var uname = item["uname"].toString();
      //移除title中的<em></em>标签
      uname = uname.replaceAll(RegExp(r"<.*?em.*?>"), "");
      var anchorItem = LiveAnchorItem(
        roomId: item["roomid"].toString(),
        avatar: "https:${item["uface"]}@400w.jpg",
        userName: uname,
        liveStatus: item["is_live"],
      );
      items.add(anchorItem);
    }
    return LiveSearchAnchorResult(hasMore: items.length >= 40, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Room/get_info",
      queryParameters: {"room_id": roomId},
      header: await getHeader(),
    );
    return (asT<int?>(result["data"]["live_status"]) ?? 0) == 1;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({
    required String roomId,
  }) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/av/v1/SuperChat/getMessageList",
      queryParameters: {"room_id": roomId},
      header: await getHeader(),
    );
    List<LiveSuperChatMessage> ls = [];
    for (var item in result["data"]?["list"] ?? []) {
      var message = LiveSuperChatMessage(
        backgroundBottomColor: item["background_bottom_color"].toString(),
        backgroundColor: item["background_color"].toString(),
        endTime: DateTime.fromMillisecondsSinceEpoch(item["end_time"] * 1000),
        face: "${item["user_info"]["face"]}@200w.jpg",
        message: item["message"].toString(),
        price: item["price"],
        startTime: DateTime.fromMillisecondsSinceEpoch(
          item["start_time"] * 1000,
        ),
        userName: item["user_info"]["uname"].toString(),
      );
      ls.add(message);
    }
    return ls;
  }

  /// 获取 buvid3 和 buvid4
  /// 返回buvid3和buvid4
  /// ``` json
  /// {
  ///   "b_3": "buvid3",
  ///   "b_4": "buvid4",
  /// }
  /// ```
  Future<Map> getBuvid() async {
    try {
      if (cookie.contains("buvid3")) {
        return {
          "b_3": RegExp(r"buvid3=(.*?);").firstMatch(cookie)?.group(1) ?? "",
          "b_4": RegExp(r"buvid4=(.*?);").firstMatch(cookie)?.group(1) ?? "",
        };
      }

      var result = await HttpClient.instance.getJson(
        "https://api.bilibili.com/x/frontend/finger/spi",
        queryParameters: {},
        header: {
          "user-agent": kDefaultUserAgent,
          "referer": kDefaultReferer,
          "cookie": cookie,
        },
      );
      return result["data"];
    } catch (e) {
      return {"b_3": "", "b_4": ""};
    }
  }

  static String kImgKey = '';
  static String kSubKey = '';
  static const List<int> mixinKeyEncTab = [
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
    37,
    48,
    7,
    16,
    24,
    55,
    40,
    61,
    26,
    17,
    0,
    1,
    60,
    51,
    30,
    4,
    22,
    25,
    54,
    21,
    56,
    59,
    6,
    63,
    57,
    62,
    11,
    36,
    20,
    34,
    44,
    52,
  ];
  Future<(String, String)> getWbiKeys() async {
    if (kImgKey.isNotEmpty && kSubKey.isNotEmpty) {
      return (kImgKey, kSubKey);
    }
    // 获取最新的 img_key 和 sub_key
    var resp = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/nav',
      header: await getHeader(),
    );

    var imgUrl = resp["data"]["wbi_img"]["img_url"].toString();
    var subUrl = resp["data"]["wbi_img"]["sub_url"].toString();
    var imgKey = imgUrl.substring(imgUrl.lastIndexOf('/') + 1).split('.').first;
    var subKey = subUrl.substring(subUrl.lastIndexOf('/') + 1).split('.').first;

    kImgKey = imgKey;
    kSubKey = subKey;

    return (imgKey, subKey);
  }

  String getMixinKey(String origin) {
    // 对 imgKey 和 subKey 进行字符顺序打乱编码
    return mixinKeyEncTab.fold("", (s, i) => s + origin[i]).substring(0, 32);
  }

  Future<Map<String, String>> getWbiSign(String url) async {
    var (imgKey, subKey) = await getWbiKeys();

    // 为请求参数进行 wbi 签名
    var mixinKey = getMixinKey(imgKey + subKey);
    var currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var queryParams = Map<String, String>.from(Uri.parse(url).queryParameters);

    queryParams["wts"] = currentTime.toString(); // 添加 wts 字段

    //按照 key 重排参数
    Map<String, String> map = {};
    var sortedKeys = queryParams.keys.toList()..sort();
    for (var key in sortedKeys) {
      var value = queryParams[key]!;
      // 过滤 value 中的 "!'()*" 字符
      map[key] = value
          .toString()
          .split('')
          .where((c) => "!'()*".contains(c) == false)
          .join('');
    }

    var query = map.keys
        .map((key) => "$key=${Uri.encodeQueryComponent(map[key]!)}")
        .join("&");
    var wbiSign = md5.convert(utf8.encode("$query$mixinKey")).toString();
    queryParams["w_rid"] = wbiSign;
    return queryParams;
  }

  Future<String> getAccessId() async {
    if (accessId.isNotEmpty) {
      return accessId;
    }

    // 获取 access_id
    var resp = await HttpClient.instance.getText(
      "https://live.bilibili.com/lol",
      queryParameters: {},
      header: await getHeader(),
    );
    var id = RegExp(
      r'"access_id":"(.*?)"',
    ).firstMatch(resp)?.group(1)?.replaceAll("\\", "");
    accessId = id ?? "";
    return accessId;
  }

  @override
  Future<List<LiveContributionRankItem>> getContributionRank({
    required String roomId,
    LiveRoomDetail? detail,
  }) async {
    try {
      final roomInfo = await getRoomInfo(roomId: roomId);
      final roomRankItems = (roomInfo["room_rank_info"]?["user_rank_entry"]
              ?["user_contribution_rank_entry"]?["item"] as List?) ??
          const [];
      if (roomRankItems.isNotEmpty) {
        return roomRankItems
            .asMap()
            .entries
            .map(
              (entry) => LiveContributionRankItem.fromGenericMap(
                Map<String, dynamic>.from(entry.value as Map),
                fallbackRank: entry.key + 1,
              ),
            )
            .toList();
      }

      final roomData = roomInfo["room_info"] ?? {};
      final uid = roomData["uid"]?.toString() ?? "";
      final realRoomId = roomData["room_id"]?.toString() ?? roomId;
      if (uid.isEmpty) {
        return [];
      }

      final result = await HttpClient.instance.getJson(
        "https://api.live.bilibili.com/xlive/general-interface/v1/rank/queryContributionRank",
        queryParameters: {
          "ruid": uid,
          "room_id": realRoomId,
          "page": 1,
          "page_size": 50,
        },
        header: await getHeader(),
      );
      final items = (result["data"]?["item"] as List?) ?? const [];
      return items
          .asMap()
          .entries
          .map(
            (entry) => LiveContributionRankItem.fromGenericMap(
              Map<String, dynamic>.from(entry.value as Map),
              fallbackRank: entry.key + 1,
            ),
          )
          .toList();
    } catch (e) {
      CoreLog.error(e);
      return [];
    }
  }
}

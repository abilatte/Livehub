import 'package:livehub_app/app/controller/base_controller.dart';
import 'package:livehub_app/app/sites.dart';
import 'package:livehub_core/livehub_core.dart';

class HomeListController extends BasePageController<LiveRoomItem> {
  final Site site;
  HomeListController(this.site);

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    var result = await site.liveSite.getRecommendRooms(page: page);

    return result.items;
  }
}

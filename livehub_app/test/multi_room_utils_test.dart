import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/modules/multi_room/multi_room_utils.dart';

void main() {
  group('MultiRoomUtils', () {
    test('distinctRoomKeys preserves order and drops dups', () {
      expect(
        MultiRoomUtils.distinctRoomKeys([
          'bilibili_1',
          'douyin_2',
          'bilibili_1',
          ' ',
        ]),
        ['bilibili_1', 'douyin_2'],
      );
    });

    test('gridColumnCount scales with width and room count', () {
      expect(
        MultiRoomUtils.gridColumnCount(roomCount: 1, maxWidth: 2000),
        1,
      );
      expect(
        MultiRoomUtils.gridColumnCount(roomCount: 4, maxWidth: 800),
        2,
      );
      expect(
        MultiRoomUtils.gridColumnCount(roomCount: 4, maxWidth: 1500),
        3,
      );
      expect(
        MultiRoomUtils.gridColumnCount(roomCount: 3, maxWidth: 500),
        1,
      );
    });

    test('capRooms limits concurrent rooms', () {
      final rooms = List.generate(10, (i) => i);
      expect(MultiRoomUtils.capRooms(rooms).length, MultiRoomUtils.maxRooms);
      expect(MultiRoomUtils.capRooms([1, 2]).length, 2);
    });
  });
}

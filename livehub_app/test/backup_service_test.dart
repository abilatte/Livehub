import 'package:flutter_test/flutter_test.dart';
import 'package:livehub_app/models/db/follow_user.dart';
import 'package:livehub_app/services/backup_service.dart';

void main() {
  group('BackupService 导出结构', () {
    test('配置导出使用独立类型且不再夹带屏蔽词', () {
      final payload = BackupService.buildConfigPayload(
        settings: {
          'ThemeMode': 2,
          'PlayerVolume': 45.0,
        },
        platform: 'windows',
        now: DateTime(2026, 3, 21, 12, 30, 0),
      );

      expect(payload['type'], BackupService.configType);
      expect(payload['config'], {
        'ThemeMode': 2,
        'PlayerVolume': 45.0,
      });
      expect(payload.containsKey('shield'), isFalse);
    });

    test('导出全部固定写出三份文件', () {
      final files = BackupService.buildAllExportFiles(
        settings: {'ThemeMode': 2},
        shieldWords: const ['剧透', '广告'],
        follows: [
          FollowUser(
            id: 'bilibili_1',
            roomId: '1',
            siteId: 'bilibili',
            userName: '主播',
            face: 'face',
            addTime: DateTime(2026, 3, 21, 8, 0, 0),
          ),
        ],
        platform: 'windows',
        now: DateTime(2026, 3, 21, 12, 30, 0),
      );

      expect(
        files.keys.toSet(),
        {
          BackupService.configFileName,
          BackupService.shieldFileName,
          BackupService.followFileName,
        },
      );
    });
  });

  group('BackupService 兼容旧格式', () {
    test('旧版配置文件仍然能读取配置和屏蔽词', () {
      const legacyContent = '''
{
  "type": "simple_live",
  "platform": "windows",
  "version": 1,
  "time": 1770000000000,
  "config": {
    "ThemeMode": 2,
    "PlayerVolume": 66.0
  },
  "shield": {
    "剧透": "剧透",
    "广告": "广告"
  }
}
''';

      final payload = BackupService.decodePayloadMap(legacyContent);

      expect(
        BackupService.extractConfigEntries(payload),
        {
          'ThemeMode': 2,
          'PlayerVolume': 66.0,
        },
      );
      expect(
        BackupService.extractShieldWords(payload),
        ['剧透', '广告'],
      );
    });

    test('旧版关注列表裸数组仍然能读取', () {
      const legacyContent = '''
[
  {
    "siteId": "bilibili",
    "id": "bilibili_13308358",
    "roomId": "13308358",
    "userName": "甜药Jamren",
    "face": "face",
    "addTime": "2026-03-21 12:00:00.000",
    "tag": "全部"
  }
]
''';

      final follows = BackupService.extractFollowUsers(legacyContent);

      expect(follows, hasLength(1));
      expect(follows.first.roomId, '13308358');
      expect(follows.first.userName, '甜药Jamren');
    });

    test('导入全部扫描时能识别旧版拆分文件类型', () {
      expect(
        BackupService.detectBackupKind('''
{
  "type": "simple_live_config",
  "config": {
    "ThemeMode": 2
  }
}
'''),
        BackupService.legacyConfigFileType,
      );

      expect(
        BackupService.detectBackupKind('''
{
  "type": "simple_live_shield_list",
  "shield": ["剧透", "广告"]
}
'''),
        BackupService.legacyShieldType,
      );

      expect(
        BackupService.detectBackupKind('''
{
  "type": "simple_live_follow_list",
  "follow": []
}
'''),
        BackupService.legacyFollowType,
      );
    });
  });
}

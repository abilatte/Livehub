import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/log.dart';
import 'package:livehub_app/app/utils.dart';

class DebugLogPage extends StatelessWidget {
  const DebugLogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log"),
        actions: [
          IconButton(
            onPressed: () async {
              var msg = Log.debugLogs
                  .map((x) => "${x.datetime}\r\n${x.content}")
                  .join('\r\n\r\n');
              var dir = await getApplicationDocumentsDirectory();
              var logFile = File(
                  '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.log');
              await logFile.writeAsString(msg);
              Utils.copyToClipboard(logFile.path);
              Get.snackbar("日志已保存", "已复制日志文件路径");
            },
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: () {
              Log.debugLogs.clear();
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Obx(
        () => ListView.separated(
          itemCount: Log.debugLogs.length,
          separatorBuilder: (_, i) => const Divider(),
          padding: AppStyle.edgeInsetsA12,
          itemBuilder: (_, i) {
            var item = Log.debugLogs[i];
            return SelectableText(
              "${item.datetime.toString()}\r\n${item.content}",
              style: TextStyle(
                color: item.color,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
    );
  }
}

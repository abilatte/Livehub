import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livehub_app/app/app_style.dart';
import 'package:livehub_app/app/utils.dart';
import 'package:livehub_app/modules/live_room/super_chat_utils.dart';
import 'package:livehub_app/widgets/net_image.dart';
import 'package:livehub_core/livehub_core.dart';

class SuperChatCard extends StatefulWidget {
  final LiveSuperChatMessage message;
  final Function()? onExpire;
  final int? customCountdown;
  final bool showCountdown;
  final String? trailingText;
  const SuperChatCard(
    this.message, {
    required this.onExpire,
    this.customCountdown,
    this.showCountdown = true,
    this.trailingText,
    Key? key,
  }) : super(key: key);

  @override
  State<SuperChatCard> createState() => _SuperChatCardState();
}

class _SuperChatCardState extends State<SuperChatCard> {
  Timer? timer;

  int countdown = 0;

  @override
  void initState() {
    super.initState();
    setupCountdown();
  }

  @override
  void didUpdateWidget(covariant SuperChatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.customCountdown != widget.customCountdown ||
        oldWidget.showCountdown != widget.showCountdown ||
        oldWidget.trailingText != widget.trailingText) {
      setupCountdown();
    }
  }

  void setupCountdown() {
    timer?.cancel();
    countdown =
        widget.customCountdown ?? remainingSuperChatSeconds(widget.message);
    if (!widget.showCountdown || widget.customCountdown != null) {
      return;
    }
    if (countdown <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onExpire?.call();
      });
      return;
    }
    timer = Timer.periodic(const Duration(seconds: 1), timerCallback);
  }

  void timerCallback(e) {
    if (countdown <= 1) {
      setState(() {
        countdown = 0;
      });
      widget.onExpire?.call();
      timer?.cancel();
      return;
    }

    setState(() {
      countdown -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayCountdown = widget.customCountdown ?? countdown;
    return ClipRRect(
      borderRadius: AppStyle.radius8,
      child: Container(
        decoration: BoxDecoration(
          color: Utils.convertHexColor(widget.message.backgroundColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppStyle.edgeInsetsA8,
              child: Row(
                children: [
                  NetImage(
                    widget.message.face,
                    width: 48,
                    height: 48,
                    borderRadius: 36,
                  ),
                  AppStyle.hGap12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.message.userName,
                          style: const TextStyle(
                            color: AppColors.black333,
                          ),
                        ),
                        Text(
                          "￥${widget.message.price}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.trailingText != null)
                    Text(
                      widget.trailingText!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    )
                  else if (widget.showCountdown)
                    Text(
                      "$displayCountdown",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color:
                    Utils.convertHexColor(widget.message.backgroundBottomColor),
              ),
              padding: AppStyle.edgeInsetsA8,
              child: Text(
                widget.message.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

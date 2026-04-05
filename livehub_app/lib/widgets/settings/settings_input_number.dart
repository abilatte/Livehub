import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:livehub_app/app/app_style.dart';

class SettingsInputNumber extends StatefulWidget {
  final String title;
  final String? titleTooltip;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final String hintText;
  final ValueChanged<int> onChanged;

  const SettingsInputNumber({
    required this.title,
    required this.value,
    required this.hintText,
    required this.onChanged,
    this.titleTooltip,
    this.subtitle,
    this.min = 0,
    this.max = 9999,
    super.key,
  });

  @override
  State<SettingsInputNumber> createState() => _SettingsInputNumberState();
}

class _SettingsInputNumberState extends State<SettingsInputNumber> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? widget.value.toString() : "",
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitText(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SettingsInputNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus) {
      return;
    }
    final expectedText = widget.value > 0 ? widget.value.toString() : "";
    if (_controller.text != expectedText) {
      _controller.text = expectedText;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commitText(String text) {
    final value = int.tryParse(text.trim()) ?? 0;
    final safeValue = value <= 0 ? 0 : value.clamp(widget.min, widget.max);
    final nextText = safeValue > 0 ? safeValue.toString() : "";
    if (_controller.text != nextText) {
      _controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }
    widget.onChanged(safeValue);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: widget.titleTooltip == null
          ? Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyLarge,
            )
          : Tooltip(
              message: widget.titleTooltip!,
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
      subtitle: widget.subtitle == null
          ? null
          : Text(
              widget.subtitle!,
              style: Get.textTheme.bodySmall!.copyWith(color: Colors.grey),
            ),
      contentPadding: AppStyle.edgeInsetsL16.copyWith(right: 16),
      trailing: SizedBox(
        width: 132,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.end,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.withAlpha(170)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onSubmitted: _commitText,
        ),
      ),
    );
  }
}

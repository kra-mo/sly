import 'package:flutter/material.dart';

import 'slider.dart';

class SlySliderRow extends StatefulWidget {
  const SlySliderRow({
    super.key,
    required this.value,
    this.secondaryTrackValue,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.secondaryActiveColor,
    this.thumbColor,
    this.overlayColor,
    this.mouseCursor,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.allowedInteraction,
  });

  final double value;
  final double? secondaryTrackValue;
  final void Function(double)? onChanged;
  final void Function(double)? onChangeStart;
  final void Function(double)? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? secondaryActiveColor;
  final Color? thumbColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final MouseCursor? mouseCursor;
  final String Function(double)? semanticFormatterCallback;
  final FocusNode? focusNode;
  final bool autofocus;
  final SliderInteraction? allowedInteraction;

  @override
  State<SlySliderRow> createState() => _SlySliderRowState();
}

class _SlySliderRowState extends State<SlySliderRow> {
  late String? label = getLabel(widget.value);

  String? getLabel(num value) {
    final initial = (widget.secondaryTrackValue ?? 0);
    if (value == initial) return null;

    final v = value.abs();
    final i = initial.abs();
    final min = widget.min.abs();
    final max = widget.max.abs();

    String valueLabel =
        '${v < i ? '-' : '+'}${(100 * ((v - i) / ((v < i ? min : max) - i))).round().toString()}';

    return (valueLabel == '+0' || valueLabel == "-0") ? null : valueLabel;
  }

  late final slider = SlySlider(
    value: widget.value,
    secondaryTrackValue: widget.secondaryTrackValue,
    onChanged: widget.onChanged,
    onChangeStart: widget.onChangeStart,
    onChangeEnd: (value) {
      setState(() {
        label = getLabel(value);
      });
      if (widget.onChangeEnd != null) widget.onChangeEnd!(value);
    },
    min: widget.min,
    max: widget.max,
    divisions: widget.divisions,
    label: widget.label,
    activeColor: widget.activeColor,
    inactiveColor: widget.inactiveColor,
    secondaryActiveColor: widget.secondaryActiveColor,
    thumbColor: widget.thumbColor,
    overlayColor: widget.overlayColor,
    mouseCursor: widget.mouseCursor,
    semanticFormatterCallback: widget.semanticFormatterCallback,
    focusNode: widget.focusNode,
    autofocus: widget.autofocus,
    allowedInteraction: widget.allowedInteraction,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 24, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label ?? '',
                  style: TextStyle(color: Colors.grey.shade200),
                ),
                Text(
                  label ?? '',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          slider
        ],
      ),
    );
  }
}

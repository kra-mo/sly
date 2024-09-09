import 'package:flutter/material.dart';

class SlySlider extends StatefulWidget {
  const SlySlider({
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
  State<SlySlider> createState() => _SlySliderState();
}

class _SlySliderState extends State<SlySlider> {
  late double value = widget.value;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SlySliderThemeData(),
      child: GestureDetector(
        // Reset to secondary track value on double tap
        onDoubleTap: () {
          setState(() {
            value = widget.secondaryTrackValue ?? 0;
          });

          if (widget.onChangeStart != null) widget.onChangeStart!(value);
          if (widget.onChanged != null) widget.onChanged!(value);
          if (widget.onChangeEnd != null) widget.onChangeEnd!(value);
        },
        child: Slider(
          value: value,
          secondaryTrackValue: widget.secondaryTrackValue,
          onChanged: (v) {
            setState(() {
              value = v;
            });
            if (widget.onChanged != null) widget.onChanged!(v);
          },
          onChangeStart: widget.onChangeStart,
          onChangeEnd: (v) {
            setState(() {
              value = v;
            });
            if (widget.onChangeEnd != null) widget.onChangeEnd!(v);
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
        ),
      ),
    );
  }
}

class SlySliderThemeData extends SliderThemeData {
  SlySliderThemeData()
      : super(
          activeTrackColor: Colors.white,
          secondaryActiveTrackColor: Colors.grey.shade600,
          inactiveTrackColor: Colors.grey.shade800,
          thumbColor: Colors.white,
          trackHeight: 18,
          thumbShape: InsetSliderThumbShape(),
          overlayColor: Colors.transparent,
        );
}

class InsetSliderThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(10);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawCircle(
        center,
        10,
        Paint()
          ..color = sliderTheme.activeTrackColor!
          ..style = PaintingStyle.fill);
    context.canvas.drawCircle(
        center,
        6 * activationAnimation.value,
        Paint()
          ..color = sliderTheme.inactiveTrackColor!
          ..style = PaintingStyle.fill);
  }
}

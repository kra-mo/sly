import 'dart:math';

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
    this.gradient,
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
  final LinearGradient? gradient;

  @override
  State<SlySlider> createState() => _SlySliderState();
}

class _SlySliderState extends State<SlySlider> {
  late double value = widget.value;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        secondaryActiveTrackColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        inactiveTrackColor: Theme.of(context).disabledColor,
        trackHeight: 18,
        thumbShape: InsetSliderThumbShape(),
        trackShape: SlySliderTrackShape(widget.gradient),
        overlayColor: Colors.transparent,
      ),
      child: GestureDetector(
        // Reset to secondary track value on double tap
        onDoubleTap: () {
          setState(() => value = widget.secondaryTrackValue ?? 0);

          if (widget.onChangeStart != null) widget.onChangeStart!(value);
          if (widget.onChanged != null) widget.onChanged!(value);
          if (widget.onChangeEnd != null) widget.onChangeEnd!(value);
        },
        child: Slider(
          value: value,
          secondaryTrackValue: widget.secondaryTrackValue,
          onChanged: (v) {
            setState(() => value = v);
            if (widget.onChanged != null) widget.onChanged!(v);
          },
          onChangeStart: widget.onChangeStart,
          onChangeEnd: (v) {
            setState(() => value = v);
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
          mouseCursor: widget.mouseCursor ?? SystemMouseCursors.basic,
          semanticFormatterCallback: widget.semanticFormatterCallback,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          allowedInteraction:
              widget.allowedInteraction ?? SliderInteraction.slideThumb,
        ),
      ),
    );
  }
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
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: 10 + (2 * activationAnimation.value),
          height: 32 + (4 * activationAnimation.value),
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = sliderTheme.activeTrackColor!
        ..style = PaintingStyle.fill,
    );
  }
}

class SlySliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const SlySliderTrackShape(this.gradient);

  final LinearGradient? gradient;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    // If the slider [SliderThemeData.trackHeight] is less than or equal to 0,
    // then it makes no difference whether the track is painted or not,
    // therefore the painting can be a no-op.
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Assign the track segment paints, which are leading: active and
    // trailing: inactive.
    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..shader = gradient?.createShader(trackRect)
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final (Paint leftTrackPaint, Paint rightTrackPaint) =
        switch (textDirection) {
      TextDirection.ltr => (activePaint, inactivePaint),
      TextDirection.rtl => (inactivePaint, activePaint),
    };

    const int thumbRadius = 5;
    context.canvas.drawRRect(
      RRect.fromLTRBR(
        trackRect.left - thumbRadius,
        trackRect.top,
        trackRect.right + thumbRadius,
        trackRect.bottom,
        Radius.circular(trackRect.height / 2),
      ),
      rightTrackPaint,
    );

    final bool isLTR = textDirection == TextDirection.ltr;
    if (gradient == null && secondaryOffset != null) {
      context.canvas.drawRRect(
        RRect.fromLTRBR(
          max(secondaryOffset.dx, thumbCenter.dx) + thumbRadius,
          isLTR ? trackRect.top : trackRect.top,
          min(secondaryOffset.dx, thumbCenter.dx) - thumbRadius,
          isLTR ? trackRect.bottom : trackRect.bottom,
          const Radius.circular(4),
        ),
        leftTrackPaint,
      );
    }
  }
}

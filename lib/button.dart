import 'package:flutter/material.dart';

class SlyButton extends StatefulWidget {
  const SlyButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior,
    this.statesController,
    required this.child,
    this.iconAlignment = IconAlignment.start,
  });

  final void Function()? onPressed;
  final void Function()? onLongPress;
  final void Function(bool)? onHover;
  final void Function(bool)? onFocusChange;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip? clipBehavior;
  final WidgetStatesController? statesController;
  final Widget? child;
  final IconAlignment iconAlignment;

  @override
  State<SlyButton> createState() => SlyButtonState();

  void setChild(Widget newChild) {
    if (key is GlobalKey<SlyButtonState>) {
      final state = (key as GlobalKey<SlyButtonState>).currentState;
      state?.setChild(newChild);
    }
  }
}

class SlyButtonState extends State<SlyButton> {
  ElevatedButton? elevatedButton;
  late Widget elevatedButtonChild = SizedBox(
    height: 40,
    child: Center(
      child: widget.child!,
    ),
  );

  @override
  Widget build(BuildContext context) {
    elevatedButton = ElevatedButton(
      onPressed: widget.onPressed,
      onLongPress: widget.onLongPress,
      onHover: widget.onHover,
      onFocusChange: widget.onFocusChange,
      style: widget.style ??
          ButtonStyle(
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w600),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
              ),
            ),
            splashFactory: NoSplash.splashFactory,
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.black.withOpacity(0.08),
            ),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      clipBehavior: widget.clipBehavior,
      iconAlignment: widget.iconAlignment,
      child: elevatedButtonChild,
    );
    return elevatedButton!;
  }

  void setChild(Widget newChild) {
    setState(() {
      elevatedButtonChild = SizedBox(
        height: 40,
        child: Center(
          child: getCrossfade(elevatedButtonChild, newChild),
        ),
      );
    });
  }
}

Widget getCrossfade(Widget widget1, Widget widget2) {
  return AnimatedCrossFade(
    duration: const Duration(milliseconds: 700),
    firstChild: widget1,
    secondChild: widget2,
    crossFadeState: CrossFadeState.showSecond,
    firstCurve: Curves.easeOutQuint,
    secondCurve: Curves.easeInQuint,
    sizeCurve: Curves.easeInOutQuint,
  );
}

const ButtonStyle slyElevatedButtonStlye = ButtonStyle(
  textStyle: WidgetStatePropertyAll(
    TextStyle(fontWeight: FontWeight.w600),
  ),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(12),
      ),
    ),
  ),
  splashFactory: NoSplash.splashFactory,
  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
  shadowColor: WidgetStatePropertyAll(Colors.transparent),
  backgroundColor: WidgetStatePropertyAll(Colors.white),
  foregroundColor: WidgetStatePropertyAll(Colors.black87),
  iconColor: WidgetStatePropertyAll(Colors.black87),
  overlayColor: WidgetStatePropertyAll(Colors.black12),
);

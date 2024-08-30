import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SlyButton extends StatefulWidget {
  const SlyButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.style = slyElevatedButtonStlye,
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
      style: widget.style,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      clipBehavior: widget.clipBehavior,
      iconAlignment: widget.iconAlignment,
      child: elevatedButtonChild,
    );
    return CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.light),
        child: Theme(data: ThemeData.light(), child: elevatedButton!));
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
    duration: const Duration(milliseconds: 500),
    firstChild: widget1,
    secondChild: widget2,
    crossFadeState: CrossFadeState.showSecond,
  );
}

const ButtonStyle slyElevatedButtonStlye = ButtonStyle(
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(12),
      ),
    ),
  ),
  overlayColor: WidgetStatePropertyAll(Colors.black12),
  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
  foregroundColor: WidgetStatePropertyAll(Colors.black),
  iconColor: WidgetStatePropertyAll(Colors.black),
  backgroundColor: WidgetStatePropertyAll(Colors.white),
  shadowColor: WidgetStatePropertyAll(Colors.transparent),
);

const ButtonStyle slySubtleButtonStlye = ButtonStyle(
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(12),
      ),
    ),
  ),
  overlayColor: WidgetStatePropertyAll(Colors.white10),
  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
  foregroundColor: WidgetStatePropertyAll(Colors.white),
  iconColor: WidgetStatePropertyAll(Colors.white),
  backgroundColor: WidgetStatePropertyAll(Colors.white10),
  shadowColor: WidgetStatePropertyAll(Colors.transparent),
);

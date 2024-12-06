import 'package:flutter/material.dart';

import '/theme.dart';

class SlyButton extends StatefulWidget {
  const SlyButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.suggested = false,
    required this.child,
  });

  final void Function()? onPressed;
  final void Function()? onLongPress;
  final void Function(bool)? onHover;
  final void Function(bool)? onFocusChange;
  final bool suggested;
  final Widget? child;

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
      child:
          widget.suggested ? LightTheme(child: widget.child!) : widget.child!,
    ),
  );

  @override
  Widget build(BuildContext context) {
    elevatedButton = ElevatedButton(
      onPressed: widget.onPressed,
      onLongPress: widget.onLongPress,
      onHover: widget.onHover,
      onFocusChange: widget.onFocusChange,
      style: ButtonStyle(
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
        overlayColor: const WidgetStatePropertyAll(Colors.black12),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStatePropertyAll(
          Theme.of(context).brightness == Brightness.dark
              ? widget.suggested
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hoverColor
              : widget.suggested
                  ? Theme.of(context).focusColor
                  : Theme.of(context).hoverColor,
        ),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).brightness == Brightness.dark && !widget.suggested
              ? Colors.white
              : Colors.grey.shade900,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutQuint,
        switchOutCurve: Curves.easeInQuint,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: widget.suggested
            ? LightTheme(
                key: UniqueKey(),
                child: elevatedButtonChild,
              )
            : elevatedButtonChild,
      ),
    );
    return elevatedButton!;
  }

  void setChild(Widget newChild) {
    setState(() {
      elevatedButtonChild = SizedBox(
        key: UniqueKey(),
        height: 40,
        child: Center(child: newChild),
      );
    });
  }
}

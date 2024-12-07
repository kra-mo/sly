import 'package:flutter/material.dart';

Widget getControlsView(
  BoxConstraints constraints,
  int keyValue,
  Widget? child,
) {
  return AnimatedSize(
    key: Key('controlsWidget $keyValue'),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutQuint,
    child: AnimatedSwitcher(
      switchInCurve: Curves.easeOutQuint,
      // switchOutCurve: Curves.easeInSine,
      transitionBuilder: (Widget newChild, Animation<double> animation) {
        // Don't transition widgets animating out
        // as this causes issues with the crop page
        if (newChild != child) return Container();

        return SlideTransition(
          key: ValueKey<Key?>(newChild.key),
          position: Tween<Offset>(
            begin: (constraints.maxWidth > 600)
                ? const Offset(0.07, 0.0)
                : const Offset(0.0, 0.07),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            key: ValueKey<Key?>(newChild.key),
            opacity: animation,
            child: newChild,
          ),
        );
      },
      duration: const Duration(milliseconds: 150),
      child: child,
    ),
  );
}

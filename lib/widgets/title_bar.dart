import 'dart:io';

import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

import '/platform.dart';

class SlyDragWindowBox extends DragToMoveArea {
  const SlyDragWindowBox({super.key, required super.child});
}

class SlyTitleBarBox extends SizedBox {
  SlyTitleBarBox({super.key, required super.child})
      : super(
          height: platformInsetTopBarHeight,
        );
}

class SlyTitleBar extends StatelessWidget {
  const SlyTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return isLinux
        ? Padding(
            padding: const EdgeInsets.only(
              top: 6,
              bottom: 16,
              left: 8,
              right: 8,
            ),
            child: SlyTitleBarBox(
              child: SlyDragWindowBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Semantics(
                      label: 'Close Window',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              Theme.of(context).hoverColor),
                        ),
                        iconSize: 16,
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                          maxWidth: 24,
                          maxHeight: 24,
                        ),
                        icon: const ImageIcon(
                          AssetImage('assets/icons/window-close.png'),
                        ),
                        onPressed: () {
                          exit(0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : SlyTitleBarBox(
            child: Container(),
          );
  }
}

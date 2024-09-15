import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

class SlyDragWindowBox extends DragToMoveArea {
  const SlyDragWindowBox({super.key, required super.child});
}

class SlyTitleBarBox extends SizedBox {
  SlyTitleBarBox({super.key, required super.child})
      : super(
          height: !kIsWeb
              ? Platform.isMacOS
                  ? 28
                  : Platform.isLinux
                      ? 32
                      : 0
              : 0,
        );
}

final titleBar = !kIsWeb && Platform.isLinux
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
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.white10),
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

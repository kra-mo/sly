import 'dart:io';

import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'utils.dart';

class SlyDragWindowBox extends MoveWindow {
  SlyDragWindowBox({super.key, super.child});
}

final slyWindowButtonColors = WindowButtonColors(
  iconNormal: Colors.white,
  mouseOver: Colors.white10,
  mouseDown: Colors.white24,
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);

class SlyTitleBarBox extends SizedBox {
  SlyTitleBarBox({super.key, required super.child})
      : super(
          height: isDesktop()
              ? Platform.isMacOS
                  ? 28
                  : 32
              : 0,
        );
}

final titleBar = isDesktop()
    ? Padding(
        padding: Platform.isLinux
            ? const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              )
            : const EdgeInsets.all(0),
        child: SlyTitleBarBox(
          child: MoveWindow(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: Platform.isLinux
                  ? <Widget>[
                      Semantics(
                        label: 'Close Window',
                        child: IconButton(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.white10),
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
                    ]
                  : <Widget>[
                      MinimizeWindowButton(
                        colors: slyWindowButtonColors,
                      ),
                      MaximizeWindowButton(
                        colors: slyWindowButtonColors,
                      ),
                      CloseWindowButton(
                        colors: slyWindowButtonColors,
                      ),
                    ],
            ),
          ),
        ),
      )
    : Container();

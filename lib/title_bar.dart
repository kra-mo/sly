import 'dart:io';

import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';

final slyWindowButtonColors = WindowButtonColors(
  iconNormal: Colors.white,
  mouseOver: Colors.white10,
  mouseDown: Colors.white24,
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);

final titleBar = Padding(
  padding: EdgeInsets.all(Platform.isLinux ? 8 : 0),
  child: WindowTitleBarBox(
    child: MoveWindow(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: Platform.isLinux
            ? <Widget>[
                ClipOval(
                  child: Container(
                    color: Colors.white10,
                    child: CloseWindowButton(
                      animate: true,
                      colors: slyWindowButtonColors,
                    ),
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
);

import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';

import '/platform.dart';

void showFullScreenViewer(BuildContext context, Uint8List editedImageData) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: CurvedAnimation(
          curve: Curves.easeOutExpo,
          parent: animation,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Scaffold(
            body: Row(children: [
              Expanded(
                child: Column(children: [
                  Expanded(
                    child: InteractiveViewer(
                      clipBehavior: Clip.none,
                      child: Hero(
                        tag: 'image',
                        child: Image.memory(
                          editedImageData,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.miniEndTop,
            floatingActionButton: Padding(
              padding: EdgeInsetsDirectional.only(
                top: platformHasRightAlignedWindowControls
                    ? platformInsetTopBarHeight
                    : 0 + 12,
              ),
              child: FloatingActionButton.small(
                heroTag: 'close',
                shape: const CircleBorder(),
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                focusColor: Colors.white10,
                hoverColor: Colors.white10,
                splashColor: Colors.transparent,
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                disabledElevation: 0,
                highlightElevation: 0,
                child: Transform.rotate(
                  angle: pi / 4,
                  child: Semantics(
                    label: 'Close',
                    child: const ImageIcon(
                      AssetImage('assets/icons/add.webp'),
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.black,
          ),
        ),
      ),
    ),
  );
}

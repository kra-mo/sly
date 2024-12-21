import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';

import '/layout.dart';
import '/image.dart';
import '/widgets/button.dart';
import '/widgets/tooltip.dart';
import '/widgets/dialog.dart';
import '/widgets/toggle_buttons.dart';

class SlyGeometryControls extends StatelessWidget {
  final CropController? cropController;
  final Function setCropChanged;
  final Function getPortraitCrop;
  final Function setPortraitCrop;
  final SlyImageAttribute rotation;
  final Function rotate;
  final Function flipImage;

  const SlyGeometryControls({
    super.key,
    this.cropController,
    required this.setCropChanged,
    required this.getPortraitCrop,
    required this.setPortraitCrop,
    required this.rotation,
    required this.rotate,
    required this.flipImage,
  });

  @override
  Widget build(BuildContext context) {
    void onAspectRatioSelected(double? ratio) {
      if ((cropController != null) && (cropController!.aspectRatio != ratio)) {
        setCropChanged(true);
        cropController!.aspectRatio = ratio;
      }
      Navigator.pop(context);
    }

    final buttons = <SlyTooltip>[
      SlyTooltip(
        message: 'Aspect Ratio',
        child: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: const ImageIcon(
            AssetImage('assets/icons/aspect-ratio.webp'),
          ),
          padding: const EdgeInsets.all(12),
          onPressed: () =>
              showSlyDialog(context, 'Select Aspect Ratio', <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SlyToggleButtons(
                defaultItem: getPortraitCrop() ? 1 : 0,
                onSelected: (index) => setPortraitCrop(index == 1),
                children: const <Widget>[
                  Text('Landscape'),
                  Text('Portrait'),
                ],
              ),
            ),
            SlyButton(
              child: const Text('Free'),
              onPressed: () => onAspectRatioSelected(null),
            ),
            SlyButton(
              child: const Text('Square'),
              onPressed: () => onAspectRatioSelected(1),
            ),
            SlyButton(
              child: const Text('4:3'),
              onPressed: () =>
                  onAspectRatioSelected(getPortraitCrop() ? 3 / 4 : 4 / 3),
            ),
            SlyButton(
              child: const Text('3:2'),
              onPressed: () =>
                  onAspectRatioSelected(getPortraitCrop() ? 2 / 3 : 3 / 2),
            ),
            SlyButton(
              child: const Text('16:9'),
              onPressed: () =>
                  onAspectRatioSelected(getPortraitCrop() ? 9 / 16 : 16 / 9),
            ),
            const SlyCancelButton(),
          ]),
        ),
      ),
      SlyTooltip(
        message: 'Rotate Left',
        child: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: const ImageIcon(
            AssetImage('assets/icons/rotate-left.webp'),
          ),
          padding: const EdgeInsets.all(12),
          onPressed: () => rotate(rotation.value - 1),
        ),
      ),
      SlyTooltip(
        message: 'Rotate Right',
        child: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: const ImageIcon(
            AssetImage('assets/icons/rotate-right.webp'),
          ),
          padding: const EdgeInsets.all(12),
          onPressed: () => rotate(rotation.value + 1),
        ),
      ),
      SlyTooltip(
        message: 'Flip Horizontal',
        child: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: const ImageIcon(
            AssetImage('assets/icons/flip-horizontal.webp'),
          ),
          padding: const EdgeInsets.all(12),
          onPressed: () => flipImage(SlyImageFlipDirection.horizontal),
        ),
      ),
      SlyTooltip(
        message: 'Flip Vertical',
        child: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: const ImageIcon(
            AssetImage('assets/icons/flip-vertical.webp'),
          ),
          padding: const EdgeInsets.all(12),
          onPressed: () => flipImage(SlyImageFlipDirection.vertical),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: isWide(context)
          ? Wrap(
              direction: Axis.vertical,
              spacing: 6,
              children: buttons,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: buttons,
            ),
    );
  }
}

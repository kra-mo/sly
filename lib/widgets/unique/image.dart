import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';

import '/platform.dart';
import '/image.dart';
import '/widgets/spinner.dart';

Widget getImageView(
  GlobalKey key,
  BuildContext context,
  BoxConstraints constraints,
  Uint8List? originalImageData,
  Uint8List? editedImageData,
  Function showCropView,
  CropController? cropController,
  ValueChanged<Rect>? onCrop,
  SlyImageAttribute hflip,
  SlyImageAttribute vflip,
  SlyImageAttribute rotation,
) {
  final imageView = AnimatedSize(
    duration: const Duration(seconds: 1),
    curve: Curves.easeOutQuint,
    child: editedImageData != null
        ? InteractiveViewer(
            clipBehavior:
                constraints.maxWidth > 600 ? Clip.none : Clip.hardEdge,
            key: const Key('imageView'),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(6),
              ),
              child: Image.memory(
                editedImageData,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          )
        : SizedBox(
            height: constraints.maxWidth,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: SlySpinner(),
              ),
            ),
          ),
  );

  final cropImageView = originalImageData != null
      ? Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).viewPadding.top,
          ),
          child: CropImage(
            key: const Key('cropImageView'),
            gridThickWidth: constraints.maxWidth > 600 ? 6 : 8,
            gridCornerColor: Theme.of(context).colorScheme.primary,
            gridColor: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            controller: cropController,
            image: Image.memory(
              originalImageData,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
            onCrop: onCrop,
          ),
        )
      : const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: SlySpinner(),
          ),
        );

  return AnimatedPadding(
    key: key,
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutQuint,
    padding: showCropView()
        ? EdgeInsets.only(
            top: platformHasInsetTopBar ? 4 : 12,
            bottom: 12,
            left: 32,
            right: 32,
          )
        : constraints.maxWidth > 600
            ? EdgeInsets.only(
                top: platformHasInsetTopBar ? 0 : 8,
                bottom: 8,
              )
            : const EdgeInsets.only(
                top: 12,
                left: 12,
                right: 12,
              ),
    child: Transform.flip(
      flipX: hflip.value,
      flipY: vflip.value,
      child: RotatedBox(
        quarterTurns: rotation.value,
        child: constraints.maxWidth > 600
            ? showCropView()
                ? cropImageView
                : imageView
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxWidth),
                child: showCropView()
                    ? cropImageView
                    : ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        child: imageView,
                      ),
              ),
      ),
    ),
  );
}

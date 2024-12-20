import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';

import '/platform.dart';
import '/image.dart';
import '/widgets/spinner.dart';
import '/widgets/unique/fullscreen_viewer.dart';

class SlyImageView extends StatelessWidget {
  final Uint8List? originalImageData;
  final Uint8List? editedImageData;
  final CropController? cropController;
  final ValueChanged<Rect>? onCrop;
  final bool wideLayout;
  final Function showCropView;
  final SlyImageAttribute hflip;
  final SlyImageAttribute vflip;
  final SlyImageAttribute rotation;

  const SlyImageView({
    super.key,
    this.originalImageData,
    this.editedImageData,
    this.cropController,
    this.onCrop,
    required this.wideLayout,
    required this.showCropView,
    required this.hflip,
    required this.vflip,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    final imageView = AnimatedSize(
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutQuint,
        child: editedImageData != null
            ? GestureDetector(
                onTap: () => showFullScreenViewer(context, editedImageData!),
                child: InteractiveViewer(
                  clipBehavior: wideLayout ? Clip.none : Clip.hardEdge,
                  key: const Key('imageView'),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(6),
                    ),
                    child: Hero(
                      tag: 'image',
                      child: Image.memory(
                        editedImageData!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: constraints.maxWidth,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SlySpinner(),
                    ),
                  ),
                ),
              ));

    final cropImageView = originalImageData != null
        ? Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).viewPadding.top,
            ),
            child: CropImage(
              key: const Key('cropImageView'),
              gridThickWidth: wideLayout ? 6 : 8,
              gridCornerColor: Theme.of(context).colorScheme.primary,
              gridColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              controller: cropController,
              image: Image.memory(
                originalImageData!,
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
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuint,
      padding: showCropView()
          ? EdgeInsets.only(
              top: platformHasInsetTopBar ? 4 : 12,
              bottom: 12,
              left: 32,
              right: 32,
            )
          : wideLayout
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
          child: wideLayout
              ? showCropView()
                  ? cropImageView
                  : imageView
              : LayoutBuilder(
                  builder: (context, constraints) => ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxWidth),
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
      ),
    );
  }
}

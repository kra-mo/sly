import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_image/crop_image.dart';

import '/platform.dart';
import '/carousel.dart';
import '/image.dart';
import '/views/editor.dart';
import '/widgets/dialog.dart';
import '/widgets/button.dart';
import '/widgets/spinner.dart';
import '/widgets/snack_bar.dart';

Future<void> openImage(
  BuildContext context,
  SlyCarouselProvider? carouselProvider,
  VoidCallback? loadingCallback,
  VoidCallback? failedCallback,
  bool animate,
  int? newSelection,
  (SlyImage, CropController)? currentImage,
) async {
  if (newSelection == null) {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();

    if (files.isEmpty) {
      if (failedCallback != null) failedCallback();
      return;
    }

    if (!context.mounted) {
      if (failedCallback != null) failedCallback();
      return;
    }
    if (loadingCallback != null) loadingCallback();

    final List<SlyImage> images = [];
    for (final file in files) {
      final image = await SlyImage.fromData(await file.readAsBytes());
      if (image == null) {
        if (failedCallback != null) failedCallback();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showSlySnackBar(context, 'Couldn’t Load Image');
        return;
      }

      images.add(image);
    }

    if (!context.mounted) {
      if (failedCallback != null) failedCallback();
      return;
    }

    if (carouselProvider == null) {
      carouselProvider = SlyCarouselProvider(images);
    } else {
      for (final image in images) {
        carouselProvider.addImage(image);
      }
      carouselProvider.selected = 0;
    }
  } else {
    if (currentImage != null && carouselProvider != null) {
      carouselProvider.images[carouselProvider.selected] =
          (carouselProvider.images[carouselProvider.selected].$1, currentImage);

      carouselProvider.selected = newSelection;
    }
  }

  Navigator.pushReplacement(
    context,
    animate
        ? MaterialPageRoute(
            builder: (context) =>
                SlyEditorPage(carouselProvider: carouselProvider!),
          )
        : PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SlyEditorPage(carouselProvider: carouselProvider!),
          ),
  );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

Future<img.Image?> loadImgImage(Uint8List bytes) async {
  final ui.Image? uiImage;
  uiImage = await _decodeUiImage(bytes);
  if (uiImage == null) return _decodeImgImage(bytes);

  final byteData = await uiImage.toByteData();
  if (byteData == null) return _decodeImgImage(bytes);

  return img.Image.fromBytes(
    numChannels: 4,
    width: uiImage.width,
    height: uiImage.height,
    bytes: byteData.buffer,
  );
}

/// Saves the image to the user's gallery on iOS and Android
/// or a user-picked location on desktop or the web.
///
/// Returns false if the operation was cancelled.
Future<bool> saveImage(Uint8List imageData,
    {String fileName = 'Edited Image', String fileExtension = 'png'}) async {
  if (isMobile) {
    await Gal.putImageBytes(imageData, name: fileName);
    return true;
  }

  final FileSaveLocation? result =
      await getSaveLocation(suggestedName: '$fileName.$fileExtension');
  if (result == null) return false;

  XFile.fromData(imageData,
          // An empty string seems to be returned on the web
          name: result.path == '' ? '$fileName.$fileExtension' : null)
      .saveTo(result.path);
  return true;
}

SlyButton getSaveButton(
  GlobalKey<SlyButtonState> key,
  BuildContext context,
  String label,
  Function setImageFormat,
  Function save,
) {
  SlyButton? saveButton;

  void setButtonChild(Widget newChild) {
    if (saveButton == null) return;

    saveButton.setChild(newChild);
  }

  saveButton = SlyButton(
    key: key,
    suggested: true,
    child: Text(label),
    onPressed: () async {
      setButtonChild(
        const Padding(
          padding: EdgeInsets.all(6),
          child: SizedBox(
            width: 24,
            height: 24,
            child: SlySpinner(),
          ),
        ),
      );

      SlyImageFormat? format;

      await showSlyDialog(
        context,
        'Choose a Quality',
        <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SlyButton(
              onPressed: () {
                format = SlyImageFormat.jpeg75;
                Navigator.pop(context);
              },
              child: const Text('For Sharing'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SlyButton(
              onPressed: () {
                format = SlyImageFormat.jpeg90;
                Navigator.pop(context);
              },
              child: const Text('For Storing'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SlyButton(
              onPressed: () {
                format = SlyImageFormat.png;
                Navigator.pop(context);
              },
              child: const Text('Lossless'),
            ),
          ),
          SlyButton(
            suggested: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      );

      // The user cancelled the format selection
      if (format == null) {
        setButtonChild(Text(label));
        return;
      }

      setImageFormat(format!);
      save();
    },
  );

  return saveButton;
}

Future<img.Image?> _decodeImgImage(Uint8List bytes) async {
  try {
    return (await (img.Command()..decodeImage(bytes)).executeThread())
        .outputImage;
  } on img.ImageException {
    return null;
  }
}

Future<ui.Image?> _decodeUiImage(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  } catch (e) {
    return null;
  }
}

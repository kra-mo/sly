import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:file_selector/file_selector.dart';

final isAndroid = !kIsWeb && Platform.isAndroid;
final isIOS = !kIsWeb && Platform.isIOS;
final isLinux = !kIsWeb && Platform.isLinux;
final isMacOS = !kIsWeb && Platform.isMacOS;
final isWindows = !kIsWeb && Platform.isWindows;

final isDesktop = isLinux || isMacOS || isWindows;
final isMobile = isIOS || isAndroid;
final isApplePlatform = isIOS || isMacOS;

final platformHasInsetTopBar = isLinux || isMacOS;
final platformInsetTopBarHeight = isMacOS
    ? 28.0
    : isLinux
        ? 32.0
        : 0.0;
final platformHasRightAlignedWindowControls = isLinux || isWindows;
final platformHasBackGesture = isAndroid;

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

Future<img.Image> getResizedImage(
  img.Image image,
  int? width,
  int? height,
) async {
  final cmd = img.Command()
    ..image(image)
    ..copyResize(
      width: width,
      height: height,
      interpolation: img.Interpolation.average,
    );

  return (await cmd.executeThread()).outputImage!;
}

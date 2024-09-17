import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:file_selector/file_selector.dart';

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
    print(e);
    return null;
  }
}

/// Saves the image to the user's gallery on iOS and Android
/// or a user-picked location on desktop or the web.
///
/// Returns false if the operation was cancelled.
Future<bool> saveImage(Uint8List imageData,
    {String fileName = 'Edited Image', String fileExtension = 'png'}) async {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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

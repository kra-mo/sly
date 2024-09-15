import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:file_selector/file_selector.dart';

Future<img.Image?> loadImage(Uint8List bytes) async {
  var cmd = img.Command()..decodeImage(bytes);

  img.Image? image;

  try {
    image = (await cmd.executeThread()).outputImage;
  } on img.ImageException {
    // We will try loading a ui.Image afterwards
  }

  if (image != null) return image;

  final ui.Image uiImage;

  try {
    uiImage = await _loadUiImage(bytes);
  } catch (e) {
    return null;
  }

  final byteData = await uiImage.toByteData();

  if (byteData == null) {
    throw Exception("Cannot decode image.");
  }

  image = img.Image.fromBytes(
    numChannels: 4,
    width: uiImage.width,
    height: uiImage.height,
    bytes: byteData.buffer,
  );

  return image;
}

Future<ui.Image> _loadUiImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
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

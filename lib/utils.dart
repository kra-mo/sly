import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:file_selector/file_selector.dart';

bool isDesktop() {
  return (!kIsWeb &&
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows));
}

Future<img.Image>? loadImage(Uint8List bytes) async {
  var cmd = img.Command()..decodeImage(bytes);
  var image = (await cmd.executeThread()).outputImage;

  if (image != null) return image;

  final uiImage = await loadUiImage(bytes);
  final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);

  if (byteData == null) {
    throw Exception("Cannot decode image.");
  }

  cmd = img.Command()..decodeImage(byteData.buffer.asUint8List());
  image = (await cmd.executeThread()).outputImage;

  if (image == null) {
    throw Exception("Cannot decode image.");
  }

  return image;
}

Future<ui.Image> loadUiImage(Uint8List bytes) async {
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
  if (!isDesktop() && !kIsWeb) {
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

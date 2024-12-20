import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:file_selector/file_selector.dart';

import '/platform.dart';

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

/// Saves the images to the user's gallery on iOS and Android
/// or a user-picked location on desktop or the web.
///
/// Returns false if the operation was cancelled.
Future<bool> saveImages(
  List<Uint8List> images, {
  List<String?>? fileNames,
  String fileExtension = 'png',
}) async {
  fileNames ??= [];

  if (isMobile) {
    // This is sequential, but the I/O is probably cheap enough
    // for it not to matter.
    for (int index = 0; index < images.length; index++) {
      await Gal.putImageBytes(
        images[0],
        name: fileNames[index] ?? 'Edited Image',
      );
    }

    return true;
  }

  if (images.length == 1 || isWeb) {
    for (int index = 0; index < images.length; index++) {
      final fileName = fileNames[index] ??= 'Edited Image';

      final FileSaveLocation? result =
          await getSaveLocation(suggestedName: '$fileName.$fileExtension');
      if (result == null) {
        if (images.length == 1) return false;
        continue;
      }

      XFile.fromData(images[index],
              // An empty string seems to be returned on the web
              name: result.path == '' ? '$fileName.$fileExtension' : null)
          .saveTo(result.path);
    }
    return true;
  }

  final String? result = await getDirectoryPath();
  if (result == null) return false;

  for (int index = 0; index < images.length; index++) {
    final fileName = '${fileNames[index] ?? 'Edited Image'}.$fileExtension';

    XFile.fromData(
      images[index],
      name: fileName,
    ).saveTo('$result$pathSeparator$fileName');
  }
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

import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;

enum SlyImageFlipDirection { horizontal, vertical, both }

class SlyImageAttribute {
  final String name;
  double value;
  final double anchor;
  final double min;
  final double max;

  SlyImageAttribute(this.name, this.value, this.anchor, this.min, this.max);

  SlyImageAttribute.copy(SlyImageAttribute imageAttribute)
      : this(
          imageAttribute.name,
          imageAttribute.value,
          imageAttribute.anchor,
          imageAttribute.min,
          imageAttribute.max,
        );
}

class SlyImage {
  StreamController<String> controller = StreamController<String>();

  img.Image _originalImage;
  img.Image _image;
  num _editsApplied = 0;
  int _loading = 0;

  Map<String, SlyImageAttribute> lightAttributes = {
    'exposure': SlyImageAttribute('Exposure', 0, 0, 0, 1),
    'brightness': SlyImageAttribute('Brightness', 1, 1, 0.2, 1.8),
    'contrast': SlyImageAttribute('Contrast', 1, 1, 0.4, 1.6),
    'blacks': SlyImageAttribute('Blacks', 0, 0, 0, 127.5),
    'whites': SlyImageAttribute('Whites', 255, 255, 76.5, 255),
    'mids': SlyImageAttribute('Midtones', 127.5, 127.5, 25.5, 229.5),
  };

  Map<String, SlyImageAttribute> colorAttributes = {
    'saturation': SlyImageAttribute('Saturation', 1, 1, 0, 2),
    'temp': SlyImageAttribute('Temperature', 0, 0, -1, 1),
    'tint': SlyImageAttribute('Tint', 0, 0, -1, 1),
    // 'gamma': SlyImageAttribute('Gamma', 1, 1, 0, 2),
    // 'hue': SlyImageAttribute('Hue', 0, 0, 0, 360),
  };

  Map<String, SlyImageAttribute> effectAttributes = {
    'sharpness': SlyImageAttribute('Sharpness', 0, 0, 0, 1),
    'sepia': SlyImageAttribute('Sepia', 0, 0, 0, 1),
    'vignette': SlyImageAttribute('Vignette', 0, 0, 0, 1),
    'border': SlyImageAttribute('Border', 0, 0, -1, 1),
  };

  int get width {
    return _image.width;
  }

  int get height {
    return _image.height;
  }

  bool get loading {
    return _loading > 0;
  }

  /// True if the image is small enough and the device is powerful enough to load it.
  bool get canLoadFullRes {
    return (!kIsWeb && _originalImage.height <= 2000) ||
        _originalImage.height <= 500;
  }

  /// Creates a new `SlyImage` from `image`.
  ///
  /// The `image` object is not reused, so calling `.from`
  /// before invoking this constructor is not necessary.
  SlyImage.fromImage(img.Image original)
      : _image = img.Image.from(original),
        _originalImage = img.Image.from(original);

  /// Creates a new `SlyImage` from another `image`.
  SlyImage.from(SlyImage original)
      : _image = img.Image.from(original._image),
        _originalImage = img.Image.from(original._originalImage);

  /// Applies changes to the image's attrubutes.
  Future<void> applyEdits() async {
    _loading += 1;
    final applied = DateTime.now().millisecondsSinceEpoch;
    _editsApplied = applied;

    final editedImage =
        (await _buildEditCommand(_originalImage).executeThread()).outputImage;

    _loading -= 1;

    if (editedImage == null) return;

    if (_editsApplied > applied) return;

    if (controller.isClosed) return;

    _image = editedImage;
    controller.add('updated');
  }

  /// Applies changes to the image's attrubutes, progressively.
  ///
  /// The edits will first be applied to a <=500px tall thumbnail for fast preview.
  ///
  /// Finally, when ready, the image will be returned at the original size
  /// if the device can render such a large image.
  ///
  /// You can check this with `this.canLoadFullRes`.
  Future<void> applyEditsProgressive() async {
    _loading += 1;
    final applied = DateTime.now().millisecondsSinceEpoch;
    _editsApplied = applied;

    final List<img.Image> images = [];

    if (_originalImage.height > 700 ||
        (kIsWeb && _originalImage.height > 500)) {
      images.add(
        img.copyResize(
          _originalImage,
          height: 500,
          interpolation: img.Interpolation.average,
        ),
      );
    }

    if (canLoadFullRes) {
      images.add(_originalImage);
    } else if (!kIsWeb) {
      images.add(
        img.copyResize(
          _originalImage,
          height: 1500,
          interpolation: img.Interpolation.average,
        ),
      );
    }

    for (img.Image editableImage in images) {
      if (_editsApplied > applied) {
        _loading -= 1;
        return;
      }

      final editedImage =
          (await _buildEditCommand(editableImage).executeThread()).outputImage;
      if (editedImage == null) {
        _loading -= 1;
        return;
      }

      if (_editsApplied > applied) {
        _loading -= 1;
        return;
      }

      if (controller.isClosed) {
        _loading -= 1;
        return;
      }

      _image = editedImage;
      controller.add('updated');
    }

    _loading -= 1;
  }

  /// Copies Exif metadata from `src` to the image.
  void copyMetadataFrom(SlyImage src) {
    _image.exif = img.ExifData.from(src._image.exif);
    _originalImage.exif = img.ExifData.from(src._originalImage.exif);
  }

  /// Removes Exif metadata from the image.
  void removeMetadata() {
    _image.exif = img.ExifData();
    _originalImage.exif = img.ExifData();
  }

  /// Flips the image in `direction`.
  void flip(SlyImageFlipDirection direction) {
    final img.FlipDirection imgFlipDirection;

    switch (direction) {
      case SlyImageFlipDirection.horizontal:
        imgFlipDirection = img.FlipDirection.horizontal;
      case SlyImageFlipDirection.vertical:
        imgFlipDirection = img.FlipDirection.vertical;
      case SlyImageFlipDirection.both:
        imgFlipDirection = img.FlipDirection.both;
    }

    img.flip(_image, direction: imgFlipDirection);
    img.flip(_originalImage, direction: imgFlipDirection);
  }

  /// Rotates the image by `degree`
  void rotate(num degree) {
    if (degree == 360) return;

    _image = img.copyRotate(
      _image,
      angle: degree,
      interpolation: img.Interpolation.cubic,
    );
    _originalImage = img.copyRotate(
      _originalImage,
      angle: degree,
      interpolation: img.Interpolation.cubic,
    );
  }

  /// Returns the image encoded as `format`.
  ///
  /// Available formats are:
  /// - `'PNG'`
  /// - `'JPEG100'` - Quality 100
  /// - `'JPEG'`/`'JPEG90'` - Quality 90
  /// - `'JPEG75'` - 'Quality' 75
  /// - `'TIFF'`
  ///
  /// If `fullRes` is not true, a lower resolution image might be returned
  /// if it looks like the device could not handle loading the entire image.
  ///
  /// You can check this with `this.canLoadFullRes`.
  Future<Uint8List> encode({
    String? format = 'PNG',
    bool fullRes = false,
  }) async {
    if (fullRes && !canLoadFullRes) {
      await applyEdits();
    }

    final cmd = img.Command()..image(_image);

    switch (format) {
      case 'PNG':
        cmd.encodePng();
      case 'JPEG':
        cmd.encodeJpg(quality: 90);
      case 'JPEG100':
        cmd.encodeJpg(quality: 100);
      case 'JPEG90':
        cmd.encodeJpg(quality: 90);
      case 'JPEG75':
        cmd.encodeJpg(quality: 75);
      case 'TIFF':
        cmd.encodeTiff();
      default:
        cmd.encodePng();
    }

    return (await cmd.executeThread()).outputBytes!;
  }

  void dispose() {
    controller.close();
    _editsApplied = double.infinity;
  }

  img.Command _buildEditCommand(editableImage) {
    final exposure = lightAttributes['exposure']!.value;
    final brightness = lightAttributes['brightness']!.value;
    final contrast = lightAttributes['contrast']!.value;
    final saturation = colorAttributes['saturation']!.value;
    final blacks = lightAttributes['blacks']!.value.round();
    final whites = lightAttributes['whites']!.value.round();
    final mids = lightAttributes['mids']!.value.round();

    final red = 50 * colorAttributes['temp']!.value;
    final green = 50 * colorAttributes['tint']!.value * -1;
    final blue = 50 * colorAttributes['temp']!.value * -1;

    final sepia = effectAttributes['sepia']!.value;
    final sharpness = effectAttributes['sharpness']!.value;
    final vignette = effectAttributes['vignette']!.value;
    final border = effectAttributes['border']!.value;

    return img.Command()
      ..image(editableImage)
      ..copy()
      ..adjustColor(
        exposure: exposure,
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        // gamma: colorAttributes['gamma']!.value,
        // hue: colorAttributes['hue']!.value,
        blacks: img.ColorUint8.rgb(blacks, blacks, blacks),
        whites: img.ColorUint8.rgb(whites, whites, whites),
        mids: img.ColorUint8.rgb(mids, mids, mids),
      )
      ..colorOffset(
        red: red,
        green: green,
        blue: blue,
      )
      ..sepia(amount: sepia)
      ..convolution(
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        amount: sharpness,
      )
      ..vignette(amount: vignette)
      ..copyExpandCanvas(
          backgroundColor: border > 0
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0),
          padding: (border.abs() * (editableImage.width / 3)).round());
  }
}

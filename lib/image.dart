import 'dart:typed_data';
import 'dart:math';

import 'package:image/image.dart' as img;

enum SlyImageFlipDirection { horizontal, vertical, both }

class SlyImageAttribute {
  final String name;
  double value;
  final double anchor;
  final double min;
  final double max;

  SlyImageAttribute(this.name, this.value, this.anchor, this.min, this.max);
}

class SlyImage {
  final img.Image _originalImage;
  img.Image image;

  Map<String, SlyImageAttribute> lightAttributes = {
    'exposure': SlyImageAttribute('Exposure', 0, 0, 0, 1),
    'brightness': SlyImageAttribute('Brightness', 1, 1, 0.2, 1.8),
    'contrast': SlyImageAttribute('Contrast', 1, 1, 0.4, 1.6),
    'blacks': SlyImageAttribute('Blacks', 0, 0, 0, 0.5),
    'whites': SlyImageAttribute('Whites', 1, 1, 0.3, 1),
    'mids': SlyImageAttribute('Midtones', 0.5, 0.5, 0.1, 0.9),
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
    return image.width;
  }

  int get height {
    return image.height;
  }

  /// Creates a new `SlyImage` from `image`.
  ///
  /// The `image` object is not reused, so calling `.from`
  /// before invoking this constructor is not necessary.
  SlyImage.fromImage(img.Image original)
      : image = img.Image.from(original),
        _originalImage = img.Image.from(original);

  /// Creates a new `SlyImage` from another `image`.
  SlyImage.from(SlyImage original)
      : image = img.Image.from(original.image),
        _originalImage = img.Image.from(original._originalImage);

  /// Returns a lower resolution `SlyImage` to be used as a thumbnail.
  ///
  /// Note that the thumbnail does not necessarily take up less storage space,
  /// but should be faster to load.
  ///
  /// If the image is already low resolution, the image will likely be identical.
  SlyImage getThumbnail() {
    return SlyImage.fromImage(
      img.copyResize(image,
          width: min(image.height, 500),
          interpolation: img.Interpolation.average),
    );
  }

  /// Applies changes to the image's attrubutes.
  Future<void> applyEdits() async {
    int blacks = (255 * lightAttributes['blacks']!.value).toInt();
    int whites = (255 * lightAttributes['whites']!.value).toInt();
    int mids = (255 * lightAttributes['mids']!.value).toInt();

    final cmd = img.Command()
      ..image(_originalImage)
      ..copy()
      ..adjustColor(
        exposure: lightAttributes['exposure']!.value,
        brightness: lightAttributes['brightness']!.value,
        contrast: lightAttributes['contrast']!.value,
        saturation: colorAttributes['saturation']!.value,
        // gamma: colorAttributes['gamma']!.value,
        // hue: colorAttributes['hue']!.value,
        blacks: img.ColorUint8.rgb(blacks, blacks, blacks),
        whites: img.ColorUint8.rgb(whites, whites, whites),
        mids: img.ColorUint8.rgb(mids, mids, mids),
      )
      ..colorOffset(
        red: 50 * colorAttributes['temp']!.value,
        green: 50 * colorAttributes['tint']!.value * -1,
        blue: 50 * colorAttributes['temp']!.value * -1,
      )
      ..sepia(amount: effectAttributes['sepia']!.value)
      ..convolution(
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        amount: effectAttributes['sharpness']!.value,
      )
      ..vignette(amount: effectAttributes['vignette']!.value)
      ..copyExpandCanvas(
          backgroundColor: effectAttributes['border']!.value > 0
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0),
          padding: (effectAttributes['border']!.value.abs() *
                  (_originalImage.width / 3))
              .toInt());

    final editedImage = (await cmd.executeThread()).outputImage;
    if (editedImage == null) return;

    image = editedImage;
  }

  /// Removes EXIF metadata from the image.
  void removeMetadata() {
    image.exif = img.ExifData();
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

    img.flip(image, direction: imgFlipDirection);
    img.flip(_originalImage, direction: imgFlipDirection);
  }

  /// Returns the image encoded as `format`.
  ///
  /// Available formats are:
  /// - `'PNG'`
  /// - `'JPEG100'` - Quality 100
  /// - `'JPEG'`/`'JPEG90'` - Quality 90
  /// - `'JPEG75'` - 'Quality' 75
  /// - `'TIFF'`
  Future<Uint8List> encode({String? format = 'PNG'}) async {
    final cmd = img.Command()..image(image);

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
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';

import '/image.dart';
import '/widgets/spinner.dart';

class SlyCarouselProvider {
  final List<(SlyImage, (SlyImage, CropController)?)> images = [];
  int selected = 0;

  SlyImage get originalImage => images[selected].$1;
  SlyImage? get editedImage => images[selected].$2?.$1;
  CropController? get cropController => images[selected].$2?.$2;

  late final List<Widget> children = [
    const ImageIcon(
      AssetImage('assets/icons/add.png'),
      semanticLabel: 'Add Images',
    ),
  ];

  void addImage(SlyImage image) {
    images.insert(0, (image, null));
    children.insert(
      1,
      FutureBuilder<Uint8List>(
        future: image.encode(
          format: SlyImageFormat.jpeg75,
          maxSideLength: 150,
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          } else if (snapshot.hasError) {
            return Container();
          } else {
            return const SlySpinner();
          }
        },
      ),
    );
  }

  SlyCarouselProvider(images) {
    for (final image in images) {
      addImage(image);
    }
  }
}

import 'package:flutter/material.dart';

import '/image.dart';

class SlyCarouselProvider {
  final List<SlyImage> images = [];
  int selected = 0;
  BuildContext context;

  get selectedImage => images[selected];

  late final List<Widget> children = [
    const ImageIcon(
      AssetImage('assets/icons/add.png'),
      semanticLabel: 'Add Images',
    ),
  ];

  addImage(SlyImage image) async {
    images.insert(0, image);

    final bytes = await image.encode(
      format: SlyImageFormat.jpeg75,
      maxSideLength: 150,
    );

    final index = images.indexOf(image) + 1;
    if (index > children.length) {
      children.add(Image.memory(bytes, fit: BoxFit.cover));
    } else {
      children.insert(
        index,
        Image.memory(bytes, fit: BoxFit.cover),
      );
    }
  }

  SlyCarouselProvider(this.context, images) {
    for (final image in images) {
      addImage(image);
    }
  }
}

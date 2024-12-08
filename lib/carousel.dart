import 'package:flutter/material.dart';

import '/image.dart';

class SlyCarouselProvider {
  BuildContext context;
  final List<SlyImage> images;

  late final List<Widget> children = [
    const ImageIcon(
      AssetImage('assets/icons/add.png'),
      semanticLabel: 'Add Image',
    ),
  ];

  addImage(SlyImage image) async {
    final bytes = await image.encode(
      format: SlyImageFormat.jpeg75,
      maxSideLength: 150,
    );
    children.add(
      Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  SlyCarouselProvider(this.context, this.images) {
    for (final image in images) {
      addImage(image);
    }
  }
}

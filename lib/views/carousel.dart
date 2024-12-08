import 'package:flutter/material.dart';

import '/image.dart';
import '/carousel.dart';
import '/views/editor.dart';

Widget getImageCarousel(
  BuildContext context,
  BoxConstraints constraints,
  GlobalKey key,
  Function getShowCarousel,
  SlyCarouselProvider carouselProvider,
  Function pickNewImage,
  Function getEditedImage,
  Function getCropController,
) {
  return AnimatedSize(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutQuint,
    child: getShowCarousel()
        ? Container(
            color: constraints.maxWidth > 600
                ? null
                : Theme.of(context).hoverColor,
            child: AnimatedPadding(
              key: key,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuint,
              padding: EdgeInsets.only(
                bottom: constraints.maxWidth > 600 ? 12 : 3,
              ),
              child: SizedBox(
                height: 75,
                child: CarouselView(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.focused)
                        ? Theme.of(context).hoverColor
                        : Colors.transparent;
                  }),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                  ),
                  itemExtent: 75,
                  children: carouselProvider.children,
                  onTap: (int index) {
                    if (index == 0) {
                      pickNewImage();
                    } else {
                      carouselProvider.images[carouselProvider.selected] = (
                        carouselProvider.images[carouselProvider.selected].$1,
                        // TODO: Reuse the object
                        (SlyImage.from(getEditedImage()), getCropController())
                      );

                      carouselProvider.selected = index - 1;

                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  SlyEditorPage(
                            suggestedFileName: 'Edited Image',
                            carouselProvider: carouselProvider,
                            showCarousel: true,
                          ),
                        ),
                      );

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  },
                ),
              ),
            ),
          )
        : Container(),
  );
}

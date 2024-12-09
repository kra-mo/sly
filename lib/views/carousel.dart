import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '/image.dart';
import '/views/editor.dart';
import '/widgets/snack_bar.dart';

class SlyImageCarousel extends StatefulWidget {
  const SlyImageCarousel({super.key});

  @override
  State<SlyImageCarousel> createState() => _SlyImageCarouselState();
}

class _SlyImageCarouselState extends State<SlyImageCarousel> {
  final GlobalKey _animatedPaddingKey = GlobalKey();

  @override
  build(BuildContext context) {
    final data = CarouselData.of(context).data;
    final visible = data.$1;
    final wideLayout = data.$2;
    final provider = data.$3;
    final editedImage = data.$4;
    final cropController = data.$5;

    pickNewImage() async {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isEmpty) return;
      if (!context.mounted) return;

      showSlySnackBar(context, 'Loading Image', loading: true);

      final List<SlyImage> images = [];

      for (final file in files) {
        final image = await SlyImage.fromData(await file.readAsBytes());
        if (image == null) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showSlySnackBar(context, 'Couldn’t Load Image');
          return;
        }

        images.add(image);
      }

      if (!context.mounted) return;

      for (final image in images) {
        provider.addImage(image);
      }
      provider.selected = 0;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SlyEditorPage(
            suggestedFileName: 'Edited Image',
            carouselProvider: provider,
          ),
        ),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      child: visible
          ? Container(
              color: wideLayout ? null : Theme.of(context).hoverColor,
              child: AnimatedPadding(
                key: _animatedPaddingKey,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuint,
                padding: EdgeInsets.only(
                  bottom: wideLayout ? 12 : 3,
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
                    children: provider.children,
                    onTap: (int index) {
                      if (index == 0) {
                        pickNewImage();
                      } else {
                        if (cropController != null) {
                          provider.images[provider.selected] = (
                            provider.images[provider.selected].$1,
                            // TODO: Reuse the object
                            (SlyImage.from(editedImage), cropController)
                          );
                        }

                        provider.selected = index - 1;

                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SlyEditorPage(
                              suggestedFileName: 'Edited Image',
                              carouselProvider: provider,
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
}

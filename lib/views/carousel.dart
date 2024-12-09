import 'package:flutter/material.dart';

import '/io.dart';
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
                        openImage(
                          context,
                          provider,
                          () => showSlySnackBar(
                            context,
                            'Loading Image',
                            loading: true,
                          ),
                          null,
                          true,
                          null,
                          null,
                        );
                      } else {
                        if (cropController != null) {
                          openImage(
                            context,
                            provider,
                            null,
                            null,
                            false,
                            index - 1,
                            // TODO: Reuse the object
                            (SlyImage.from(editedImage), cropController),
                          );
                        }
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

import 'package:flutter/material.dart';

import '/juggler.dart';
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
    final juggler = data.$3;

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
                    children: juggler.carouselChildren,
                    onTap: (int index) {
                      if (index == 0) {
                        editImages(
                          context,
                          juggler,
                          () => showSlySnackBar(
                            context,
                            'Loading Image',
                            loading: true,
                          ),
                          null,
                          true,
                          null,
                        );
                      } else {
                        editImages(
                          context,
                          juggler,
                          null,
                          null,
                          false,
                          index - 1,
                        );
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

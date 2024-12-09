import 'package:flutter/material.dart';

import '/widgets/snack_bar.dart';
import '/widgets/unique/editor.dart';

class SlyImageCarousel extends StatefulWidget {
  const SlyImageCarousel({super.key});

  @override
  State<SlyImageCarousel> createState() => _SlyImageCarouselState();
}

class _SlyImageCarouselState extends State<SlyImageCarousel> {
  @override
  build(BuildContext context) {
    final data = CarouselData.of(context).data;
    final visible = data.$1;
    final wideLayout = data.$2;
    final juggler = data.$3;
    final globalKey = data.$4;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      child: visible
          ? Container(
              color: wideLayout ? null : Theme.of(context).hoverColor,
              child: AnimatedPadding(
                key: globalKey,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuint,
                padding: EdgeInsets.only(bottom: wideLayout ? 12 : 3, left: 8),
                child: SizedBox(
                  height: 75,
                  child: CarouselView(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                      left: 4,
                      right: 4,
                    ),
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.focused)
                          ? Theme.of(context).hoverColor
                          : Colors.transparent;
                    }),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    itemExtent: 75,
                    children: juggler.carouselChildren,
                    onTap: (int index) {
                      if (index == 0) {
                        juggler.editImages(
                          context: context,
                          loadingCallback: () => showSlySnackBar(
                            context,
                            'Loading Image',
                            loading: true,
                          ),
                        );
                      } else {
                        juggler.editImages(
                          context: context,
                          newSelection: index - 1,
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

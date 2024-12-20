import 'package:flutter/material.dart';
import 'package:sly/widgets/button.dart';
import 'package:sly/widgets/dialog.dart';

import '/widgets/snack_bar.dart';
import '/widgets/tooltip.dart';
import '/juggler.dart';

class SlyCarouselData extends InheritedWidget {
  final (bool, bool, SlyJuggler, GlobalKey, VoidCallback?) data;

  const SlyCarouselData({
    super.key,
    required this.data,
    required super.child,
  });

  static SlyCarouselData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlyCarouselData>();
  }

  static SlyCarouselData of(BuildContext context) {
    final SlyCarouselData? result = maybeOf(context);
    return result!;
  }

  @override
  bool updateShouldNotify(SlyCarouselData oldWidget) => data != oldWidget.data;
}

class SlyImageCarousel extends StatefulWidget {
  const SlyImageCarousel({super.key});

  @override
  State<SlyImageCarousel> createState() => _SlyImageCarouselState();
}

class _SlyImageCarouselState extends State<SlyImageCarousel> {
  @override
  build(BuildContext context) {
    final data = SlyCarouselData.of(context).data;
    final visible = data.$1;
    final wideLayout = data.$2;
    final juggler = data.$3;
    final globalKey = data.$4;
    final exportAll = data.$5;

    final buttonStyle = IconButton.styleFrom(
      backgroundColor: wideLayout
          ? Theme.of(context).brightness == Brightness.light
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.8)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );

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
                  child: Row(spacing: 4, children: [
                    Column(spacing: 4, children: [
                      SlyTooltip(
                        message: 'Add Image',
                        child: IconButton(
                          visualDensity: const VisualDensity(
                            vertical: -2,
                            horizontal: -2,
                          ),
                          padding: const EdgeInsets.all(0),
                          style: buttonStyle,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          icon: const ImageIcon(AssetImage(
                            'assets/icons/add.webp',
                          )),
                          onPressed: () {
                            juggler.editImages(
                              context: context,
                              loadingCallback: () => showSlySnackBar(
                                context,
                                'Loading',
                                loading: true,
                              ),
                            );
                          },
                        ),
                      ),
                      SlyTooltip(
                        message: 'Image Options',
                        child: IconButton(
                          visualDensity: const VisualDensity(
                            vertical: -2,
                            horizontal: -2,
                          ),
                          padding: const EdgeInsets.all(0),
                          style: buttonStyle,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          icon: const ImageIcon(AssetImage(
                            'assets/icons/cog.webp',
                          )),
                          onPressed: () =>
                              showSlyDialog(context, 'Image Options', [
                            juggler.images.length > 1
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SlyButton(
                                      onPressed: () {
                                        juggler.remove(juggler.selected);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Remove'),
                                    ),
                                  )
                                : Container(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SlyButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (exportAll != null) exportAll();
                                },
                                child: const Text('Save All'),
                              ),
                            ),
                            SlyButton(
                              suggested: true,
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            )
                          ]),
                        ),
                      ),
                    ]),
                    Expanded(
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
                          if (juggler.selected == index) return;

                          juggler.editImages(
                            context: context,
                            newSelection: index,
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            )
          : Container(),
    );
  }
}

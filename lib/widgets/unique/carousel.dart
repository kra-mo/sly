import 'package:flutter/material.dart';
import 'package:sly/widgets/button.dart';
import 'package:sly/widgets/dialog.dart';

import '/layout.dart';
import '/juggler.dart';
import '/widgets/snack_bar.dart';
import '/widgets/tooltip.dart';

class SlyImageCarousel extends StatefulWidget {
  final bool visible;
  final SlyJuggler juggler;
  final GlobalKey globalKey;

  const SlyImageCarousel({
    required this.visible,
    required this.juggler,
    required this.globalKey,
    super.key,
  });

  @override
  State<SlyImageCarousel> createState() => _SlyImageCarouselState();
}

class _SlyImageCarouselState extends State<SlyImageCarousel> {
  @override
  build(BuildContext context) {
    final juggler = widget.juggler;

    final buttonStyle = IconButton.styleFrom(
      backgroundColor: isWide(context)
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
      child: widget.visible
          ? Container(
              color: isWide(context) ? null : Theme.of(context).hoverColor,
              child: AnimatedPadding(
                key: widget.globalKey,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuint,
                padding:
                    EdgeInsets.only(bottom: isWide(context) ? 12 : 3, left: 8),
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
                          onPressed: () => juggler.editImages(
                            context: context,
                            loadingCallback: () => showSlySnackBar(
                              context,
                              'Loading',
                              loading: true,
                            ),
                          ),
                        ),
                      ),
                      SlyTooltip(
                        message: 'Remove Image',
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
                            'assets/icons/delete.webp',
                          )),
                          onPressed: () =>
                              showSlyDialog(context, 'Remove Image?', [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 240),
                                child: const Text(
                                  'The original will not be deleted, but unsaved edits will be lost.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SlyButton(
                              onPressed: () {
                                juggler.remove(juggler.selected);
                                Navigator.pop(context);
                              },
                              child: const Text('Remove'),
                            ),
                            const SlyCancelButton(),
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

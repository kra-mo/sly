import 'package:flutter/material.dart';

import '/widgets/title_bar.dart';

class SlyEditorScaffold extends StatelessWidget {
  final Widget imageView;
  final Widget controlsView;
  final Widget toolbar;
  final Widget histogram;
  final Widget navigationRail;
  final Widget navigationBar;
  final Widget imageCarousel;
  final bool showCarousel;
  final int selectedPageIndex;
  final VoidCallback? toggleCarousel;

  const SlyEditorScaffold({
    super.key,
    required this.imageView,
    required this.controlsView,
    required this.toolbar,
    required this.histogram,
    required this.navigationRail,
    required this.navigationBar,
    required this.imageCarousel,
    required this.showCarousel,
    required this.selectedPageIndex,
    this.toggleCarousel,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth > 600
            ? Scaffold(
                floatingActionButtonAnimator:
                    FloatingActionButtonAnimator.noAnimation,
                floatingActionButtonLocation: constraints.maxHeight > 380
                    ? null
                    : FloatingActionButtonLocation.startFloat,
                floatingActionButton: AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuint,
                  padding: constraints.maxHeight <= 380 && showCarousel
                      ? const EdgeInsets.only(
                          top: 3, bottom: 80, left: 3, right: 3)
                      : const EdgeInsets.all(3),
                  child: Semantics(
                    label: 'More Images',
                    child: FloatingActionButton.small(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      backgroundColor: constraints.maxHeight > 380
                          ? Theme.of(context).focusColor
                          : Colors.black87,
                      foregroundColor: constraints.maxHeight > 380
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                      focusColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      hoverColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      splashColor: Colors.transparent,
                      elevation: 0,
                      hoverElevation: 0,
                      focusElevation: 0,
                      disabledElevation: 0,
                      highlightElevation: 0,
                      onPressed: toggleCarousel,
                      child: AnimatedRotation(
                        turns: showCarousel ? 1 / 8 : 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: const ImageIcon(
                            AssetImage('assets/icons/add.webp')),
                      ),
                    ),
                  ),
                ),
                body: Container(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Colors.black,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            SlyDragWindowBox(
                              child: SlyTitleBarBox(
                                child: Container(),
                              ),
                            ),
                            Expanded(child: imageView),
                            imageCarousel,
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              selectedPageIndex == 3 ? double.infinity : 250,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: Container(
                                  color: Theme.of(context).cardColor,
                                  child: AnimatedSize(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeOutQuint,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SlyDragWindowBox(
                                          child: SlyTitleBarBox(
                                            child: Container(),
                                          ),
                                        ),
                                        selectedPageIndex == 3
                                            ? Container()
                                            : histogram,
                                        Expanded(child: controlsView),
                                        selectedPageIndex != 3 &&
                                                selectedPageIndex != 4
                                            ? toolbar
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: Theme.of(context).cardColor,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: SlyDragWindowBox(
                            child: Container(
                              color: Theme.of(context).hoverColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  const SlyTitleBar(),
                                  Expanded(
                                    child: navigationRail,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Scaffold(
                body: Column(
                  children: <Widget>[
                    const SlyTitleBar(),
                    Expanded(
                      child: selectedPageIndex == 3
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(child: imageView),
                                controlsView,
                              ],
                            )
                          : ListView(
                              children: selectedPageIndex == 4
                                  ? <Widget>[
                                      imageView,
                                      controlsView,
                                    ]
                                  : <Widget>[
                                      imageView,
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [toolbar, histogram],
                                      ),
                                      controlsView,
                                    ],
                            ),
                    ),
                  ],
                ),
                bottomNavigationBar: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      navigationBar,
                      imageCarousel,
                    ],
                  ),
                ),
              ),
      );
}

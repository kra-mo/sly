import 'package:flutter/material.dart';

import '/widgets/title_bar.dart';

Scaffold getEditorScaffold(
  BuildContext context,
  BoxConstraints constraints,
  Widget imageView,
  Widget controlsView,
  Widget cropControls,
  Widget toolbar,
  Widget histogram,
  NavigationRail navigationRail,
  NavigationBar navigationBar,
  Function getSelectedPageIndex,
  VoidCallback? newImage,
) {
  if (constraints.maxWidth > 600) {
    return Scaffold(
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonLocation: constraints.maxHeight > 380
          ? null
          : FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(3),
        child: Semantics(
          label: 'New Image',
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
            focusColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            splashColor: Colors.transparent,
            elevation: 0,
            hoverElevation: 0,
            focusElevation: 0,
            disabledElevation: 0,
            highlightElevation: 0,
            onPressed: newImage,
            child: const ImageIcon(AssetImage('assets/icons/add.png')),
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
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: getSelectedPageIndex() == 3 ? double.infinity : 250,
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
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SlyDragWindowBox(
                                child: SlyTitleBarBox(
                                  child: Container(),
                                ),
                              ),
                              getSelectedPageIndex() == 3
                                  ? Container()
                                  : histogram,
                              Expanded(child: controlsView),
                              getSelectedPageIndex() != 3 &&
                                      getSelectedPageIndex() != 4
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
    );
  } else {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const SlyTitleBar(),
          Expanded(
            child: getSelectedPageIndex() == 3
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(child: imageView),
                      cropControls,
                    ],
                  )
                : ListView(
                    children: getSelectedPageIndex() == 4
                        ? <Widget>[
                            imageView,
                            controlsView,
                          ]
                        : <Widget>[
                            imageView,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
        child: navigationBar,
      ),
    );
  }
}

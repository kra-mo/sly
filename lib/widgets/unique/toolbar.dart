import 'package:flutter/material.dart';

import '/history.dart';
import '/preferences.dart';
import '/widgets/tooltip.dart';

class SlyToolbar extends StatelessWidget {
  final bool wideLayout;
  final HistoryManager history;
  final Function pageHasHistogram;
  final Function getShowHistogram;
  final Function setShowHistogram;
  final VoidCallback? showOriginal;

  const SlyToolbar({
    super.key,
    required this.wideLayout,
    required this.history,
    required this.pageHasHistogram,
    required this.getShowHistogram,
    required this.setShowHistogram,
    required this.showOriginal,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: wideLayout
            ? const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 4,
                bottom: 12,
              )
            : const EdgeInsets.only(
                left: 4,
                right: 4,
                top: 8,
                bottom: 0,
              ),
        child: Wrap(
          alignment: wideLayout ? WrapAlignment.start : WrapAlignment.center,
          children: <Widget?>[
            pageHasHistogram()
                ? SlyTooltip(
                    message: getShowHistogram()
                        ? 'Hide Histogram'
                        : 'Show Histogram',
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: ImageIcon(
                        color: Theme.of(context).hintColor,
                        const AssetImage('assets/icons/histogram.webp'),
                      ),
                      onPressed: () async {
                        await (await prefs)
                            .setBool('showHistogram', !getShowHistogram());

                        setShowHistogram(!getShowHistogram());
                      },
                    ),
                  )
                : null,
            SlyTooltip(
              message: 'Show Original',
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: ImageIcon(
                  color: Theme.of(context).hintColor,
                  const AssetImage('assets/icons/show.webp'),
                ),
                onPressed: showOriginal,
              ),
            ),
            SlyTooltip(
              message: 'Undo',
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: ImageIcon(
                  color: history.canUndo
                      ? Theme.of(context).hintColor
                      : Theme.of(context).disabledColor,
                  const AssetImage('assets/icons/undo.webp'),
                ),
                onPressed: () {
                  history.undo();
                },
              ),
            ),
            SlyTooltip(
              message: 'Redo',
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: ImageIcon(
                  color: history.canRedo
                      ? Theme.of(context).hintColor
                      : Theme.of(context).disabledColor,
                  const AssetImage('assets/icons/redo.webp'),
                ),
                onPressed: () {
                  history.redo();
                },
              ),
            ),
          ].whereType<Widget>().toList(),
        ),
      );
}

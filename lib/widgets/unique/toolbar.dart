import 'package:flutter/material.dart';

import '/history.dart';
import '/preferences.dart';
import '/widgets/tooltip.dart';

Widget getToolbar(
  BuildContext context,
  BoxConstraints constraints,
  HistoryManager history,
  Function pageHasHistogram,
  Function getShowHistogram,
  Function setShowHistogram,
  VoidCallback? showOriginal,
) {
  return Padding(
    padding: constraints.maxWidth > 600
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
      alignment: constraints.maxWidth > 600
          ? WrapAlignment.start
          : WrapAlignment.center,
      children: <Widget?>[
        pageHasHistogram()
            ? SlyTooltip(
                message:
                    getShowHistogram() ? 'Hide Histogram' : 'Show Histogram',
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: ImageIcon(
                    color: Theme.of(context).hintColor,
                    const AssetImage('assets/icons/histogram.png'),
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
              const AssetImage('assets/icons/show.png'),
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
              const AssetImage('assets/icons/undo.png'),
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
              const AssetImage('assets/icons/redo.png'),
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

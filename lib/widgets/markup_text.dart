import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:url_launcher/url_launcher.dart';

enum SlyMarkupSegmentType { regular, hyper }

class SlyMarkupText extends StatelessWidget {
  final String text;
  final List<VoidCallback>? callbacks;

  /// A simple widget to render text with limited markdown support
  /// (hyperlinks and headings).
  ///
  /// You can optionally pass a list of actions
  /// to be called upon tapping `slycallback://[index]` URIs,
  /// where `[index]` is the index of the action in `callbacks`.
  const SlyMarkupText(this.text, {this.callbacks, super.key});

  @override
  Widget build(BuildContext context) => Column(
        spacing: 16,
        children: getParagraphsForMarkup(context, text),
      );

  List<Widget> getParagraphsForMarkup(BuildContext context, String markup) {
    final widgets = <Widget>[];

    markup.trim().split('\n\n').forEach((p) {
      TextStyle? style = Theme.of(context).textTheme.bodyMedium;

      for (final h in {
        '#': Theme.of(context).textTheme.headlineLarge,
        '##': Theme.of(context).textTheme.headlineMedium,
        '###': Theme.of(context).textTheme.headlineSmall,
        '####': Theme.of(context).textTheme.titleLarge,
        '#####': Theme.of(context).textTheme.titleMedium,
        '######': Theme.of(context).textTheme.titleSmall,
      }.entries) {
        if (p.startsWith('${h.key} ')) {
          p = p.replaceFirst(h.key, '');
          style = h.value;
        }
      }

      final children = <TextSpan>[];

      String curr = '';
      String? hyper = '';
      bool startBrackets = false;
      bool endBrackets = false;
      bool inParens = false;
      bool escape = false;

      void newSegment(SlyMarkupSegmentType type, {String? hyper}) {
        switch (type) {
          case SlyMarkupSegmentType.regular:
            children.add(TextSpan(text: curr));
          case SlyMarkupSegmentType.hyper:
            final uri = Uri.parse(curr);

            if (hyper != null && hyper != '') {
              children.add(
                TextSpan(
                  text: hyper,
                  style: const TextStyle(
                    color: Colors.deepOrangeAccent,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>
                        uri.scheme != 'slycallback' || callbacks == null
                            ? launchUrl(uri)
                            : callbacks![int.parse(uri.host)](),
                ),
              );
            }
            hyper = '';
        }

        curr = '';
      }

      p.split('').forEach((char) {
        if (escape) {
          curr += char;
          escape = false;
          return;
        }

        switch (char) {
          case '\n':
            curr += ' ';
          case '\\':
            escape = true;
          case '[':
            if (startBrackets) {
              curr = '[$curr';
              newSegment(SlyMarkupSegmentType.regular);
            } else if (endBrackets) {
              endBrackets = false;
              curr = '[$curr]';
              newSegment(SlyMarkupSegmentType.regular);
              curr += char;
            } else if (inParens) {
              curr += char;
            } else {
              newSegment(SlyMarkupSegmentType.regular);
              startBrackets = true;
            }
          case ']':
            if (startBrackets) {
              startBrackets = false;
              endBrackets = true;
            } else {
              curr += char;
            }
          case '(':
            if (endBrackets) {
              endBrackets = false;
              inParens = true;
              hyper = curr;
              curr = '';
            } else {
              curr += char;
            }
          case ')':
            if (inParens) {
              inParens = false;
              newSegment(SlyMarkupSegmentType.hyper, hyper: hyper);
            } else {
              curr += char;
            }
          default:
            curr += char;
        }
      });

      newSegment(SlyMarkupSegmentType.regular);

      widgets.add(RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: style,
            children: children,
          )));
    });

    return widgets;
  }
}

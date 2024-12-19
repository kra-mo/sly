import 'package:flutter/material.dart';

import '/image.dart';
import '/widgets/dialog.dart';
import '/widgets/button.dart';
import '/widgets/spinner.dart';

class SlySaveButton extends StatefulWidget {
  final String label;
  final Function setImageFormat;
  final Function save;

  const SlySaveButton({
    super.key,
    required this.label,
    required this.setImageFormat,
    required this.save,
  });

  void setChild(Widget newChild) {
    if (key is GlobalKey<SlySaveButtonState>) {
      final state = (key as GlobalKey<SlySaveButtonState>).currentState;
      state?.setButtonChild(newChild);
    }
  }

  @override
  State<SlySaveButton> createState() => SlySaveButtonState();
}

class SlySaveButtonState extends State<SlySaveButton> {
  final _buttonKey = GlobalKey<SlyButtonState>();
  late SlyButton saveButton;

  void setButtonChild(Widget newChild) {
    saveButton.setChild(newChild);
  }

  @override
  Widget build(BuildContext context) {
    saveButton = SlyButton(
      key: _buttonKey,
      suggested: true,
      child: Text(widget.label),
      onPressed: () async {
        setButtonChild(
          const Padding(
            padding: EdgeInsets.all(6),
            child: SizedBox(
              width: 24,
              height: 24,
              child: SlySpinner(),
            ),
          ),
        );

        SlyImageFormat? format;

        await showSlyDialog(
          context,
          'Choose a Quality',
          <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SlyButton(
                onPressed: () {
                  format = SlyImageFormat.jpeg75;
                  Navigator.pop(context);
                },
                child: const Text('For Sharing'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SlyButton(
                onPressed: () {
                  format = SlyImageFormat.jpeg90;
                  Navigator.pop(context);
                },
                child: const Text('For Storing'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SlyButton(
                onPressed: () {
                  format = SlyImageFormat.png;
                  Navigator.pop(context);
                },
                child: const Text('Lossless'),
              ),
            ),
            SlyButton(
              suggested: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );

        // The user cancelled the format selection
        if (format == null) {
          setButtonChild(Text(widget.label));
          return;
        }

        widget.setImageFormat(format!);
        widget.save();
      },
    );

    return saveButton;
  }
}

import 'package:flutter/material.dart';

import '/widgets/button.dart';

class SlySaveButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const SlySaveButton({
    super.key,
    required this.label,
    this.onPressed,
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
      onPressed: widget.onPressed,
      child: Text(widget.label),
    );

    return saveButton;
  }
}

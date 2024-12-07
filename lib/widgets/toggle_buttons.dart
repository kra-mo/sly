import 'package:flutter/material.dart';

class SlyToggleButtons extends StatefulWidget {
  const SlyToggleButtons({
    super.key,
    required this.defaultItem,
    required this.children,
    required this.onSelected,
    this.compact = false,
  });

  final int defaultItem;
  final List<Widget> children;
  final void Function(int) onSelected;
  final bool compact;

  @override
  State<SlyToggleButtons> createState() => _SlyToggleButtonsState();
}

class _SlyToggleButtonsState extends State<SlyToggleButtons> {
  bool value = false;
  final List<bool> selections = [];

  @override
  void initState() {
    for (Widget _ in widget.children) {
      selections.add(false);
    }

    selections[widget.defaultItem] = true;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ToggleButtons(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.all(
          Radius.circular(widget.compact ? 14 : 12),
        ),
        borderWidth: 3,
        constraints: BoxConstraints(
          minHeight: widget.compact ? 28 : 34,
          minWidth: widget.compact ? 80 : 120,
        ),
        isSelected: selections,
        children: widget.children,
        onPressed: (int index) {
          for (int i = 0; i < selections.length; i++) {
            setState(() => selections[i] = false);
          }
          setState(() => selections[index] = true);

          widget.onSelected(index);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SlyToggleButtons extends StatefulWidget {
  const SlyToggleButtons({
    super.key,
    required this.defaultItem,
    required this.children,
    required this.onSelected,
  });

  final int defaultItem;
  final List<Widget> children;
  final void Function(int) onSelected;

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
        disabledColor: Colors.grey.shade600,
        color: Colors.white70,
        selectedColor: Colors.white,
        fillColor: Colors.white12,
        selectedBorderColor: Colors.white12,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderWidth: 2,
        constraints: const BoxConstraints(minHeight: 32, minWidth: 120),
        isSelected: selections,
        children: widget.children,
        onPressed: (int index) {
          for (int i = 0; i < selections.length; i++) {
            setState(() {
              selections[i] = false;
            });
          }
          setState(() {
            selections[index] = true;
          });

          widget.onSelected(index);
        },
      ),
    );
  }
}

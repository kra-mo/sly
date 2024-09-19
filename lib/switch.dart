import 'package:flutter/material.dart';

class SlySwitch extends StatefulWidget {
  const SlySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final void Function(bool)? onChanged;

  @override
  State<SlySwitch> createState() => _SlySwitchState();
}

class _SlySwitchState extends State<SlySwitch> {
  bool value = false;

  @override
  void initState() {
    value = widget.value;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbColor:
          WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
      inactiveTrackColor: Theme.of(context).disabledColor,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.focused)
            ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.2)
            : Colors.transparent;
      }),
      value: value,
      onChanged: (v) {
        setState(() {
          value = v;
        });
        if (widget.onChanged != null) widget.onChanged!(v);
      },
    );
  }
}

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
      activeTrackColor: Colors.white,
      inactiveTrackColor: Colors.white60,
      thumbColor: WidgetStatePropertyAll(Colors.grey.shade900),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.focused)
            ? Colors.black12
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

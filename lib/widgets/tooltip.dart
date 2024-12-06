import 'package:flutter/material.dart';

class SlyTooltip extends Tooltip {
  const SlyTooltip({super.key, super.message, super.child})
      : super(
          waitDuration: const Duration(milliseconds: 500),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
          ),
        );
}

import 'package:flutter/material.dart';

class SlySpinner extends CircularProgressIndicator {
  const SlySpinner({super.key})
      : super.adaptive(
          strokeWidth: 5,
          strokeCap: StrokeCap.round,
        );
}

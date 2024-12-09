import 'package:flutter/material.dart';

import '/widgets/switch.dart';
import '/widgets/button.dart';

Widget getExportControls(
  BoxConstraints constraints,
  SlyButton? saveButton,
  Function getSaveMetadata,
  Function setSaveMetadata,
) {
  return ListView(
    key: const Key('exportControls'),
    physics: constraints.maxWidth > 600
        ? null
        : const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          top: 20,
          bottom: 12,
          left: 32,
          right: 32,
        ),
        child: Row(
          children: [
            const Text('Save Metadata'),
            const Spacer(),
            SlySwitch(
              value: getSaveMetadata(),
              onChanged: (value) => setSaveMetadata(value),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(
          top: 6,
          bottom: 40,
          left: 32,
          right: 32,
        ),
        child: saveButton,
      ),
    ],
  );
}

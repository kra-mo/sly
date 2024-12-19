import 'package:flutter/material.dart';

import '/widgets/switch.dart';
import '/widgets/unique/save_button.dart';

class SlyExportControls extends StatelessWidget {
  final SlySaveButton? saveButton;
  final bool wideLayout;
  final Function getSaveMetadata;
  final Function setSaveMetadata;

  const SlyExportControls({
    super.key,
    this.saveButton,
    required this.wideLayout,
    required this.getSaveMetadata,
    required this.setSaveMetadata,
  });

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('exportControls'),
        physics: wideLayout ? null : const NeverScrollableScrollPhysics(),
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

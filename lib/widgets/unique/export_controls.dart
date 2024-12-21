import 'package:flutter/material.dart';
import 'package:sly/widgets/button.dart';

import '/widgets/switch.dart';
import '/widgets/unique/save_button.dart';

class SlyExportControls extends StatelessWidget {
  final bool wideLayout;
  final Function getSaveMetadata;
  final Function setSaveMetadata;
  final bool multipleImages;
  final SlySaveButton? saveButton;
  final VoidCallback? exportAll;

  const SlyExportControls({
    super.key,
    required this.wideLayout,
    required this.getSaveMetadata,
    required this.setSaveMetadata,
    required this.multipleImages,
    this.saveButton,
    this.exportAll,
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
              left: 24,
              right: 24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save Metadata'),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          'Such as date taken and location',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
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
              bottom: 6,
              left: 24,
              right: 24,
            ),
            child: saveButton,
          ),
          multipleImages
              ? Padding(
                  padding: const EdgeInsets.only(
                    top: 6,
                    bottom: 40,
                    left: 24,
                    right: 24,
                  ),
                  child: SlyButton(
                    onPressed: exportAll,
                    child: const Text('Save All'),
                  ),
                )
              : Container(),
        ],
      );
}

import 'package:flutter/material.dart';

import '/platform.dart';
import '/image.dart';
import '/history.dart';
import '/widgets/slider_row.dart';

class SlyControlsListView extends StatelessWidget {
  final Map<String, SlyRangeAttribute> attributes;
  final BoxConstraints constraints;
  final HistoryManager history;
  final Function updateImage;

  const SlyControlsListView({
    super.key,
    required this.attributes,
    required this.constraints,
    required this.history,
    required this.updateImage,
  });

  @override
  build(BuildContext context) {
    return ListView.builder(
      physics: constraints.maxWidth > 600
          ? null
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: attributes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 &&
                    constraints.maxWidth > 600 &&
                    !platformHasInsetTopBar
                ? 16
                : 0,
            bottom: index == attributes.length - 1 ? 28 : 0,
            left: platformHasBackGesture ? 8 : 0,
            right: platformHasBackGesture ? 8 : 0,
          ),
          child: SlySliderRow(
            label: attributes.values.elementAt(index).name,
            value: attributes.values.elementAt(index).value,
            secondaryTrackValue: attributes.values.elementAt(index).anchor,
            min: attributes.values.elementAt(index).min,
            max: attributes.values.elementAt(index).max,
            onChanged: (value) {},
            onChangeEnd: (value) {
              history.update();
              attributes.values.elementAt(index).value = value;
              updateImage();
            },
          ),
        );
      },
    );
  }
}

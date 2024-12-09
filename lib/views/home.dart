import 'package:flutter/material.dart';

import '/platform.dart';
import '/io.dart';
import '/preferences.dart';
import '/widgets/button.dart';
import '/widgets/spinner.dart';
import '/widgets/title_bar.dart';
import '/widgets/about.dart';

class SlyHomePage extends StatefulWidget {
  const SlyHomePage({super.key, required this.title});

  final String title;

  @override
  State<SlyHomePage> createState() => _SlyHomePageState();
}

class _SlyHomePageState extends State<SlyHomePage> {
  final GlobalKey<SlyButtonState> pickerButtonKey = GlobalKey<SlyButtonState>();

  final String _pickerButtonLabel = 'Pick Images';
  late final SlyButton _pickerButton = SlyButton(
    key: pickerButtonKey,
    suggested: true,
    child: Text(_pickerButtonLabel),
    onPressed: () async {
      _pickerButton.setChild(
        const Padding(
          padding: EdgeInsets.all(6),
          child: SizedBox(
            width: 24,
            height: 24,
            child: SlySpinner(),
          ),
        ),
      );

      openImage(
        context,
        null,
        null,
        () => _pickerButton.setChild(Text(_pickerButtonLabel)),
        true,
        null,
        null,
      );

      // Wait for the page transition animation
      await Future.delayed(const Duration(milliseconds: 2000));
      _pickerButton.setChild(Text(_pickerButtonLabel));
    },
  );

  @override
  Widget build(BuildContext context) {
    final preferencesButton = Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).viewPadding.top + 12,
        bottom: 12,
        left: 12,
        right: 12,
      ),
      child: Semantics(
        label: 'Preferences',
        child: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: ImageIcon(
            color: Theme.of(context).hintColor,
            const AssetImage('assets/icons/preferences.png'),
          ),
          padding: const EdgeInsets.all(12),
          onPressed: () {
            showSlyPreferencesDialog(context);
          },
        ),
      ),
    );

    return Scaffold(
      body: SlyDragWindowBox(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: platformHasRightAlignedWindowControls
                  ? [
                      preferencesButton,
                      const SlyTitleBar(),
                    ]
                  : [
                      const SlyTitleBar(),
                      preferencesButton,
                    ],
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 48,
                    right: 48,
                    bottom: 72,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const ImageIcon(
                        AssetImage('assets/sly.png'),
                        color: Colors.deepOrangeAccent,
                        size: 96,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Edit Your Photos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Text(
                          'Choose an image to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Column(
                          children: [
                            _pickerButton,
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: SlyButton(
                                onPressed: () {
                                  showSlyAboutDialog(context);
                                },
                                child: const Text('About Sly'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

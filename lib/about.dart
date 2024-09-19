import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:url_launcher/url_launcher.dart';

import 'dialog.dart';
import 'button.dart';
import 'title_bar.dart';

void showSlyAboutDialog(BuildContext context) {
  showSlyDialog(
    context,
    'Sly',
    <Widget>[
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [
            Text(
              'A Friendly Image Editor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(
                    text:
                        'Sly is an open source application licensed under the',
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'GPLv3',
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(
                          Uri.parse(
                            'https://www.gnu.org/licenses/gpl-3.0.en.html',
                          ),
                        );
                      },
                  ),
                  const TextSpan(
                    text: '. ',
                  ),
                  const TextSpan(
                    text: 'The source code is available',
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'on GitHub',
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(
                          Uri.parse(
                            'https://github.com/kra-mo/sly',
                          ),
                        );
                      },
                  ),
                  const TextSpan(
                    text: '. ',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(
                    text:
                        'If you want to support my work, consider donating to me on',
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'GitHub Sponsors',
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(
                          Uri.parse(
                            'https://github.com/sponsors/kra-mo',
                          ),
                        );
                      },
                  ),
                  const TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(
                    text:
                        'Licenses of other open source libraries used by the app can be viewed',
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'here',
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Column(
                              children: <Widget>[
                                Container(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: const SlyTitleBar(),
                                ),
                                const Expanded(
                                  child: LicensePage(
                                    applicationLegalese: '© 2024 kramo',
                                    applicationIcon: ImageIcon(
                                      size: 96,
                                      color: Colors.deepOrangeAccent,
                                      AssetImage('assets/sly.png'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                  ),
                  const TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SlyButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ],
  );
}

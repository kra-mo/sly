import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils.dart';
import 'image.dart';
import 'button.dart';
import 'dialog.dart';
import 'editor_page.dart';
import 'snack_bar.dart';
import 'title_bar.dart';

void main() {
  runApp(const SlyApp());

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.grey.shade900,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
    ),
  );

  if (isDesktop()) {
    doWhenWindowReady(() {
      appWindow.alignment = Alignment.center;
      appWindow.minSize = const Size(360, 294);
      appWindow.size = const Size(900, 600);
    });
  }
}

class SlyApp extends StatelessWidget {
  const SlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sly',
      home: const SlyHomePage(title: 'Home'),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Geist',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.grey,
          accentColor: Colors.white,
          cardColor: Colors.grey.shade900,
          backgroundColor: Colors.black,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}

class SlyHomePage extends StatefulWidget {
  const SlyHomePage({super.key, required this.title});

  final String title;

  @override
  State<SlyHomePage> createState() => _SlyHomePageState();
}

class _SlyHomePageState extends State<SlyHomePage> {
  final GlobalKey<SlyButtonState> pickerButtonKey = GlobalKey<SlyButtonState>();

  final String _pickerButtonLabel = 'Pick Image';
  late final SlyButton _pickerButton = SlyButton(
    key: pickerButtonKey,
    child: Text(_pickerButtonLabel),
    onPressed: () async {
      _pickerButton.setChild(
        const Padding(
          padding: EdgeInsets.all(6),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      );

      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        _pickerButton.setChild(Text(_pickerButtonLabel));
        return;
      }

      final image = await loadImage(await file.readAsBytes());
      if (image == null) {
        _pickerButton.setChild(Text(_pickerButtonLabel));

        if (!mounted) return;

        showSlySnackBar(context, 'Couldn’t Load Image');
        return;
      }

      if (!mounted) {
        _pickerButton.setChild(Text(_pickerButtonLabel));
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SlyEditorPage(image: SlyImage.fromImage(image)),
        ),
      );

      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarColor: Color.alphaBlend(
            Colors.white10,
            Colors.grey.shade900,
          ),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemStatusBarContrastEnforced: true,
        ),
      );

      // Wait for the page transition animation
      await Future.delayed(const Duration(milliseconds: 2000));
      _pickerButton.setChild(Text(_pickerButtonLabel));
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MoveWindow(
        child: Column(
          children: <Widget>[
            titleBar,
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
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
                                  showSlyDialog(
                                    context,
                                    'Sly',
                                    <Widget>[
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 240),
                                        child: Column(
                                          children: [
                                            Text(
                                              'A Friendly Image Editor',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 24),
                                            RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(
                                                children: [
                                                  const TextSpan(
                                                    text:
                                                        'Sly is an open source application licensed under the',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ' '),
                                                  TextSpan(
                                                    text: 'GPLv3',
                                                    style: const TextStyle(
                                                      color: Colors
                                                          .deepOrangeAccent,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
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
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text:
                                                        'The source code is available',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ' '),
                                                  TextSpan(
                                                    text: 'on GitHub',
                                                    style: const TextStyle(
                                                      color: Colors
                                                          .deepOrangeAccent,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
                                                          ..onTap = () {
                                                            launchUrl(
                                                              Uri.parse(
                                                                'https://github.com/kra-mo/sly',
                                                              ),
                                                            );
                                                          },
                                                  ),
                                                  const TextSpan(
                                                    text: '.',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(
                                                children: [
                                                  const TextSpan(
                                                    text:
                                                        'If you want to support my work, consider donating to me on',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ' '),
                                                  TextSpan(
                                                    text: 'GitHub Sponsors',
                                                    style: const TextStyle(
                                                      color: Colors
                                                          .deepOrangeAccent,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
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
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 40),
                                            SlyButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: slySubtleButtonStlye,
                                              child: const Text('Done'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                style: slySubtleButtonStlye,
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

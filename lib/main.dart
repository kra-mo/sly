import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:window_manager/window_manager.dart';

import 'image.dart';
import 'button.dart';
import 'spinner.dart';
import 'editor_page.dart';
import 'snack_bar.dart';
import 'title_bar.dart';
import 'about.dart';

void main() async {
  runApp(const SlyApp());

  await windowManager.ensureInitialized();

  if (!kIsWeb && Platform.isWindows) {
    windowManager.setMinimumSize(const Size(360, 294));
  }

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
            child: SlySpinner(),
          ),
        ),
      );

      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) {
        _pickerButton.setChild(Text(_pickerButtonLabel));
        return;
      }

      final image = await SlyImage.fromData(await file.readAsBytes());
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
          builder: (context) => SlyEditorPage(
            image: image,
            suggestedFileName: '${file.name.split('.').first} Edited',
          ),
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
      body: SlyDragWindowBox(
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
                                  showSlyAboutDialog(context);
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

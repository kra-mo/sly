import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'utils.dart';
import 'image.dart';
import 'editor_page.dart';

void main() {
  runApp(const SlyApp());

  doWhenWindowReady(() {
    appWindow.alignment = Alignment.center;
    appWindow.minSize = const Size(270, 270);
  });
}

class SlyApp extends StatelessWidget {
  const SlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
      settings: PlatformSettingsData(
        platformStyle: const PlatformStyleData(
          windows: PlatformStyle.Cupertino,
          web: PlatformStyle.Cupertino,
          linux: PlatformStyle.Cupertino,
        ),
      ),
      builder: (context) => PlatformTheme(
        themeMode: ThemeMode.system,
        builder: (context) => const PlatformApp(
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          title: 'Sly',
          home: SlyHomePage(title: 'Home'),
          debugShowCheckedModeBanner: false,
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
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: MoveWindow(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(context.platformIcons.photoLibrary, size: 64),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Edit an Image',
                  textAlign: TextAlign.center,
                  style: platformThemeData(
                    context,
                    material: (ThemeData data) => data.textTheme.titleLarge,
                    cupertino: (CupertinoThemeData data) =>
                        data.textTheme.navLargeTitleTextStyle,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Text(
                  'Choose an image to get started',
                  textAlign: TextAlign.center,
                ),
              ),
              PlatformElevatedButton(
                child: const Text('Choose File'),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? file =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (file == null) return;

                  final image = await loadImage(await file.readAsBytes());
                  if (image == null) return;

                  if (!context.mounted) {
                    throw Exception('Context is not mounted.');
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                          body:
                              SlyEditorPage(image: SlyImage.fromImage(image))),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

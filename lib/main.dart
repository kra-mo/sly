import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:image_picker/image_picker.dart';

import 'utils.dart';
import 'image.dart';
import 'button.dart';
import 'editor_page.dart';

void main() {
  runApp(const SlyApp());

  doWhenWindowReady(() {
    appWindow.alignment = Alignment.center;
    appWindow.minSize = const Size(320, 270);
  });
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MoveWindow(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const ImageIcon(
                AssetImage("assets/icons/sly.png"),
                color: Colors.deepOrangeAccent,
                size: 96,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Edit an Image',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Choose an image to get started',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: SlyButton(
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
                            body: SlyEditorPage(
                                image: SlyImage.fromImage(image))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:image_picker/image_picker.dart';

import 'utils.dart';
import 'image.dart';
import 'button.dart';
import 'editor_page.dart';
import 'title_bar.dart';

void main() {
  runApp(const SlyApp());

  doWhenWindowReady(() {
    appWindow.alignment = Alignment.center;
    appWindow.minSize = const Size(360, 294);
    appWindow.size = const Size(900, 600);
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
  final GlobalKey<SlyButtonState> pickerButtonKey = GlobalKey<SlyButtonState>();

  final String _pickerButtonLabel = 'Pick Image';
  late final SlyButton _pickerButton = SlyButton(
    key: pickerButtonKey,
    child: const Text('Choose File'),
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
        return;
      }

      if (!mounted) {
        _pickerButton.setChild(Text(_pickerButtonLabel));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Scaffold(body: SlyEditorPage(image: SlyImage.fromImage(image))),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const ImageIcon(
                      AssetImage("assets/sly.png"),
                      color: Colors.deepOrangeAccent,
                      size: 96,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Edit Your Photos',
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
                      child: _pickerButton,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

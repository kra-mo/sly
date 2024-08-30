import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:crop_image/crop_image.dart';

import 'utils.dart';
import 'image.dart';
import 'button.dart';
import 'slider.dart';
import 'switch.dart';

class SlyEditorPage extends StatefulWidget {
  final SlyImage image;

  const SlyEditorPage({super.key, required this.image});

  @override
  State<SlyEditorPage> createState() => _SlyEditorPageState();
}

class _SlyEditorPageState extends State<SlyEditorPage> {
  final GlobalKey<SlyButtonState> slyButtonKey = GlobalKey<SlyButtonState>();

  late SlyImage flippedImage = widget.image;
  late SlyImage thumbnail;
  late SlyImage croppedThumbnail;
  Future<Uint8List>? futureImage;
  Future<Uint8List>? editedFutureImage;
  Widget? controlsWidget;
  final cropController = CropController();
  int _selectedPageIndex = 0;
  bool _saveMetadata = true;
  final String _saveButtonLabel = Platform.isIOS ? 'Save to Photos' : 'Save';
  late final SlyButton _saveButton = SlyButton(
    key: slyButtonKey,
    child: Text(_saveButtonLabel),
    onPressed: () async {
      _saveButton.setChild(
        Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
              width: 24,
              height: 24,
              child: PlatformCircularProgressIndicator()),
        ),
      );

      String? format;

      await showDialog(
        context: context,
        builder: (context) => Theme(
          data: ThemeData.dark(),
          child: SimpleDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(18),
              ),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.only(
              bottom: 24,
              left: 24,
              right: 24,
            ),
            titlePadding: const EdgeInsets.only(
              top: 24,
              bottom: 24,
              left: 12,
              right: 12,
            ),
            backgroundColor: Colors.grey.shade900,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            title: const Center(
                child: Text('Choose a Format',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ))),
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SlyButton(
                    onPressed: () {
                      format = 'JPEG75';
                      Navigator.pop(context);
                    },
                    style: slySubtleButtonStlye,
                    child: const Text('JPEG Quality 75'),
                  )),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SlyButton(
                  onPressed: () {
                    format = 'JPEG90';
                    Navigator.pop(context);
                  },
                  style: slySubtleButtonStlye,
                  child: const Text('JPEG Quality 90'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SlyButton(
                  onPressed: () {
                    format = 'JPEG100';
                    Navigator.pop(context);
                  },
                  style: slySubtleButtonStlye,
                  child: const Text('JPEG Quality 100'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SlyButton(
                  onPressed: () {
                    format = 'PNG';
                    Navigator.pop(context);
                  },
                  style: slySubtleButtonStlye,
                  child: const Text('PNG (Lossless)'),
                ),
              ),
              SlyButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );

      // The user cancelled the format selection
      if (format == null) {
        _saveButton.setChild(Text(_saveButtonLabel));
        return;
      }

      final image = SlyImage.from(flippedImage);
      flippedImage.applyEdits();

      if (!_saveMetadata) {
        image.removeMetadata;
      }

      final fullSizeCropController = CropController(
        defaultCrop: cropController.crop,
        rotation: cropController.rotation,
      );
      fullSizeCropController.image = await loadUiImage(await image.encode());

      final uiImage = await fullSizeCropController.croppedBitmap();
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final imgImage = await loadImage(byteData.buffer.asUint8List());
      if (imgImage == null) return;

      final croppedImage = SlyImage.fromImage(imgImage);
      croppedImage.lightAttributes = thumbnail.lightAttributes;
      croppedImage.colorAttributes = thumbnail.colorAttributes;
      await croppedImage.applyEdits();

      if (!(await saveImage(await croppedImage.encode(format: format),
          fileExtension: format == 'PNG' ? 'png' : 'jpg'))) {
        _saveButton.setChild(Text(_saveButtonLabel));
        return;
      }

      if (mounted) {
        _saveButton.setChild(Icon(context.platformIcons.checkMark));
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      _saveButton.setChild(Text(_saveButtonLabel));
    },
  );

  @override
  void initState() {
    thumbnail = flippedImage.getThumbnail();
    croppedThumbnail = flippedImage.getThumbnail();

    flippedImage.lightAttributes =
        thumbnail.lightAttributes = croppedThumbnail.lightAttributes;
    flippedImage.colorAttributes =
        thumbnail.colorAttributes = croppedThumbnail.colorAttributes;

    futureImage = thumbnail.encode();

    editedFutureImage = croppedThumbnail.applyEdits().then((value) {
      return croppedThumbnail.encode();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void updateImage() async {
      setState(() {
        editedFutureImage = croppedThumbnail.applyEdits().then((value) {
          return croppedThumbnail.encode();
        });
      });
    }

    Future<void> updateCroppedImage() async {
      final originalImage = await futureImage;
      if (originalImage == null) return;

      cropController.image = await loadUiImage(originalImage);
      final uiImage = await cropController.croppedBitmap();
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final image = await loadImage(byteData.buffer.asUint8List());
      if (image == null) return;

      croppedThumbnail = SlyImage.fromImage(image);
      croppedThumbnail.lightAttributes = thumbnail.lightAttributes;
      croppedThumbnail.colorAttributes = thumbnail.colorAttributes;
      updateImage();
    }

    void flipImage(SlyImageFlipDirection direction) async {
      if (cropController.rotation == CropRotation.left ||
          cropController.rotation == CropRotation.right) {
        if (direction == SlyImageFlipDirection.horizontal) {
          direction = SlyImageFlipDirection.vertical;
        } else if (direction == SlyImageFlipDirection.vertical) {
          direction = SlyImageFlipDirection.horizontal;
        }
      }

      flippedImage.flip(direction);
      thumbnail.flip(direction);

      setState(() {
        futureImage = thumbnail.encode();
      });

      updateCroppedImage();
    }

    return PlatformScaffold(
      backgroundColor: Colors.grey.shade900,
      body: CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: Theme(
          data: ThemeData.dark(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageView = Expanded(
                flex: 7,
                child: FittedBox(
                  child: SizedBox(
                    width: thumbnail.width.toDouble(),
                    height: thumbnail.height.toDouble(),
                    child: FutureBuilder<Uint8List>(
                      future: editedFutureImage,
                      builder: (BuildContext context,
                          AsyncSnapshot<Uint8List> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: PlatformCircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return Image.memory(snapshot.data!);
                        } else {
                          return const Text('Could not Load Image');
                        }
                      },
                    ),
                  ),
                ),
              );

              final cropImageView = Expanded(
                flex: 7,
                child: FittedBox(
                  child: SizedBox(
                    width: thumbnail.width.toDouble(),
                    height: thumbnail.height.toDouble(),
                    child: FutureBuilder<Uint8List>(
                      future: futureImage,
                      builder: (BuildContext context,
                          AsyncSnapshot<Uint8List> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: PlatformCircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return CropImage(
                            controller: cropController,
                            image: Image.memory(snapshot.data!),
                            onCrop: (rect) async {
                              updateCroppedImage();
                            },
                          );
                        } else {
                          return const Text('Could not Load Image');
                        }
                      },
                    ),
                  ),
                ),
              );

              final lightControls = ConstrainedBox(
                key: const Key('lightControls'),
                constraints: const BoxConstraints(maxWidth: 250),
                child: Material(
                  color: Colors.grey.shade900,
                  child: ListView.builder(
                    physics: constraints.maxWidth > 600
                        ? null
                        : const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: croppedThumbnail.lightAttributes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: index == 0 ? 16 : 0,
                          bottom: index ==
                                  croppedThumbnail.lightAttributes.length - 1
                              ? 28
                              : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: Text(
                                croppedThumbnail.lightAttributes.values
                                    .elementAt(index)
                                    .name,
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                            SlySlider(
                              value: croppedThumbnail.lightAttributes.values
                                  .elementAt(index)
                                  .value,
                              secondaryTrackValue: croppedThumbnail
                                  .lightAttributes.values
                                  .elementAt(index)
                                  .anchor,
                              min: croppedThumbnail.lightAttributes.values
                                  .elementAt(index)
                                  .min,
                              max: croppedThumbnail.lightAttributes.values
                                  .elementAt(index)
                                  .max,
                              onChanged: (value) {},
                              onChangeEnd: (value) {
                                croppedThumbnail.lightAttributes.values
                                    .elementAt(index)
                                    .value = value;
                                updateImage();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );

              final colorControls = ConstrainedBox(
                key: const Key('colorControls'),
                constraints: const BoxConstraints(maxWidth: 250),
                child: Material(
                  color: Colors.grey.shade900,
                  child: ListView.builder(
                    physics: constraints.maxWidth > 600
                        ? null
                        : const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: croppedThumbnail.colorAttributes.length + 1,
                    itemBuilder: (context, index) {
                      // I am adding padding like this here because of some Flutter bug.
                      // If I didn't, the value of the first slider would be messed up.
                      // No idea why.
                      //
                      // Or maybe I'm stupid. In that case, please tell me.
                      if (index == 0) return const SizedBox(height: 16);
                      index--;

                      return Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: index ==
                                  croppedThumbnail.colorAttributes.length - 1
                              ? 28
                              : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: Text(
                                croppedThumbnail.colorAttributes.values
                                    .elementAt(index)
                                    .name,
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                            SlySlider(
                              value: croppedThumbnail.colorAttributes.values
                                  .elementAt(index)
                                  .value,
                              secondaryTrackValue: croppedThumbnail
                                  .colorAttributes.values
                                  .elementAt(index)
                                  .anchor,
                              min: croppedThumbnail.colorAttributes.values
                                  .elementAt(index)
                                  .min,
                              max: croppedThumbnail.colorAttributes.values
                                  .elementAt(index)
                                  .max,
                              onChanged: (value) {},
                              onChangeEnd: (value) {
                                croppedThumbnail.colorAttributes.values
                                    .elementAt(index)
                                    .value = value;
                                updateImage();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );

              final geometryControls = Material(
                key: const Key('geometryControls'),
                color: Colors.grey.shade900,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final buttons = <Padding>[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          color: Colors.white,
                          icon: const Icon(CupertinoIcons.rotate_left),
                          onPressed: () async {
                            cropController.rotateLeft();
                            updateCroppedImage();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          color: Colors.white,
                          icon: const Icon(CupertinoIcons.rotate_right),
                          onPressed: () async {
                            cropController.rotateRight();
                            updateCroppedImage();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          color: Colors.white,
                          icon: const Icon(
                              CupertinoIcons.arrow_right_arrow_left_square),
                          onPressed: () {
                            flipImage(SlyImageFlipDirection.horizontal);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          color: Colors.white,
                          icon: const Icon(CupertinoIcons.arrow_up_down_square),
                          onPressed: () {
                            flipImage(SlyImageFlipDirection.vertical);
                          },
                        ),
                      ),
                    ];

                    if (constraints.maxWidth > 600) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: ListView(
                          shrinkWrap: true,
                          children: buttons,
                        ),
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: buttons,
                      );
                    }
                  },
                ),
              );

              final exportControls = ConstrainedBox(
                key: const Key('lexportControls'),
                constraints: const BoxConstraints(maxWidth: 250),
                child: Material(
                  color: Colors.grey.shade900,
                  child: ListView(
                    physics: constraints.maxWidth > 600
                        ? null
                        : const NeverScrollableScrollPhysics(),
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
                              value: _saveMetadata,
                              onChanged: (value) {
                                _saveMetadata = value;
                              },
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
                        child: _saveButton,
                      ),
                    ],
                  ),
                ),
              );

              controlsWidget ??= lightControls;

              void navigationDestinationSelected(int index) {
                if (_selectedPageIndex == index) return;
                _selectedPageIndex = index;

                switch (index) {
                  case 0:
                    setState(() {
                      controlsWidget = lightControls;
                    });
                  case 1:
                    setState(() {
                      controlsWidget = colorControls;
                    });
                  case 2:
                    setState(() {
                      controlsWidget = geometryControls;
                    });
                  case 3:
                    setState(() {
                      controlsWidget = exportControls;
                    });
                  default:
                    setState(() {
                      controlsWidget = lightControls;
                    });
                }
              }

              final navigationRail = NavigationRail(
                backgroundColor: Colors.white10,
                indicatorColor: Colors.white24,
                selectedIndex: _selectedPageIndex,
                labelType: NavigationRailLabelType.selected,
                onDestinationSelected: navigationDestinationSelected,
                destinations: <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(context.platformIcons.brightness),
                    label: const Text('Light'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(context.platformIcons.star),
                    label: const Text('Color'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(context.platformIcons.fullscreen),
                    label: const Text('Geometry'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(context.platformIcons.share),
                    label: const Text('Export'),
                  ),
                ],
              );

              final navigationBar = NavigationBar(
                backgroundColor: Colors.white10,
                shadowColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.white12),
                indicatorColor: Colors.white24,
                surfaceTintColor: Colors.transparent,
                selectedIndex: _selectedPageIndex,
                onDestinationSelected: navigationDestinationSelected,
                destinations: <Widget>[
                  NavigationDestination(
                    icon: Icon(context.platformIcons.brightness),
                    label: 'Light',
                  ),
                  NavigationDestination(
                    icon: Icon(context.platformIcons.star),
                    label: 'Color',
                  ),
                  NavigationDestination(
                    icon: Icon(context.platformIcons.fullscreen),
                    label: 'Geometry',
                  ),
                  NavigationDestination(
                    icon: Icon(context.platformIcons.share),
                    label: 'Export',
                  ),
                ],
              );

              if (constraints.maxWidth > 600) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: isDesktop()
                                  ? (Platform.isLinux ? 42 : 32)
                                  : 0,
                              child: MoveWindow(),
                            ),
                            _selectedPageIndex == 2 ? cropImageView : imageView
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: (isDesktop() && !Platform.isMacOS)
                              ? (Platform.isLinux ? 42 : 32)
                              : 0,
                        ),
                        Expanded(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuint,
                            child: AnimatedSwitcher(
                                switchInCurve: Curves.easeOutQuint,
                                switchOutCurve: Curves.easeInSine,
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return SlideTransition(
                                      key: ValueKey<Key?>(child.key),
                                      position: Tween<Offset>(
                                        begin: const Offset(0.07, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        key: ValueKey<Key?>(child.key),
                                        opacity: animation,
                                        child: child,
                                      ));
                                },
                                duration: const Duration(milliseconds: 150),
                                child: controlsWidget),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        SizedBox(
                          // TODO: Change the color to the navigation rail's color
                          height: (isDesktop() && !Platform.isMacOS)
                              ? (Platform.isLinux ? 42 : 32)
                              : 0,
                        ),
                        Expanded(child: navigationRail),
                      ],
                    ),
                  ],
                );
              } else {
                return Scaffold(
                  backgroundColor: Colors.grey.shade900,
                  body: Column(
                    children: <Widget>[
                      SizedBox(
                        height: isDesktop() ? (Platform.isLinux ? 42 : 32) : 0,
                        child: MoveWindow(),
                      ),
                      Expanded(
                        child: ListView(
                          children: <Widget>[
                            _selectedPageIndex == 2 ? cropImageView : imageView,
                            (controlsWidget != null)
                                ? controlsWidget!
                                : lightControls
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: navigationBar,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

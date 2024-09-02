import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

import 'utils.dart';
import 'image.dart';
import 'button.dart';
import 'slider_row.dart';
import 'switch.dart';
import 'title_bar.dart';

class SlyEditorPage extends StatefulWidget {
  final SlyImage image;

  const SlyEditorPage({super.key, required this.image});

  @override
  State<SlyEditorPage> createState() => _SlyEditorPageState();
}

class _SlyEditorPageState extends State<SlyEditorPage> {
  final GlobalKey<SlyButtonState> saveButtonKey = GlobalKey<SlyButtonState>();
  final GlobalKey imageWidgetKey = GlobalKey();
  final GlobalKey controlsWidgetKey = GlobalKey();

  late SlyImage flippedImage = widget.image;
  late SlyImage thumbnail;
  late SlyImage croppedThumbnail;
  Uint8List? imageData;
  Uint8List? editedImageData;
  Widget? controlsChild;
  final cropController = CropController();
  int _selectedPageIndex = 0;
  bool _saveMetadata = true;
  final String _saveButtonLabel =
      !kIsWeb && Platform.isIOS ? 'Save to Photos' : 'Save';
  late final SlyButton _saveButton = SlyButton(
    key: saveButtonKey,
    child: Text(_saveButtonLabel),
    onPressed: () async {
      _saveButton.setChild(
        const Padding(
          padding: EdgeInsets.all(6),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      );

      String? format;

      await showGeneralDialog(
        context: context,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SimpleDialog(
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
            titlePadding: const EdgeInsets.symmetric(
              vertical: 32,
              horizontal: 16,
            ),
            title: const Center(
              child: Text(
                'Choose a Format',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SlyButton(
                  onPressed: () {
                    format = 'JPEG75';
                    Navigator.pop(context);
                  },
                  style: slySubtleButtonStlye,
                  child: const Text('JPEG Quality 75'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.only(bottom: 16),
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
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, widget) {
          final animIn = animation.status == AnimationStatus.forward;

          return FadeTransition(
            opacity: animation.drive(
              Tween(
                begin: 0.0,
                end: 1.0,
              ).chain(
                CurveTween(
                  curve: animIn ? Curves.easeOutExpo : Curves.easeInOutQuint,
                ),
              ),
            ),
            child: ScaleTransition(
              scale: animation.drive(
                Tween(
                  begin: animIn ? 1.1 : 1.4,
                  end: 1.0,
                ).chain(
                  CurveTween(
                    curve: animIn ? Curves.easeOutBack : Curves.easeOutQuint,
                  ),
                ),
              ),
              child: widget,
            ),
          );
        },
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
      croppedImage.effectAttributes = thumbnail.effectAttributes;
      await croppedImage.applyEdits();

      if (!(await saveImage(await croppedImage.encode(format: format),
          fileExtension: format == 'PNG' ? 'png' : 'jpg'))) {
        _saveButton.setChild(Text(_saveButtonLabel));
        return;
      }

      if (mounted) {
        _saveButton.setChild(const Icon(Icons.check));
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
    flippedImage.effectAttributes =
        thumbnail.effectAttributes = croppedThumbnail.effectAttributes;

    thumbnail.encode().then((data) {
      setState(() {
        imageData = data;
      });
    });

    croppedThumbnail.applyEdits().then((value) {
      croppedThumbnail.encode().then((data) {
        setState(() {
          editedImageData = data;
        });
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void updateImage() async {
      croppedThumbnail.applyEdits().then((value) {
        croppedThumbnail.encode().then((data) {
          setState(() {
            editedImageData = data;
          });
        });
      });
    }

    Future<void> updateCroppedImage() async {
      if (imageData == null) return;

      cropController.image = await loadUiImage(imageData!);
      final uiImage = await cropController.croppedBitmap();
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final image = await loadImage(byteData.buffer.asUint8List());
      if (image == null) return;

      croppedThumbnail = SlyImage.fromImage(image);
      croppedThumbnail.lightAttributes = thumbnail.lightAttributes;
      croppedThumbnail.colorAttributes = thumbnail.colorAttributes;
      croppedThumbnail.effectAttributes = thumbnail.effectAttributes;
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

      thumbnail.encode().then((data) {
        setState(() {
          imageData = data;
        });
        updateCroppedImage();
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        Future<void> pickNewImage() async {
          final ImagePicker picker = ImagePicker();

          final XFile? file =
              await picker.pickImage(source: ImageSource.gallery);
          if (file == null) return;

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              backgroundColor: Colors.transparent,
              content: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.only(
                        left: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 250)
                            : 16),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        ui.Radius.circular(8),
                      ),
                      child: Container(
                        color: Colors.grey.shade700,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator.adaptive(),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Loading Image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          final image = await loadImage(await file.readAsBytes());
          if (image == null) return;

          if (!context.mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SlyEditorPage(image: SlyImage.fromImage(image)),
            ),
          );

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        final imageView = editedImageData != null
            ? InteractiveViewer(
                clipBehavior:
                    constraints.maxWidth > 600 ? Clip.none : Clip.hardEdge,
                key: const Key('imageView'),
                child: Image.memory(
                  editedImageData!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              )
            : FittedBox(
                key: const Key('imageView'),
                child: SizedBox(
                  width: thumbnail.width.toDouble(),
                  height: thumbnail.height.toDouble(),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              );

        final cropImageView = FittedBox(
          key: const Key('cropImageView'),
          child: SizedBox(
            width: thumbnail.width.toDouble(),
            height: thumbnail.height.toDouble(),
            child: imageData != null
                ? CropImage(
                    controller: cropController,
                    image: Image.memory(
                      imageData!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
          ),
        );

        final imageWidget = AnimatedPadding(
          key: imageWidgetKey,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuint,
          padding: _selectedPageIndex == 3
              ? const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                )
              : constraints.maxWidth > 600
                  ? const EdgeInsets.all(0)
                  : const EdgeInsets.only(top: 12, left: 12, right: 12),
          child: constraints.maxWidth > 600
              ? _selectedPageIndex == 3
                  ? cropImageView
                  : imageView
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxWidth),
                  child: _selectedPageIndex == 3
                      ? cropImageView
                      : ClipRRect(
                          borderRadius:
                              const BorderRadius.all(ui.Radius.circular(6)),
                          child: imageView,
                        ),
                ),
        );

        final lightControls = ListView.builder(
          key: const Key('lightControls'),
          physics: constraints.maxWidth > 600
              ? null
              : const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: croppedThumbnail.lightAttributes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 16 : 0,
                bottom: index == croppedThumbnail.lightAttributes.length - 1
                    ? 28
                    : 0,
              ),
              child: SlySliderRow(
                label: croppedThumbnail.lightAttributes.values
                    .elementAt(index)
                    .name,
                value: croppedThumbnail.lightAttributes.values
                    .elementAt(index)
                    .value,
                secondaryTrackValue: croppedThumbnail.lightAttributes.values
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
                  setState(() {});
                },
              ),
            );
          },
        );

        final colorControls = ListView.builder(
          key: const Key('colorControls'),
          physics: constraints.maxWidth > 600
              ? null
              : const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: croppedThumbnail.colorAttributes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 16 : 0,
                bottom: index == croppedThumbnail.colorAttributes.length - 1
                    ? 28
                    : 0,
              ),
              child: SlySliderRow(
                label: croppedThumbnail.colorAttributes.values
                    .elementAt(index)
                    .name,
                value: croppedThumbnail.colorAttributes.values
                    .elementAt(index)
                    .value,
                secondaryTrackValue: croppedThumbnail.colorAttributes.values
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
            );
          },
        );

        final effectControls = ListView.builder(
          key: const Key('effectControls'),
          physics: constraints.maxWidth > 600
              ? null
              : const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: croppedThumbnail.effectAttributes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 16 : 0,
                bottom: index == croppedThumbnail.effectAttributes.length - 1
                    ? 28
                    : 0,
              ),
              child: SlySliderRow(
                label: croppedThumbnail.effectAttributes.values
                    .elementAt(index)
                    .name,
                value: croppedThumbnail.effectAttributes.values
                    .elementAt(index)
                    .value,
                secondaryTrackValue: croppedThumbnail.effectAttributes.values
                    .elementAt(index)
                    .anchor,
                min: croppedThumbnail.effectAttributes.values
                    .elementAt(index)
                    .min,
                max: croppedThumbnail.effectAttributes.values
                    .elementAt(index)
                    .max,
                onChanged: (value) {},
                onChangeEnd: (value) {
                  croppedThumbnail.effectAttributes.values
                      .elementAt(index)
                      .value = value;
                  updateImage();
                },
              ),
            );
          },
        );

        final cropControls = LayoutBuilder(
          builder: (context, constraints) {
            final buttons = <Semantics>[
              Semantics(
                label: 'Rotate Left',
                child: IconButton(
                  color: Colors.white,
                  icon: const ImageIcon(
                    AssetImage('assets/icons/rotate-left.png'),
                  ),
                  padding: const EdgeInsets.all(12),
                  onPressed: () async {
                    cropController.rotateLeft();
                    updateCroppedImage();
                  },
                ),
              ),
              Semantics(
                label: 'Rotate Right',
                child: IconButton(
                  color: Colors.white,
                  icon: const ImageIcon(
                    AssetImage('assets/icons/rotate-right.png'),
                  ),
                  padding: const EdgeInsets.all(12),
                  onPressed: () async {
                    cropController.rotateRight();
                    updateCroppedImage();
                  },
                ),
              ),
              Semantics(
                label: 'Flip Horizontal',
                child: IconButton(
                  color: Colors.white,
                  icon: const ImageIcon(
                    AssetImage('assets/icons/flip-horizontal.png'),
                  ),
                  padding: const EdgeInsets.all(12),
                  onPressed: () {
                    flipImage(SlyImageFlipDirection.horizontal);
                  },
                ),
              ),
              Semantics(
                label: 'Flip Vertical',
                child: IconButton(
                  color: Colors.white,
                  icon: const ImageIcon(
                    AssetImage('assets/icons/flip-vertical.png'),
                  ),
                  padding: const EdgeInsets.all(12),
                  onPressed: () {
                    flipImage(SlyImageFlipDirection.vertical);
                  },
                ),
              ),
            ];

            return Padding(
              padding: const EdgeInsets.all(12),
              child: (constraints.maxWidth > 600)
                  ? Wrap(
                      direction: Axis.vertical,
                      spacing: 6,
                      children: buttons,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: buttons,
                    ),
            );
          },
        );

        final exportControls = ListView(
          key: const Key('exportControls'),
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
        );

        controlsChild ??= lightControls;

        void navigationDestinationSelected(int index) {
          if (_selectedPageIndex == index) return;
          if (_selectedPageIndex == 3) updateCroppedImage();

          _selectedPageIndex = index;

          switch (index) {
            case 0:
              setState(() {
                controlsChild = lightControls;
              });
            case 1:
              setState(() {
                controlsChild = colorControls;
              });
            case 2:
              setState(() {
                controlsChild = effectControls;
              });
            case 3:
              setState(() {
                controlsChild = cropControls;
              });
            case 4:
              setState(() {
                controlsChild = exportControls;
              });
            default:
              setState(() {
                controlsChild = lightControls;
              });
          }
        }

        final navigationRail = NavigationRail(
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.white24,
          selectedIndex: _selectedPageIndex,
          labelType: NavigationRailLabelType.selected,
          indicatorShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
          ),
          onDestinationSelected: navigationDestinationSelected,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/light.png'),
                color: Colors.white,
              ),
              label: Text('Light'),
            ),
            NavigationRailDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/color.png'),
                color: Colors.white,
              ),
              label: Text('Color'),
            ),
            NavigationRailDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/effects.png'),
                color: Colors.white,
              ),
              label: Text('Effects'),
            ),
            NavigationRailDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/crop.png'),
                color: Colors.white,
              ),
              label: Text('Crop'),
            ),
            NavigationRailDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/export.png'),
                color: Colors.white,
              ),
              label: Text('Export'),
            ),
          ],
        );

        final navigationBar = NavigationBar(
          backgroundColor: Colors.white10,
          shadowColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.white12),
          indicatorColor: Colors.white24,
          selectedIndex: _selectedPageIndex,
          onDestinationSelected: navigationDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
          ),
          destinations: <Widget>[
            const NavigationDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/light.png'),
                color: Colors.white,
              ),
              label: 'Light',
            ),
            const NavigationDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/color.png'),
                color: Colors.white,
              ),
              label: 'Color',
            ),
            const NavigationDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/effects.png'),
                color: Colors.white,
              ),
              label: 'Effects',
            ),
            const NavigationDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/crop.png'),
                color: Colors.white,
              ),
              label: 'Crop',
            ),
            const NavigationDestination(
              icon: ImageIcon(
                AssetImage('assets/icons/export.png'),
                color: Colors.white,
              ),
              label: 'Export',
            ),
            Semantics(
              label: 'Add Image',
              child: FloatingActionButton.small(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey.shade200,
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                disabledElevation: 0,
                highlightElevation: 0,
                child: const Icon(Icons.add),
                onPressed: () {
                  pickNewImage();
                },
              ),
            ),
          ],
        );

        final controlsWidget = AnimatedSize(
          key: controlsWidgetKey,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          child: AnimatedSwitcher(
              switchInCurve: Curves.easeOutQuint,
              // switchOutCurve: Curves.easeInSine,
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Don't transition widgets animating out
                // as this causes issues with the crop page
                if (child != controlsChild) return Container();

                return SlideTransition(
                  key: ValueKey<Key?>(child.key),
                  position: Tween<Offset>(
                    begin: (constraints.maxWidth > 600)
                        ? const Offset(0.07, 0.0)
                        : const Offset(0.0, 0.07),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    key: ValueKey<Key?>(child.key),
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              duration: const Duration(milliseconds: 150),
              child: controlsChild),
        );

        if (constraints.maxWidth > 600) {
          return Scaffold(
            floatingActionButton: Padding(
              padding: const EdgeInsets.all(3),
              child: Semantics(
                label: 'Add Image',
                child: FloatingActionButton.small(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      ui.Radius.circular(8),
                    ),
                  ),
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  focusColor: Colors.white24,
                  hoverColor: Colors.white10,
                  splashColor: Colors.white10,
                  elevation: 0,
                  hoverElevation: 0,
                  focusElevation: 0,
                  disabledElevation: 0,
                  highlightElevation: 0,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    pickNewImage();
                  },
                ),
              ),
            ),
            body: Container(
              color: Colors.black,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: isDesktop()
                        ? Column(
                            children: <Widget>[
                              WindowTitleBarBox(
                                child: MoveWindow(),
                              ),
                              Expanded(child: imageWidget),
                            ],
                          )
                        : imageWidget,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _selectedPageIndex == 3 ? double.infinity : 250,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: ui.Radius.circular(12),
                            ),
                            child: Container(
                              color: Colors.grey.shade900,
                              child: controlsWidget,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.grey.shade900,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: ui.Radius.circular(12),
                        bottomLeft: ui.Radius.circular(12),
                      ),
                      child: MoveWindow(
                        child: Container(
                          color: Colors.white10,
                          child: Column(
                            children: <Widget>[
                              titleBar,
                              Expanded(
                                child: navigationRail,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Column(
              children: <Widget>[
                titleBar,
                Expanded(
                  child: _selectedPageIndex == 3
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(child: imageWidget),
                            cropControls,
                          ],
                        )
                      : ListView(
                          children: <Widget>[
                            imageWidget,
                            controlsWidget,
                          ],
                        ),
                ),
              ],
            ),
            bottomNavigationBar: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: ui.Radius.circular(12),
                topRight: ui.Radius.circular(12),
              ),
              child: navigationBar,
            ),
          );
        }
      },
    );
  }
}

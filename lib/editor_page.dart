import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

import 'utils.dart';
import 'image.dart';
import 'button.dart';
import 'slider_row.dart';
import 'switch.dart';
import 'toggle_buttons.dart';
import 'spinner.dart';
import 'dialog.dart';
import 'snack_bar.dart';
import 'title_bar.dart';

class SlyEditorPage extends StatefulWidget {
  final SlyImage image;
  final String suggestedFileName;

  const SlyEditorPage(
      {super.key,
      required this.image,
      this.suggestedFileName = 'Edited Image'});

  @override
  State<SlyEditorPage> createState() => _SlyEditorPageState();
}

class _SlyEditorPageState extends State<SlyEditorPage> {
  final GlobalKey<SlyButtonState> _saveButtonKey = GlobalKey<SlyButtonState>();
  final GlobalKey _imageWidgetKey = GlobalKey();
  int _controlsWidgetKeyValue = 0;

  Widget? _controlsChild;

  late final SlyImage _originalImage = widget.image;
  late SlyImage _editedImage;

  Uint8List? _originalImageData;
  Uint8List? _editedImageData;

  StreamSubscription<String>? subscription;

  bool _saveMetadata = true;
  String _saveFormat = 'PNG';
  bool _saveOnLoad = false;

  double _rotationAngle = 0.0;
  bool _hflip = false;
  bool _vflip = false;

  CropController? _cropController = CropController();
  bool _cropChanged = false;
  bool _portraitCrop = false;

  final List<List<Map<String, SlyImageAttribute>>> _undoList = [];
  final List<List<Map<String, SlyImageAttribute>>> _redoList = [];
  bool _canUndo = false;
  bool _canRedo = false;

  int _selectedPageIndex = 0;

  final String _saveButtonLabel =
      !kIsWeb && Platform.isIOS ? 'Save to Photos' : 'Save';
  late final SlyButton _saveButton = SlyButton(
    key: _saveButtonKey,
    child: Text(_saveButtonLabel),
    onPressed: () async {
      _saveButton.setChild(
        const Padding(
          padding: EdgeInsets.all(6),
          child: SizedBox(
            width: 24,
            height: 24,
            child: SlySpinner(),
          ),
        ),
      );

      String? format;

      await showSlyDialog(
        context,
        'Choose a Format',
        <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SlyButton(
              onPressed: () {
                format = 'JPEG75';
                Navigator.pop(context);
              },
              style: slySubtleButtonStlye,
              child: const Text('JPEG - Quality 75'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SlyButton(
              onPressed: () {
                format = 'JPEG90';
                Navigator.pop(context);
              },
              style: slySubtleButtonStlye,
              child: const Text('JPEG - Quality 90'),
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
              child: const Text('JPEG - Quality 100'),
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

      // The user cancelled the format selection
      if (format == null) {
        _saveButton.setChild(Text(_saveButtonLabel));
        return;
      }

      _saveFormat = format!;

      if (_editedImage.loading) {
        _saveOnLoad = true;
      } else {
        _save();
      }
    },
  );

  Future<void> _save() async {
    final copyImage = SlyImage.from(_editedImage);

    if (_rotationAngle != 0 && _rotationAngle != (math.pi * 2)) {
      copyImage.rotate(_rotationAngle * (180 / math.pi));
    }

    if (_hflip && _vflip) {
      copyImage.flip(SlyImageFlipDirection.both);
    } else if (_hflip) {
      copyImage.flip(SlyImageFlipDirection.horizontal);
    } else if (_vflip) {
      copyImage.flip(SlyImageFlipDirection.vertical);
    }

    if (_saveMetadata) {
      copyImage.copyMetadataFrom(_originalImage);
    } else {
      copyImage.removeMetadata();
    }

    if (!(await saveImage(
        await copyImage.encode(format: _saveFormat, fullRes: true),
        fileName: widget.suggestedFileName,
        fileExtension: _saveFormat == 'PNG' ? 'png' : 'jpg'))) {
      _saveButton.setChild(Text(_saveButtonLabel));
      copyImage.dispose();
      return;
    }

    copyImage.dispose();

    if (mounted) {
      _saveButton.setChild(
        const ImageIcon(
          AssetImage('assets/icons/checkmark.png'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    _saveButton.setChild(Text(_saveButtonLabel));
  }

  void _onImageUpdate(event) {
    if (!mounted) return;

    switch (event) {
      case 'updated':
        if (_saveOnLoad) {
          _save();
          _saveOnLoad = false;
        }

        _editedImage.encode(format: 'JPEG75').then((data) {
          setState(() {
            _editedImageData = data;
          });
        });
    }
  }

  @override
  void initState() {
    _editedImage = SlyImage.from(_originalImage);

    subscription = _editedImage.controller.stream.listen(_onImageUpdate);

    _editedImage.applyEditsProgressive();

    _originalImage.encode(format: 'PNG').then((data) {
      setState(() {
        _originalImageData = data;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    subscription?.cancel();

    _originalImage.dispose();
    _editedImage.dispose();

    _originalImageData = null;
    _editedImageData = null;

    _cropController = null;

    super.dispose();
  }

  void updateImage() async {
    _editedImage.applyEditsProgressive();
  }

  Future<void> updateCroppedImage() async {
    if (_cropController?.crop == null) return;

    final croppedImage = SlyImage.from(_originalImage);
    await croppedImage.crop(_cropController!.crop);

    subscription?.cancel();
    _editedImage.dispose();
    _editedImage = croppedImage;
    subscription = _editedImage.controller.stream.listen(_onImageUpdate);

    updateImage();
  }

  void flipImage(SlyImageFlipDirection direction) {
    if (!mounted) return;

    switch (direction) {
      case SlyImageFlipDirection.horizontal:
        setState(() {
          _hflip = !_hflip;
        });
      case SlyImageFlipDirection.vertical:
        setState(() {
          _vflip = !_vflip;
        });
      case SlyImageFlipDirection.both:
        setState(() {
          _hflip = !_hflip;
          _vflip = !_vflip;
        });
    }
  }

  void undo() {
    _undoOrRedo(redo: false);
  }

  void redo() {
    _undoOrRedo(redo: true);
  }

  void _undoOrRedo({required bool redo}) {
    final list = redo ? _redoList : _undoList;
    final last = list.lastOrNull;
    if (last == null) return;

    list.removeLast();

    _addToUndoOrRedo(redo: !redo, clearRedo: false);

    for (int index in [0, 1, 2]) {
      Map<String, SlyImageAttribute> attributes = index == 0
          ? _editedImage.lightAttributes
          : index == 1
              ? _editedImage.colorAttributes
              : _editedImage.effectAttributes;

      for (MapEntry<String, SlyImageAttribute> entry in last[index].entries) {
        attributes[entry.key] = entry.value;
      }
    }

    updateImage();
    _controlsWidgetKeyValue++;
  }

  void _addToUndoOrRedo({bool redo = false, bool clearRedo = true}) {
    List<Map<String, SlyImageAttribute>> newItem = [];

    for (final attributes in [
      _editedImage.lightAttributes,
      _editedImage.colorAttributes,
      _editedImage.effectAttributes,
    ]) {
      final Map<String, SlyImageAttribute> newMap = {};

      for (MapEntry<String, SlyImageAttribute> entry in attributes.entries) {
        newMap[entry.key] = SlyImageAttribute.copy(entry.value);
      }
      newItem.add(newMap);
    }

    (redo ? _redoList : _undoList).add(newItem);
    if (!redo && clearRedo) _redoList.clear();

    setState(() {
      _canUndo = _undoList.isNotEmpty;
      _canRedo = _redoList.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isApplePlatform = (!kIsWeb && (Platform.isMacOS || Platform.isIOS));

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: !isApplePlatform,
          meta: isApplePlatform,
        ): const UndoTextIntent(
          SelectionChangedCause.keyboard,
        ),
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: !isApplePlatform,
          meta: isApplePlatform,
          shift: true,
        ): const RedoTextIntent(
          SelectionChangedCause.keyboard,
        ),
        SingleActivator(
          LogicalKeyboardKey.keyY,
          control: !isApplePlatform,
          meta: isApplePlatform,
        ): const RedoTextIntent(
          SelectionChangedCause.keyboard,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoTextIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) {
              undo();
              return null;
            },
          ),
          RedoTextIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) {
              redo();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              Future<void> pickNewImage() async {
                final ImagePicker picker = ImagePicker();

                final XFile? file =
                    await picker.pickImage(source: ImageSource.gallery);
                if (file == null) return;

                if (!context.mounted) return;

                showSlySnackBar(context, 'Loading Image', loading: true);

                final image = await loadImage(await file.readAsBytes());
                if (image == null) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  showSlySnackBar(context, 'Couldn’t Load Image');
                  return;
                }

                if (!context.mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlyEditorPage(
                      image: SlyImage.fromImage(image),
                      suggestedFileName: '${file.name.split('.').first} Edited',
                    ),
                  ),
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }

              final imageView = _editedImageData != null
                  ? InteractiveViewer(
                      clipBehavior: constraints.maxWidth > 600
                          ? Clip.none
                          : Clip.hardEdge,
                      key: const Key('imageView'),
                      child: Image.memory(
                        _editedImageData!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    )
                  : const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: SlySpinner(),
                      ),
                    );

              final cropImageView = _originalImageData != null
                  ? CropImage(
                      key: const Key('cropImageView'),
                      gridThickWidth: constraints.maxWidth > 600 ? 6 : 8,
                      gridCornerColor: Colors.white,
                      controller: _cropController,
                      image: Image.memory(
                        _originalImageData!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                      onCrop: (rect) {
                        _cropChanged = true;
                      },
                    )
                  : const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: SlySpinner(),
                      ),
                    );

              final imageWidget = AnimatedPadding(
                key: _imageWidgetKey,
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
                child: Transform.flip(
                  flipX: _hflip,
                  flipY: _vflip,
                  child: Transform.rotate(
                    angle: _rotationAngle,
                    child: constraints.maxWidth > 600
                        ? _selectedPageIndex == 3
                            ? cropImageView
                            : imageView
                        : ConstrainedBox(
                            constraints:
                                BoxConstraints(maxHeight: constraints.maxWidth),
                            child: _selectedPageIndex == 3
                                ? cropImageView
                                : ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                    child: imageView,
                                  ),
                          ),
                  ),
                ),
              );

              final lightControls = ListView.builder(
                key: const Key('lightControls'),
                physics: constraints.maxWidth > 600
                    ? null
                    : const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _editedImage.lightAttributes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 && constraints.maxWidth > 600 ? 16 : 0,
                      bottom: index == _editedImage.lightAttributes.length - 1
                          ? 28
                          : 0,
                    ),
                    child: SlySliderRow(
                      label: _editedImage.lightAttributes.values
                          .elementAt(index)
                          .name,
                      value: _editedImage.lightAttributes.values
                          .elementAt(index)
                          .value,
                      secondaryTrackValue: _editedImage.lightAttributes.values
                          .elementAt(index)
                          .anchor,
                      min: _editedImage.lightAttributes.values
                          .elementAt(index)
                          .min,
                      max: _editedImage.lightAttributes.values
                          .elementAt(index)
                          .max,
                      onChanged: (value) {},
                      onChangeEnd: (value) {
                        _addToUndoOrRedo();
                        _editedImage.lightAttributes.values
                            .elementAt(index)
                            .value = value;
                        updateImage();
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
                itemCount: _editedImage.colorAttributes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 && constraints.maxWidth > 600 ? 16 : 0,
                      bottom: index == _editedImage.colorAttributes.length - 1
                          ? 28
                          : 0,
                    ),
                    child: SlySliderRow(
                      label: _editedImage.colorAttributes.values
                          .elementAt(index)
                          .name,
                      value: _editedImage.colorAttributes.values
                          .elementAt(index)
                          .value,
                      secondaryTrackValue: _editedImage.colorAttributes.values
                          .elementAt(index)
                          .anchor,
                      min: _editedImage.colorAttributes.values
                          .elementAt(index)
                          .min,
                      max: _editedImage.colorAttributes.values
                          .elementAt(index)
                          .max,
                      onChanged: (value) {},
                      onChangeEnd: (value) {
                        _addToUndoOrRedo();
                        _editedImage.colorAttributes.values
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
                itemCount: _editedImage.effectAttributes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 && constraints.maxWidth > 600 ? 16 : 0,
                      bottom: index == _editedImage.effectAttributes.length - 1
                          ? 28
                          : 0,
                    ),
                    child: SlySliderRow(
                      label: _editedImage.effectAttributes.values
                          .elementAt(index)
                          .name,
                      value: _editedImage.effectAttributes.values
                          .elementAt(index)
                          .value,
                      secondaryTrackValue: _editedImage.effectAttributes.values
                          .elementAt(index)
                          .anchor,
                      min: _editedImage.effectAttributes.values
                          .elementAt(index)
                          .min,
                      max: _editedImage.effectAttributes.values
                          .elementAt(index)
                          .max,
                      onChanged: (value) {},
                      onChangeEnd: (value) {
                        _addToUndoOrRedo();
                        _editedImage.effectAttributes.values
                            .elementAt(index)
                            .value = value;
                        updateImage();
                      },
                    ),
                  );
                },
              );

              void onAspectRatioSelected(double? ratio) {
                if ((_cropController != null) &&
                    (_cropController!.aspectRatio != ratio)) {
                  _cropChanged = true;
                  _cropController!.aspectRatio = ratio;
                }
                Navigator.pop(context);
              }

              final cropControls = LayoutBuilder(
                builder: (context, constraints) {
                  final buttons = <Semantics>[
                    Semantics(
                      label: 'Aspect Ratio',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const ImageIcon(
                          AssetImage('assets/icons/aspect-ratio.png'),
                        ),
                        padding: const EdgeInsets.all(12),
                        onPressed: () {
                          showSlyDialog(
                              context, 'Select Aspect Ratio', <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SlyToggleButtons(
                                defaultItem: _portraitCrop ? 1 : 0,
                                onSelected: (index) {
                                  _portraitCrop = index == 1;
                                },
                                children: const <Widget>[
                                  Text('Landscape'),
                                  Text('Portrait'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SlyButton(
                                onPressed: () {
                                  onAspectRatioSelected(null);
                                },
                                style: slySubtleButtonStlye,
                                child: const Text('Free'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SlyButton(
                                onPressed: () {
                                  onAspectRatioSelected(1);
                                },
                                style: slySubtleButtonStlye,
                                child: const Text('Square'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SlyButton(
                                onPressed: () {
                                  onAspectRatioSelected(
                                    _portraitCrop ? 3 / 4 : 4 / 3,
                                  );
                                },
                                style: slySubtleButtonStlye,
                                child: const Text('4:3'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SlyButton(
                                onPressed: () {
                                  onAspectRatioSelected(
                                    _portraitCrop ? 2 / 3 : 3 / 2,
                                  );
                                },
                                style: slySubtleButtonStlye,
                                child: const Text('3:2'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SlyButton(
                                onPressed: () {
                                  onAspectRatioSelected(
                                    _portraitCrop ? 9 / 16 : 16 / 9,
                                  );
                                },
                                style: slySubtleButtonStlye,
                                child: const Text('16:9'),
                              ),
                            ),
                            SlyButton(
                              onPressed: () {
                                if (_cropController == null) return;
                                onAspectRatioSelected(
                                    _cropController!.aspectRatio);
                              },
                              child: const Text('Cancel'),
                            ),
                          ]);
                        },
                      ),
                    ),
                    Semantics(
                      label: 'Rotate Left',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const ImageIcon(
                          AssetImage('assets/icons/rotate-left.png'),
                        ),
                        padding: const EdgeInsets.all(12),
                        onPressed: () {
                          double newAngle = _rotationAngle - (math.pi / 2);
                          if (newAngle < 0) {
                            newAngle = (math.pi * 2) + newAngle;
                          }

                          if (newAngle == (math.pi * 2)) {
                            newAngle = 0;
                          }

                          setState(() {
                            _rotationAngle = newAngle;
                          });
                        },
                      ),
                    ),
                    Semantics(
                      label: 'Rotate Right',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const ImageIcon(
                          AssetImage('assets/icons/rotate-right.png'),
                        ),
                        padding: const EdgeInsets.all(12),
                        onPressed: () {
                          double newAngle = _rotationAngle + (math.pi / 2);
                          if (newAngle > (math.pi * 2)) {
                            newAngle = newAngle - (math.pi * 2);
                          }

                          if (newAngle == (math.pi * 2)) {
                            newAngle = 0;
                          }

                          setState(() {
                            _rotationAngle = newAngle;
                          });
                        },
                      ),
                    ),
                    Semantics(
                      label: 'Flip Horizontal',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
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
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
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

              _controlsChild ??= lightControls;

              void navigationDestinationSelected(int index) {
                if (_selectedPageIndex == index) return;
                if (_selectedPageIndex == 3 && _cropChanged == true) {
                  updateCroppedImage();
                  _cropChanged = false;
                }

                _selectedPageIndex = index;

                switch (index) {
                  case 0:
                    setState(() {
                      _controlsChild = lightControls;
                    });
                  case 1:
                    setState(() {
                      _controlsChild = colorControls;
                    });
                  case 2:
                    setState(() {
                      _controlsChild = effectControls;
                    });
                  case 3:
                    setState(() {
                      _controlsChild = cropControls;
                    });
                  case 4:
                    setState(() {
                      _controlsChild = exportControls;
                    });
                  default:
                    setState(() {
                      _controlsChild = lightControls;
                    });
                }
              }

              final navigationRail = NavigationRail(
                backgroundColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                selectedIndex: _selectedPageIndex,
                labelType: NavigationRailLabelType.selected,
                indicatorShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                onDestinationSelected: navigationDestinationSelected,
                selectedIconTheme: const IconThemeData(
                  color: Colors.white,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Colors.white,
                ),
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: 'Light',
                      child: ImageIcon(AssetImage('assets/icons/light.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/light.png')),
                    label: Text('Light'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: 'Color',
                      child: ImageIcon(AssetImage('assets/icons/color.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/color.png')),
                    label: Text('Color'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: 'Effects',
                      child: ImageIcon(AssetImage('assets/icons/effects.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/effects.png')),
                    label: Text('Effects'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: 'Crop',
                      child: ImageIcon(AssetImage('assets/icons/crop.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/crop.png')),
                    label: Text('Crop'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: 'Export',
                      child: ImageIcon(AssetImage('assets/icons/export.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/export.png')),
                    label: Text('Export'),
                  ),
                ],
              );

              final navigationBar = NavigationBar(
                backgroundColor: Colors.white10,
                indicatorColor: Colors.transparent,
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.focused)
                      ? Colors.white12
                      : Colors.transparent;
                }),
                indicatorShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                selectedIndex: _selectedPageIndex,
                onDestinationSelected: navigationDestinationSelected,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
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
                    label: 'New Image',
                    child: FloatingActionButton.small(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      splashColor: Colors.transparent,
                      elevation: 0,
                      hoverElevation: 0,
                      focusElevation: 0,
                      disabledElevation: 0,
                      highlightElevation: 0,
                      child:
                          const ImageIcon(AssetImage('assets/icons/add.png')),
                      onPressed: () {
                        pickNewImage();
                      },
                    ),
                  ),
                ],
              );

              final controlsWidget = AnimatedSize(
                key: Key("controlsWidget $_controlsWidgetKeyValue"),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                child: AnimatedSwitcher(
                    switchInCurve: Curves.easeOutQuint,
                    // switchOutCurve: Curves.easeInSine,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      // Don't transition widgets animating out
                      // as this causes issues with the crop page
                      if (child != _controlsChild) return Container();

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
                    child: _controlsChild),
              );

              final toolbar = Padding(
                padding: constraints.maxWidth > 600
                    ? const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 4,
                        bottom: 12,
                      )
                    : const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        top: 8,
                        bottom: 0,
                      ),
                child: Wrap(
                  alignment: constraints.maxWidth > 600
                      ? WrapAlignment.start
                      : WrapAlignment.center,
                  children: <Widget>[
                    Tooltip(
                      message: 'Show Original',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const ImageIcon(
                          color: Colors.white54,
                          AssetImage('assets/icons/show.png'),
                        ),
                        onPressed: () async {
                          if (_editedImageData == _originalImageData) {
                            return;
                          }

                          Uint8List? previous;
                          if (_editedImageData != null) {
                            previous = Uint8List.fromList(_editedImageData!);
                          } else {
                            previous = null;
                          }
                          setState(() {
                            _editedImageData = _originalImageData;
                          });

                          await Future.delayed(
                            const Duration(milliseconds: 1500),
                          );

                          if (_editedImageData != _originalImageData) {
                            previous = null;
                            return;
                          }

                          setState(() {
                            _editedImageData = previous;
                          });

                          previous = null;
                        },
                      ),
                    ),
                    Tooltip(
                      message: 'Undo',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: ImageIcon(
                          color: _canUndo ? Colors.white60 : Colors.white24,
                          const AssetImage('assets/icons/undo.png'),
                        ),
                        onPressed: () {
                          undo();
                        },
                      ),
                    ),
                    Tooltip(
                      message: 'Redo',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: ImageIcon(
                          color: _canRedo ? Colors.white60 : Colors.white24,
                          const AssetImage('assets/icons/redo.png'),
                        ),
                        onPressed: () {
                          redo();
                        },
                      ),
                    ),
                  ],
                ),
              );

              if (constraints.maxWidth > 600) {
                return Scaffold(
                  floatingActionButtonAnimator:
                      FloatingActionButtonAnimator.noAnimation,
                  floatingActionButtonLocation: constraints.maxHeight > 380
                      ? null
                      : FloatingActionButtonLocation.startFloat,
                  floatingActionButton: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Semantics(
                      label: 'New Image',
                      child: FloatingActionButton.small(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        backgroundColor: constraints.maxHeight > 380
                            ? Colors.grey.shade700
                            : Colors.black87,
                        foregroundColor: Colors.white,
                        focusColor: Colors.white24,
                        hoverColor: Colors.white10,
                        splashColor: Colors.transparent,
                        elevation: 0,
                        hoverElevation: 0,
                        focusElevation: 0,
                        disabledElevation: 0,
                        highlightElevation: 0,
                        child:
                            const ImageIcon(AssetImage('assets/icons/add.png')),
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
                                    SlyTitleBarBox(
                                      child: SlyDragWindowBox(),
                                    ),
                                    Expanded(
                                      child: imageWidget,
                                    ),
                                  ],
                                )
                              : imageWidget,
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                _selectedPageIndex == 3 ? double.infinity : 250,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Container(
                                    color: Colors.grey.shade900,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: _selectedPageIndex == 3 ||
                                              _selectedPageIndex == 4
                                          ? [
                                              Expanded(child: controlsWidget),
                                            ]
                                          : [
                                              Expanded(child: controlsWidget),
                                              toolbar,
                                            ],
                                    ),
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
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: SlyDragWindowBox(
                              child: Container(
                                color: Colors.white10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            !kIsWeb && Platform.isLinux ? 8 : 0,
                                      ),
                                      child: titleBar,
                                    ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(child: imageWidget),
                                  cropControls,
                                ],
                              )
                            : ListView(
                                children: _selectedPageIndex == 4
                                    ? <Widget>[
                                        imageWidget,
                                        controlsWidget,
                                      ]
                                    : <Widget>[
                                        imageWidget,
                                        toolbar,
                                        controlsWidget,
                                      ],
                              ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: navigationBar,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

import '/platform.dart';
import '/image.dart';
import '/io.dart';
import '/preferences.dart';
import '/views/crop_controls.dart';
import '/widgets/button.dart';
import '/widgets/histogram.dart';
import '/widgets/slider_row.dart';
import '/widgets/switch.dart';
import '/widgets/spinner.dart';
import '/widgets/tooltip.dart';
import '/widgets/snack_bar.dart';
import '/widgets/title_bar.dart';

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
  Widget? _histogram;

  Uint8List? _originalImageData;
  Uint8List? _editedImageData;

  StreamSubscription<String>? subscription;

  bool _saveMetadata = true;
  SlyImageFormat _saveFormat = SlyImageFormat.png;
  bool _saveOnLoad = false;

  int _rotationQuarterTurns = 0;
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
  bool _showHistogram = false;

  SlyButton? _saveButton;
  final String _saveButtonLabel = isIOS ? 'Save to Photos' : 'Save';

  Future<void> _save() async {
    final copyImage = SlyImage.from(_editedImage);

    if (_rotationQuarterTurns != 0 && _rotationQuarterTurns != 4) {
      copyImage.rotate(_rotationQuarterTurns * 90);
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
        fileExtension: _saveFormat == SlyImageFormat.png ? 'png' : 'jpg'))) {
      _saveButton?.setChild(Text(_saveButtonLabel));
      copyImage.dispose();
      return;
    }

    copyImage.dispose();

    if (mounted) {
      _saveButton?.setChild(
        const ImageIcon(
          AssetImage('assets/icons/checkmark.png'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 2500));
    }

    _saveButton?.setChild(Text(_saveButtonLabel));
  }

  void _onImageUpdate(event) {
    if (!mounted) return;

    switch (event) {
      case 'updated':
        if (_saveOnLoad) {
          _save();
          _saveOnLoad = false;
        }

        _editedImage.encode(format: SlyImageFormat.jpeg75).then((data) {
          if (!mounted) return;
          setState(() {
            _editedImageData = data;
          });
        });

        getHistogram(_editedImage).then((data) {
          if (!mounted) return;
          setState(() {
            _histogram = data;
          });
        });
    }
  }

  @override
  void initState() {
    prefs.then((value) {
      final showHistogram = value.getBool('showHistogram');
      if (showHistogram == null) return;

      setState(() {
        _showHistogram = showHistogram;
      });
    });

    _editedImage = SlyImage.from(_originalImage);
    subscription = _editedImage.controller.stream.listen(_onImageUpdate);
    updateImage();

    _originalImage.encode(format: SlyImageFormat.png).then((data) {
      if (!mounted) return;

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

    croppedImage.lightAttributes = _editedImage.lightAttributes;
    croppedImage.colorAttributes = _editedImage.colorAttributes;
    croppedImage.effectAttributes = _editedImage.effectAttributes;

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

    for (int i = 0; i < 3; i++) {
      for (MapEntry<String, SlyImageAttribute> entry in last[i].entries) {
        [
          _editedImage.lightAttributes,
          _editedImage.colorAttributes,
          _editedImage.effectAttributes
        ][i][entry.key] = entry.value;
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

  ListView _createControlsListView(
    Map<String, SlyImageAttribute> attributes,
    Key key,
    BoxConstraints constraints,
  ) {
    return ListView.builder(
      key: key,
      physics: constraints.maxWidth > 600
          ? null
          : const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: attributes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 &&
                    constraints.maxWidth > 600 &&
                    !platformHasInsetTopBar
                ? 16
                : 0,
            bottom: index == attributes.length - 1 ? 28 : 0,
            left: platformHasBackGesture ? 8 : 0,
            right: platformHasBackGesture ? 8 : 0,
          ),
          child: SlySliderRow(
            label: attributes.values.elementAt(index).name,
            value: attributes.values.elementAt(index).value,
            secondaryTrackValue: attributes.values.elementAt(index).anchor,
            min: attributes.values.elementAt(index).min,
            max: attributes.values.elementAt(index).max,
            onChanged: (value) {},
            onChangeEnd: (value) {
              _addToUndoOrRedo();
              attributes.values.elementAt(index).value = value;
              updateImage();
            },
          ),
        );
      },
    );
  }

  void _onAspectRatioSelected(double? ratio) {
    if ((_cropController != null) && (_cropController!.aspectRatio != ratio)) {
      _cropChanged = true;
      _cropController!.aspectRatio = ratio;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _saveButton ??= getSaveButton(
      _saveButtonKey,
      context,
      _saveButtonLabel,
      (value) => _saveFormat = value,
      () {
        if (_editedImage.loading) {
          _saveOnLoad = true;
        } else {
          _save();
        }
      },
    );

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

                final image = await SlyImage.fromData(await file.readAsBytes());
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
                      image: image,
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
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                        child: Image.memory(
                          _editedImageData!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
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
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).viewPadding.top,
                      ),
                      child: CropImage(
                        key: const Key('cropImageView'),
                        gridThickWidth: constraints.maxWidth > 600 ? 6 : 8,
                        gridCornerColor: Theme.of(context).colorScheme.primary,
                        gridColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.6),
                        controller: _cropController,
                        image: Image.memory(
                          _originalImageData!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                        onCrop: (rect) {
                          _cropChanged = true;
                        },
                      ),
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
                    ? EdgeInsets.only(
                        top: platformHasInsetTopBar ? 4 : 12,
                        bottom: 12,
                        left: 32,
                        right: 32,
                      )
                    : constraints.maxWidth > 600
                        ? EdgeInsets.only(
                            top: platformHasInsetTopBar ? 0 : 8,
                            bottom: 8,
                          )
                        : const EdgeInsets.only(
                            top: 12,
                            left: 12,
                            right: 12,
                          ),
                child: Transform.flip(
                  flipX: _hflip,
                  flipY: _vflip,
                  child: RotatedBox(
                    quarterTurns: _rotationQuarterTurns,
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
                                      Radius.circular(12),
                                    ),
                                    child: imageView,
                                  ),
                          ),
                  ),
                ),
              );

              final lightControls = _createControlsListView(
                _editedImage.lightAttributes,
                const Key('lightControls'),
                constraints,
              );

              final colorControls = _createControlsListView(
                _editedImage.colorAttributes,
                const Key('colorControls'),
                constraints,
              );

              final effectControls = _createControlsListView(
                _editedImage.effectAttributes,
                const Key('effectControls'),
                constraints,
              );

              final cropControls = getCropControls(
                _cropController,
                () => _portraitCrop,
                (value) {
                  setState(() {
                    _portraitCrop = value;
                  });
                },
                _onAspectRatioSelected,
                () => _rotationQuarterTurns,
                (value) {
                  setState(() {
                    _rotationQuarterTurns = value;
                  });
                },
                flipImage,
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

                setState(() {
                  switch (index) {
                    case 0:
                      _controlsChild = lightControls;
                    case 1:
                      _controlsChild = colorControls;
                    case 2:
                      _controlsChild = effectControls;
                    case 3:
                      _controlsChild = cropControls;
                    case 4:
                      _controlsChild = exportControls;
                    default:
                      _controlsChild = lightControls;
                  }
                });
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
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: SlyTooltip(
                      message: 'Light',
                      child: ImageIcon(AssetImage('assets/icons/light.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/light.png')),
                    label: Text('Light'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: SlyTooltip(
                      message: 'Color',
                      child: ImageIcon(AssetImage('assets/icons/color.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/color.png')),
                    label: Text('Color'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: SlyTooltip(
                      message: 'Effects',
                      child: ImageIcon(AssetImage('assets/icons/effects.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/effects.png')),
                    label: Text('Effects'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: SlyTooltip(
                      message: 'Crop',
                      child: ImageIcon(AssetImage('assets/icons/crop.png')),
                    ),
                    selectedIcon:
                        ImageIcon(AssetImage('assets/icons/crop.png')),
                    label: Text('Crop'),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  NavigationRailDestination(
                    icon: SlyTooltip(
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
                backgroundColor: Theme.of(context).hoverColor,
                indicatorColor: Colors.transparent,
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
                    icon: ImageIcon(AssetImage('assets/icons/light.png')),
                    label: 'Light',
                  ),
                  const NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/color.png')),
                    label: 'Color',
                  ),
                  const NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/effects.png')),
                    label: 'Effects',
                  ),
                  const NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/crop.png')),
                    label: 'Crop',
                  ),
                  const NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/export.png')),
                    label: 'Export',
                  ),
                  Semantics(
                    label: 'New Image',
                    child: FloatingActionButton.small(
                      shape: const CircleBorder(),
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
                key: Key('controlsWidget $_controlsWidgetKeyValue'),
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
                  children: <Widget?>[
                    [0, 1].contains(_selectedPageIndex)
                        ? SlyTooltip(
                            message: _showHistogram
                                ? 'Hide Histogram'
                                : 'Show Histogram',
                            child: IconButton(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              icon: ImageIcon(
                                color: Theme.of(context).hintColor,
                                const AssetImage('assets/icons/histogram.png'),
                              ),
                              onPressed: () async {
                                await (await prefs)
                                    .setBool('showHistogram', !_showHistogram);

                                setState(() {
                                  _showHistogram = !_showHistogram;
                                });
                              },
                            ),
                          )
                        : null,
                    SlyTooltip(
                      message: 'Show Original',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: ImageIcon(
                          color: Theme.of(context).hintColor,
                          const AssetImage('assets/icons/show.png'),
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
                    SlyTooltip(
                      message: 'Undo',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: ImageIcon(
                          color: _canUndo
                              ? Theme.of(context).hintColor
                              : Theme.of(context).disabledColor,
                          const AssetImage('assets/icons/undo.png'),
                        ),
                        onPressed: () {
                          undo();
                        },
                      ),
                    ),
                    SlyTooltip(
                      message: 'Redo',
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: ImageIcon(
                          color: _canRedo
                              ? Theme.of(context).hintColor
                              : Theme.of(context).disabledColor,
                          const AssetImage('assets/icons/redo.png'),
                        ),
                        onPressed: () {
                          redo();
                        },
                      ),
                    ),
                  ].whereType<Widget>().toList(),
                ),
              );

              final histogram = AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                child: [0, 1].contains(_selectedPageIndex) && _showHistogram
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: constraints.maxWidth > 600 ? 12 : 0,
                          top: (constraints.maxWidth > 600 &&
                                  platformHasInsetTopBar)
                              ? 0
                              : 8,
                        ),
                        child: SizedBox(
                          height: constraints.maxWidth > 600 ? 40 : 30,
                          width: constraints.maxWidth > 600 ? null : 150,
                          child: _histogram,
                        ),
                      )
                    : Container(),
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
                            ? Theme.of(context).focusColor
                            : Colors.black87,
                        foregroundColor: constraints.maxHeight > 380
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        focusColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        hoverColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
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
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.black,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              SlyDragWindowBox(
                                child: SlyTitleBarBox(
                                  child: Container(),
                                ),
                              ),
                              Expanded(
                                child: imageWidget,
                              ),
                            ],
                          ),
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
                                    color: Theme.of(context).cardColor,
                                    child: AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutQuint,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          SlyDragWindowBox(
                                            child: SlyTitleBarBox(
                                              child: Container(),
                                            ),
                                          ),
                                          _selectedPageIndex == 3
                                              ? Container()
                                              : histogram,
                                          Expanded(child: controlsWidget),
                                          _selectedPageIndex != 3 &&
                                                  _selectedPageIndex != 4
                                              ? toolbar
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: Theme.of(context).cardColor,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: SlyDragWindowBox(
                              child: Container(
                                color: Theme.of(context).hoverColor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    const SlyTitleBar(),
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
                      const SlyTitleBar(),
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
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [toolbar, histogram],
                                        ),
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

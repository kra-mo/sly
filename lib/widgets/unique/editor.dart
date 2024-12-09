import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';

import '/platform.dart';
import '/image.dart';
import '/history.dart';
import '/io.dart';
import '/juggler.dart';
import '/preferences.dart';
import '/widgets/controls_list.dart';
import '/widgets/button.dart';
import '/widgets/snack_bar.dart';
import '/widgets/unique/carousel.dart';
import '/widgets/unique/histogram.dart';
import '/widgets/unique/navigation.dart';
import '/widgets/unique/controls.dart';
import '/widgets/unique/crop_controls.dart';
import '/widgets/unique/export_controls.dart';
import '/widgets/unique/toolbar.dart';
import '/widgets/unique/image.dart';
import '/widgets/unique/editor_scaffold.dart';

class SlyEditorPage extends StatefulWidget {
  final String suggestedFileName;
  final SlyJuggler juggler;

  const SlyEditorPage({
    super.key,
    required this.juggler,
    this.suggestedFileName = 'Edited Image',
  });

  @override
  State<SlyEditorPage> createState() => _SlyEditorPageState();
}

class CarouselData extends InheritedWidget {
  final (bool, bool, SlyJuggler, GlobalKey) data;

  const CarouselData({
    super.key,
    required this.data,
    required super.child,
  });

  static CarouselData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CarouselData>();
  }

  static CarouselData of(BuildContext context) {
    final CarouselData? result = maybeOf(context);
    return result!;
  }

  @override
  bool updateShouldNotify(CarouselData oldWidget) => data != oldWidget.data;
}

class _SlyEditorPageState extends State<SlyEditorPage> {
  final _saveButtonKey = GlobalKey<SlyButtonState>();
  final _imageViewKey = GlobalKey();
  GlobalKey _controlsKey = GlobalKey();
  GlobalKey _carouselKey = GlobalKey();

  Widget? _controlsChild;

  CropController? get _cropController => widget.juggler.cropController;
  SlyImage get _originalImage => widget.juggler.originalImage;
  SlyImage get _editedImage => widget.juggler.editedImage!;
  set _editedImage(value) => widget.juggler.editedImage = value;

  get _lightAttributes => _editedImage.lightAttributes;
  get _colorAttributes => _editedImage.colorAttributes;
  get _effectAttributes => _editedImage.effectAttributes;
  get _geometryAttributes => _editedImage.geometryAttributes;

  bool newImage = false;

  Widget? _histogram;

  Uint8List? _originalImageData;
  Uint8List? _editedImageData;

  bool _saveMetadata = true;
  SlyImageFormat _saveFormat = SlyImageFormat.png;
  bool _saveOnLoad = false;

  bool _cropChanged = false;
  bool _portraitCrop = false;

  late final HistoryManager history = HistoryManager(
    () => _editedImage,
    () {
      updateImage();
      _controlsKey = GlobalKey();
    },
  );

  int _selectedPageIndex = 0;
  bool _showHistogram = false;
  late bool _showCarousel = widget.juggler.images.length > 1;

  SlyButton? _saveButton;
  final String _saveButtonLabel = isIOS ? 'Save to Photos' : 'Save';

  Future<void> _save() async {
    final copyImage = SlyImage.from(_editedImage);

    final rotationAttr =
        copyImage.geometryAttributes['rotation']! as SlyClamptedAttribute;

    if (![rotationAttr.min, rotationAttr.max].contains(rotationAttr.value)) {
      copyImage.rotate(rotationAttr.value * 90);
    }

    final hflip = copyImage.geometryAttributes['hflip']!.value;
    final vflip = copyImage.geometryAttributes['vflip']!.value;

    if (hflip && vflip) {
      copyImage.flip(SlyImageFlipDirection.both);
    } else if (hflip) {
      copyImage.flip(SlyImageFlipDirection.horizontal);
    } else if (vflip) {
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
      case 'image added':
        setState(() => _carouselKey = GlobalKey());

      case 'new image':
        _originalImageData = null;
        _originalImage.encode(format: SlyImageFormat.png).then((data) {
          if (!mounted) return;
          setState(() => _originalImageData = data);
        });

        _editedImageData = null;
        _editedImage.encode(format: SlyImageFormat.jpeg75).then((data) {
          if (!mounted) return;
          setState(() => _editedImageData = data);
        });

        getHistogram(_editedImage).then((data) {
          if (!mounted) return;
          setState(() => _histogram = data);
        });

        setState(() {
          newImage = true;
          _controlsKey = GlobalKey();
        });

      case 'updated':
        if (_saveOnLoad) {
          _save();
          _saveOnLoad = false;
        }

        _editedImage.encode(format: SlyImageFormat.jpeg75).then((data) {
          if (!mounted) return;
          setState(() => _editedImageData = data);
        });

        getHistogram(_editedImage).then((data) {
          if (!mounted) return;
          setState(() => _histogram = data);
        });
    }
  }

  @override
  void initState() {
    prefs.then((value) {
      final showHistogram = value.getBool('showHistogram');
      if (showHistogram == null) return;

      setState(() => _showHistogram = showHistogram);
    });

    widget.juggler.controller.stream.listen(_onImageUpdate);
    updateImage();

    _originalImage.encode(format: SlyImageFormat.png).then((data) {
      if (!mounted) return;

      setState(() => _originalImageData = data);
    });

    super.initState();
  }

  @override
  void dispose() {
    _originalImage.dispose();
    _editedImage.dispose();

    _originalImageData = null;
    _editedImageData = null;

    super.dispose();
  }

  void updateImage() async => _editedImage.applyEditsProgressive();

  Future<void> updateCroppedImage() async {
    if (_cropController?.crop == null) return;

    final croppedImage = SlyImage.from(_originalImage);
    await croppedImage.crop(_cropController!.crop);

    croppedImage.lightAttributes = _lightAttributes;
    croppedImage.colorAttributes = _colorAttributes;
    croppedImage.effectAttributes = _effectAttributes;
    croppedImage.geometryAttributes = _geometryAttributes;

    _editedImage.dispose();
    _editedImage = croppedImage;

    updateImage();
  }

  void flipImage(SlyImageFlipDirection direction) {
    if (!mounted) return;

    setState(() {
      final hflipAttr = _geometryAttributes['hflip']!;
      final vflipAttr = _geometryAttributes['vflip']!;

      switch (direction) {
        case SlyImageFlipDirection.horizontal:
          hflipAttr.value = !hflipAttr.value;
        case SlyImageFlipDirection.vertical:
          vflipAttr.value = !vflipAttr.value;
        case SlyImageFlipDirection.both:
          hflipAttr.value = !hflipAttr.value;
          vflipAttr.value = !vflipAttr.value;
      }
    });
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
              history.undo();
              return null;
            },
          ),
          RedoTextIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) {
              history.redo();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageCarousel = CarouselData(
                data: (
                  _showCarousel,
                  constraints.maxWidth > 600,
                  widget.juggler,
                  _carouselKey,
                ),
                child: const SlyImageCarousel(),
              );

              void toggleCarousel() {
                if (widget.juggler.images.length <= 1) {
                  widget.juggler.editImages(
                    context: context,
                    loadingCallback: () => showSlySnackBar(
                      context,
                      'Loading Image',
                      loading: true,
                    ),
                  );
                } else {
                  setState(() => _showCarousel = !_showCarousel);
                }
              }

              final imageView = getImageView(
                _imageViewKey,
                context,
                constraints,
                _originalImageData,
                _editedImageData,
                () => _selectedPageIndex == 3,
                _cropController,
                (rect) => _cropChanged = true,
                _geometryAttributes['hflip']!,
                _geometryAttributes['vflip']!,
                _geometryAttributes['rotation']!,
              );

              Widget getControlsChild(index) {
                switch (index) {
                  case 1:
                    return SlyControlsListView(
                      key: const Key('colorControls'),
                      attributes: _colorAttributes,
                      constraints: constraints,
                      history: history,
                      updateImage: updateImage,
                    );
                  case 2:
                    return SlyControlsListView(
                      key: const Key('effectControls'),
                      attributes: _effectAttributes,
                      constraints: constraints,
                      history: history,
                      updateImage: updateImage,
                    );
                  case 3:
                    return getCropControls(
                      _cropController,
                      () => _portraitCrop,
                      (value) => setState(() => _portraitCrop = value),
                      _onAspectRatioSelected,
                      _geometryAttributes['rotation']!,
                      (value) => setState(() {
                        _geometryAttributes['rotation']!.value = value;
                      }),
                      flipImage,
                    );
                  case 4:
                    return getExportControls(
                      constraints,
                      _saveButton,
                      () => _saveMetadata,
                      (value) => _saveMetadata = value,
                    );
                  default:
                    return SlyControlsListView(
                      key: const Key('lightControls'),
                      attributes: _lightAttributes,
                      constraints: constraints,
                      history: history,
                      updateImage: updateImage,
                    );
                }
              }

              _controlsChild ??= getControlsChild(_selectedPageIndex);

              if (newImage) {
                if (_selectedPageIndex == 3) _selectedPageIndex = 0;
                _controlsChild = getControlsChild(_selectedPageIndex);
                newImage = false;
              }

              void navigationDestinationSelected(int index) {
                if (_selectedPageIndex == index) return;
                if (_selectedPageIndex == 3 && _cropChanged == true) {
                  updateCroppedImage();
                  _cropChanged = false;
                }

                _selectedPageIndex = index;

                setState(() {
                  _controlsChild = getControlsChild(index);
                });
              }

              final navigationRail = getNavigationRail(
                () => _selectedPageIndex,
                navigationDestinationSelected,
              );
              final navigationBar = getNavigationBar(
                context,
                () => _showCarousel,
                () => _selectedPageIndex,
                navigationDestinationSelected,
                toggleCarousel,
              );

              final controlsView = getControlsView(
                _controlsKey,
                constraints,
                _controlsChild,
              );

              final toolbar = getToolbar(
                context,
                constraints,
                history,
                () => [0, 1].contains(_selectedPageIndex),
                () => _showHistogram,
                (value) => setState(() => _showHistogram = value),
                () async {
                  if (_editedImageData == _originalImageData) return;

                  Uint8List? previous;

                  if (_editedImageData != null) {
                    previous = Uint8List.fromList(_editedImageData!);
                  } else {
                    previous = null;
                  }

                  setState(() => _editedImageData = _originalImageData);

                  await Future.delayed(
                    const Duration(milliseconds: 1500),
                  );

                  if (_editedImageData != _originalImageData) {
                    previous = null;
                    return;
                  }

                  setState(() => _editedImageData = previous);

                  previous = null;
                },
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

              return getEditorScaffold(
                context,
                constraints,
                imageView,
                controlsView,
                toolbar,
                histogram,
                navigationRail,
                navigationBar,
                imageCarousel,
                () => _showCarousel,
                () => _selectedPageIndex,
                toggleCarousel,
              );
            },
          ),
        ),
      ),
    );
  }
}

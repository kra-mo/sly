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
import '/widgets/snack_bar.dart';
import '/widgets/unique/save_button.dart';
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

class _SlyEditorPageState extends State<SlyEditorPage> {
  final _saveButtonKey = GlobalKey<SlySaveButtonState>();
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

  SlySaveButton? _saveButton;
  final String _saveButtonLabel = isIOS ? 'Save to Photos' : 'Save';

  Future<void> _save() async {
    final copyImage = SlyImage.from(_editedImage);

    final rotationAttr =
        copyImage.geometryAttributes['rotation']! as SlyClampedAttribute;

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
          AssetImage('assets/icons/checkmark.webp'),
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

  void showOriginal() async {
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
  }

  Widget getControlsChild(int index, bool wideLayout) {
    switch (index) {
      case 1:
        return SlyControlsListView(
          key: const Key('colorControls'),
          attributes: _colorAttributes,
          wideLayout: wideLayout,
          history: history,
          updateImage: updateImage,
        );
      case 2:
        return SlyControlsListView(
          key: const Key('effectControls'),
          attributes: _effectAttributes,
          wideLayout: wideLayout,
          history: history,
          updateImage: updateImage,
        );
      case 3:
        return SlyCropControls(
          cropController: _cropController,
          wideLayout: wideLayout,
          setCropChanged: (value) => _cropChanged = value,
          getPortraitCrop: () => _portraitCrop,
          setPortraitCrop: (value) => setState(() => _portraitCrop = value),
          rotation: _geometryAttributes['rotation']!,
          rotate: (value) => setState(() {
            _geometryAttributes['rotation']!.value = value;
          }),
          flipImage: flipImage,
        );
      case 4:
        return SlyExportControls(
          saveButton: _saveButton,
          wideLayout: wideLayout,
          getSaveMetadata: () => _saveMetadata,
          setSaveMetadata: (value) => _saveMetadata = value,
        );
      default:
        return SlyControlsListView(
          key: const Key('lightControls'),
          attributes: _lightAttributes,
          wideLayout: wideLayout,
          history: history,
          updateImage: updateImage,
        );
    }
  }

  void navigationDestinationSelected(int index, bool wideLayout) {
    if (_selectedPageIndex == index) return;
    if (_selectedPageIndex == 3 && _cropChanged == true) {
      updateCroppedImage();
      _cropChanged = false;
    }

    _selectedPageIndex = index;

    setState(() {
      _controlsChild = getControlsChild(index, wideLayout);
    });
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
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
                final wideLayout = constraints.maxWidth > 600;

                if (newImage) {
                  if (_selectedPageIndex == 3) _selectedPageIndex = 0;
                  _controlsChild = getControlsChild(
                    _selectedPageIndex,
                    wideLayout,
                  );
                  newImage = false;
                }

                _controlsChild ??= getControlsChild(
                  _selectedPageIndex,
                  wideLayout,
                );

                _saveButton ??= SlySaveButton(
                  key: _saveButtonKey,
                  label: _saveButtonLabel,
                  setImageFormat: (value) => _saveFormat = value,
                  save: () {
                    if (_editedImage.loading) {
                      _saveOnLoad = true;
                    } else {
                      _save();
                    }
                  },
                );

                return SlyEditorScaffold(
                  imageView: SlyImageView(
                    globalKey: _imageViewKey,
                    originalImageData: _originalImageData,
                    editedImageData: _editedImageData,
                    cropController: _cropController,
                    onCrop: (rect) => _cropChanged = true,
                    wideLayout: wideLayout,
                    showCropView: () => _selectedPageIndex == 3,
                    hflip: _geometryAttributes['hflip']!,
                    vflip: _geometryAttributes['vflip']!,
                    rotation: _geometryAttributes['rotation']!,
                  ),
                  controlsView: SlyControlsView(
                    globalKey: _controlsKey,
                    wideLayout: wideLayout,
                    child: _controlsChild,
                  ),
                  toolbar: SlyToolbar(
                    wideLayout: wideLayout,
                    history: history,
                    pageHasHistogram: () => [0, 1].contains(_selectedPageIndex),
                    getShowHistogram: () => _showHistogram,
                    setShowHistogram: (value) => setState(
                      () => _showHistogram = value,
                    ),
                    showOriginal: showOriginal,
                  ),
                  histogram: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuint,
                    child: [0, 1].contains(_selectedPageIndex) && _showHistogram
                        ? Padding(
                            padding: EdgeInsets.only(
                              bottom: wideLayout ? 12 : 0,
                              top: (wideLayout && platformHasInsetTopBar)
                                  ? 0
                                  : 8,
                            ),
                            child: SizedBox(
                              height: wideLayout ? 40 : 30,
                              width: wideLayout ? null : 150,
                              child: _histogram,
                            ),
                          )
                        : Container(),
                  ),
                  navigationRail: SlyNavigationRail(
                    getSelectedPageIndex: () => _selectedPageIndex,
                    onDestinationSelected: (index) =>
                        navigationDestinationSelected(
                      index,
                      wideLayout,
                    ),
                  ),
                  navigationBar: SlyNavigationBar(
                    getSelectedPageIndex: () => _selectedPageIndex,
                    getShowCarousel: () => _showCarousel,
                    toggleCarousel: toggleCarousel,
                    onDestinationSelected: (index) =>
                        navigationDestinationSelected(
                      index,
                      wideLayout,
                    ),
                  ),
                  imageCarousel: SlyCarouselData(
                    data: (
                      _showCarousel,
                      wideLayout,
                      widget.juggler,
                      _carouselKey,
                    ),
                    child: const SlyImageCarousel(),
                  ),
                  showCarousel: _showCarousel,
                  selectedPageIndex: _selectedPageIndex,
                  toggleCarousel: toggleCarousel,
                );
              },
            ),
          ),
        ),
      );
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

import '/platform.dart';
import '/image.dart';
import '/history.dart';
import '/io.dart';
import '/carousel.dart';
import '/preferences.dart';
import '/views/navigation.dart';
import '/views/controls.dart';
import '/views/controls_list.dart';
import '/views/crop_controls.dart';
import '/views/export_controls.dart';
import '/views/toolbar.dart';
import '/views/image.dart';
import '/views/carousel.dart';
import '/views/editor_scaffold.dart';
import '/widgets/button.dart';
import '/widgets/histogram.dart';
import '/widgets/snack_bar.dart';

class SlyEditorPage extends StatefulWidget {
  final String suggestedFileName;
  final SlyCarouselProvider carouselProvider;
  final bool showCarousel;

  const SlyEditorPage({
    super.key,
    required this.carouselProvider,
    this.suggestedFileName = 'Edited Image',
    this.showCarousel = false,
  });

  @override
  State<SlyEditorPage> createState() => _SlyEditorPageState();
}

class _SlyEditorPageState extends State<SlyEditorPage> {
  final GlobalKey<SlyButtonState> _saveButtonKey = GlobalKey<SlyButtonState>();
  final GlobalKey _imageViewKey = GlobalKey();
  final GlobalKey _imageCarouselKey = GlobalKey();
  int _controlsWidgetKeyValue = 0;

  Widget? _controlsChild;

  late final SlyImage _originalImage = widget.carouselProvider.originalImage;
  late SlyImage _editedImage;
  Widget? _histogram;

  Uint8List? _originalImageData;
  Uint8List? _editedImageData;

  StreamSubscription<String>? subscription;

  bool _saveMetadata = true;
  SlyImageFormat _saveFormat = SlyImageFormat.png;
  bool _saveOnLoad = false;

  CropController? _cropController;

  bool _cropChanged = false;
  bool _portraitCrop = false;

  late final HistoryManager history = HistoryManager(
    () => _editedImage,
    () {
      updateImage();
      _controlsWidgetKeyValue++;
    },
  );

  int _selectedPageIndex = 0;
  bool _showHistogram = false;

  late bool showCarousel = widget.showCarousel;

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

    if (widget.carouselProvider.editedImage != null) {
      _editedImage = widget.carouselProvider.editedImage!;
    } else {
      _editedImage = SlyImage.from(_originalImage);
    }

    if (widget.carouselProvider.cropController != null) {
      _cropController = widget.carouselProvider.cropController!;
    } else {
      _cropController = CropController();
    }

    subscription = _editedImage.controller.stream.listen(_onImageUpdate);
    updateImage();

    _originalImage.encode(format: SlyImageFormat.png).then((data) {
      if (!mounted) return;

      setState(() => _originalImageData = data);
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

  void updateImage() async => _editedImage.applyEditsProgressive();

  Future<void> updateCroppedImage() async {
    if (_cropController?.crop == null) return;

    final croppedImage = SlyImage.from(_originalImage);
    await croppedImage.crop(_cropController!.crop);

    croppedImage.lightAttributes = _editedImage.lightAttributes;
    croppedImage.colorAttributes = _editedImage.colorAttributes;
    croppedImage.effectAttributes = _editedImage.effectAttributes;
    croppedImage.geometryAttributes = _editedImage.geometryAttributes;

    subscription?.cancel();
    _editedImage.dispose();
    _editedImage = croppedImage;
    subscription = _editedImage.controller.stream.listen(_onImageUpdate);

    updateImage();
  }

  void flipImage(SlyImageFlipDirection direction) {
    if (!mounted) return;

    setState(() {
      final hflipAttr = _editedImage.geometryAttributes['hflip']!;
      final vflipAttr = _editedImage.geometryAttributes['vflip']!;

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
    widget.carouselProvider.context = context;

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

    pickNewImage() async {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isEmpty) return;
      if (!context.mounted) return;

      showSlySnackBar(context, 'Loading Image', loading: true);

      final List<SlyImage> images = [];

      for (final file in files) {
        final image = await SlyImage.fromData(await file.readAsBytes());
        if (image == null) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showSlySnackBar(context, 'Couldn’t Load Image');
          return;
        }

        images.add(image);
      }

      if (!context.mounted) return;

      for (final image in images) {
        widget.carouselProvider.addImage(image);
      }
      widget.carouselProvider.selected = 0;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SlyEditorPage(
            suggestedFileName: 'Edited Image',
            carouselProvider: widget.carouselProvider,
            showCarousel: true,
          ),
        ),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    void toggleCarousel() {
      if (widget.carouselProvider.images.length <= 1) {
        pickNewImage();
      } else {
        setState(() => showCarousel = !showCarousel);
      }
    }

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
              final imageView = getImageView(
                _imageViewKey,
                context,
                constraints,
                _originalImageData,
                _editedImageData,
                () => _selectedPageIndex == 3,
                _cropController,
                (rect) => _cropChanged = true,
                _editedImage.geometryAttributes['hflip']!,
                _editedImage.geometryAttributes['vflip']!,
                _editedImage.geometryAttributes['rotation']!,
              );

              final lightControls = createControlsListView(
                _editedImage.lightAttributes,
                const Key('lightControls'),
                constraints,
                history,
                updateImage,
              );

              final colorControls = createControlsListView(
                _editedImage.colorAttributes,
                const Key('colorControls'),
                constraints,
                history,
                updateImage,
              );

              final effectControls = createControlsListView(
                _editedImage.effectAttributes,
                const Key('effectControls'),
                constraints,
                history,
                updateImage,
              );

              final cropControls = getCropControls(
                _cropController,
                () => _portraitCrop,
                (value) => setState(() => _portraitCrop = value),
                _onAspectRatioSelected,
                _editedImage.geometryAttributes['rotation']!,
                (value) => setState(() {
                  _editedImage.geometryAttributes['rotation']!.value = value;
                }),
                flipImage,
              );

              final exportControls = getExportControls(
                constraints,
                _saveButton,
                () => _saveMetadata,
                (value) => _saveMetadata = value,
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
                  _controlsChild = [
                    lightControls,
                    colorControls,
                    effectControls,
                    cropControls,
                    exportControls,
                  ][index];
                });
              }

              final navigationRail = getNavigationRail(
                () => _selectedPageIndex,
                navigationDestinationSelected,
              );
              final navigationBar = getNavigationBar(
                context,
                () => showCarousel,
                () => _selectedPageIndex,
                navigationDestinationSelected,
                toggleCarousel,
              );

              final imageCarousel = getImageCarousel(
                context,
                constraints,
                _imageCarouselKey,
                () => showCarousel,
                widget.carouselProvider,
                pickNewImage,
                () => _editedImage,
                () => _cropController,
              );

              final controlsView = getControlsView(
                constraints,
                _controlsWidgetKeyValue,
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
                cropControls,
                toolbar,
                histogram,
                navigationRail,
                navigationBar,
                imageCarousel,
                () => showCarousel,
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

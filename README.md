<div align="center">
  <img src="macos/Runner/Assets.xcassets/AppIcon.appiconset/Sly 128.png" width="128" height="128">

# Sly

A friendly image editor

  <img src="packaging/screenshot.png">
</div>

# About the Project

Sly is a user-friendly image editor designed for anyone to use without requiring internet access or advanced technical knowledge. Whether you're looking to make simple edits or more detailed adjustments, Sly has you covered with its offline capabilities and intuitive design.

## Features

### Light Adjustments

-   **Exposure**: Adjust the overall exposure of the image.
-   **Brightness**: Control how light or dark the image appears.
-   **Contrast**: Increase or decrease the difference between light and dark areas.
-   **Blacks**: Adjust the black levels in the image.
-   **Whites**: Adjust the white levels in the image.
-   **Midtones**: Fine-tune the mid-range tones.

### Color Adjustments

-   **Saturation**: Control the intensity of the colors.
-   **Temperature**: Adjust the color warmth (cool blue to warm yellow).
-   **Tint**: Fine-tune the balance between green and magenta tones.

### Effects Adjustments

-   **Noise Reduction**: Reduce image noise for a cleaner look.
-   **Sharpness**: Enhance the clarity and definition of the image.
-   **Sepia**: Apply a sepia-tone filter for a vintage effect.
-   **Vignette**: Darken the corners of the image for a focal point effect.
-   **Border**: Add a customizable border around the image.

### Crop and Rotate

-   **Aspect Ratio**: Choose from preset aspect ratios or crop freely by dragging corners.
-   **Rotate**: Rotate the image to the desired angle.
-   **Flip**: Flip the image horizontally or vertically.

### Export

-   **JPEG Export**: Save your image as a JPEG with adjustable quality.
-   **PNG Export**: Save your image as a lossless PNG.

### Additional Features

-   **Reset Adjustments**: Double-click any adjustment bar to reset it to its default value.
-   **Show Original**: Instantly preview the original image for comparison.
-   **Undo/Redo**: Use the undo and redo buttons to revert or reapply changes.
-   **Histogram**: View a real-time histogram of color channels (red, green, blue) to visually track changes in image data.

# Installation

## Linux

Sly is available via [Flathub](https://flathub.org/apps/page.kramo.Sly). To install the app on Linux, use the following command:

```bash
flatpak install flathub page.kramo.Sly
```

## Other Platforms

I'm planning to make the app available for all other major platforms (Android, iOS, macOS, Windows) in the near future.

For now, if you want to try out the app, you can do so at [sly.kramo.page](https://sly.kramo.page). Be aware that this version is unstable and the performance will probably be significantly worse than that of the native app.

**Issues for each platform can be found here:**

-   Android - https://github.com/kra-mo/sly/issues/12
-   iOS - https://github.com/kra-mo/sly/issues/11
-   macOS - https://github.com/kra-mo/sly/issues/9
-   Windows - https://github.com/kra-mo/sly/issues/10

## How to Use

1. Open an Image: Upload an image from your computer.
2. Make Adjustments: Use the adjustment sliders for light, color, and effects to modify the image.
3. Crop and Rotate: Resize or rotate the image using the cropping tool.
4. Preview Changes: View the histogram to track real-time changes to the image’s color balance.
5. Export: Save the edited image as JPEG or PNG with your desired quality settings.

# Contributing

If you would like to contribute a feature or an enhancement, please open an issue or [reach out](https://kramo.page/about/) before doing so, so that we can discuss details before an implementation.

Small bug fixes are always appreciated!

## Localization

For now, localization of the app is not possible, but I plan to set up translations in the near future.

## Code Structure

Here are brief descriptions of the files in the `lib` directory, detailing the main components and their functionality:

### `lib/about.dart`

This file defines the "About" dialog, which provides app information, links to the GPLv3 license, the GitHub repository, and GitHub Sponsors. It also includes a button to close the dialog.

### `lib/button.dart`

This file defines the `SlyButton`, a customizable button widget that supports actions like press, long press, hover, and focus change. It can display a suggested state with theme-based styling and provides smooth crossfade transitions between button states.

### `lib/dialog.dart`

This file defines `showSlyDialog`, a function that displays a customizable dialog or bottom sheet based on screen size. It includes animations like fade and scale transitions for larger screens and a modal bottom sheet for smaller screens.

### `lib/editor_page.dart`

This file defines the `SlyEditorPage` class, which is the main image editing interface of the app. It handles image adjustments like cropping, flipping, rotating, and applying effects. It also manages image export functionality, undo/redo, and allows users to choose file formats for saving images.

### `lib/histogram.dart`

This file generates a visual histogram for an image, displaying color data for red, green, and blue channels. It uses the `fl_chart` package to plot the histogram based on image pixel data. The histogram provides a graphical representation of the image's color distribution.

### `lib/image.dart`

This file handles image processing operations in the app. It defines the `SlyImage` class, which supports various image editing functionalities such as flipping, rotating, cropping, and adjusting attributes like brightness, contrast, and color. It also manages metadata and supports progressive image editing for performance optimization.

### `lib/preferences.dart`

This file manages the app's theme preferences using `SharedPreferences`. It includes functions to initialize preferences and display a preferences dialog where users can select between dark, light, or system themes.

### `lib/slider_row.dart`

This file defines the `SlySliderRow` widget, which combines a labeled text row and a customizable slider. It supports various visual and functional configurations, such as value labels, secondary track values, and on-change event handling.

### `lib/slider.dart`

This file defines the `SlySlider` widget, a customizable slider component that supports double-tap reset functionality, secondary track values, and various visual customizations like colors and thumb shapes. It also includes a custom `InsetSliderThumbShape` for the slider thumb's appearance.

### `lib/snack_bar.dart`

This file defines the `showSlySnackBar` function, which displays a custom snack bar with optional loading indicators. It uses a `SlySpinner` to show a loading icon alongside a message and applies custom styling for a modern look.

### `lib/spinner.dart`

This file defines the `SlySpinner` widget, which is a customized circular progress indicator with rounded stroke and adaptive behavior for different platforms.

### `lib/switch.dart`

This file defines the `SlySwitch` widget, a customized toggle switch that manages its own state and supports event handling when the switch is toggled. It includes custom colors and behavior for different states.

### `lib/theme.dart`

This file defines light and dark theme configurations for the app using `ThemeData` and `ColorScheme`. It also includes two stateless widgets, `LightTheme` and `DarkTheme`, to easily apply the respective themes to any widget subtree.

### `lib/title_bar.dart`

This file defines components for customizing the window title bar on desktop platforms. It includes `SlyDragWindowBox` for making the title bar draggable and `SlyTitleBar` for displaying a close button on Linux platforms. It adapts the title bar size based on the platform (Linux, macOS, or web).

### `lib/toggle_buttons.dart`

This file defines the `SlyToggleButtons` widget, a custom toggle button group that allows users to select one option at a time from multiple options. It supports both regular and compact modes, and calls a callback when a new option is selected.

### `lib/tooltip.dart`

This file defines the `SlyTooltip` widget, a customized tooltip with a black background, white text, and rounded corners. It has a slight delay before appearing to improve user experience.

### `lib/utils.dart`

This file provides utility functions for image handling, including decoding images (`loadImgImage`), resizing images (`getResizedImage`), and saving images either to a gallery (on mobile) or a user-specified location (on desktop and web). It supports both Flutter’s `ui.Image` and the `image` package.

### `lib/main.dart`

This file contains the main entry point of the app, initializing preferences, setting up window properties for desktop, and launching the `SlyApp`. It includes the `SlyHomePage`, which serves as the starting page, allowing users to pick an image to edit or view the "About" section.

# Roadmap

The roadmap for the project is available [here](https://github.com/users/kra-mo/projects/4).

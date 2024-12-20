import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

const isWeb = kIsWeb;
final isAndroid = !isWeb && Platform.isAndroid;
final isIOS = !isWeb && Platform.isIOS;
final isLinux = !isWeb && Platform.isLinux;
final isMacOS = !isWeb && Platform.isMacOS;
final isWindows = !isWeb && Platform.isWindows;

final isDesktop = isLinux || isMacOS || isWindows;
final isMobile = isIOS || isAndroid;
final isApplePlatform = isIOS || isMacOS;

final platformHasInsetTopBar = isLinux || isMacOS;
final platformInsetTopBarHeight = isMacOS
    ? 28.0
    : isLinux
        ? 32.0
        : 0.0;
final platformHasRightAlignedWindowControls = isLinux || isWindows;
final platformHasBackGesture = isAndroid;

final pathSeparator = Platform.pathSeparator;

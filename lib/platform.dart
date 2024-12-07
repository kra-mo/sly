import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

final isAndroid = !kIsWeb && Platform.isAndroid;
final isIOS = !kIsWeb && Platform.isIOS;
final isLinux = !kIsWeb && Platform.isLinux;
final isMacOS = !kIsWeb && Platform.isMacOS;
final isWindows = !kIsWeb && Platform.isWindows;

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

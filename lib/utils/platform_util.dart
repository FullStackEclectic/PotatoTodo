import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_delegate_io.dart'
    if (dart.library.html) 'platform_delegate_web.dart';

class PlatformUtil {
  static final PlatformDelegate _delegate = PlatformDelegate();

  static bool get isWeb => kIsWeb;

  static bool get isMobile => !kIsWeb && _delegate.isMobile;

  static bool get isDesktop => !kIsWeb && _delegate.isDesktop;

  static bool get isAndroid => !kIsWeb && _delegate.isAndroid;

  static bool get isIOS => !kIsWeb && _delegate.isIOS;

  static bool get isWindows => !kIsWeb && _delegate.isWindows;

  static bool get isMacOS => !kIsWeb && _delegate.isMacOS;

  static bool get isLinux => !kIsWeb && _delegate.isLinux;
}

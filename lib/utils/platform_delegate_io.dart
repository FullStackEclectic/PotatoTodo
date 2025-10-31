import 'dart:io';

class PlatformDelegate {
  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;
  bool get isWindows => Platform.isWindows;
  bool get isMacOS => Platform.isMacOS;
  bool get isLinux => Platform.isLinux;

  bool get isMobile => isAndroid || isIOS;
  bool get isDesktop => isWindows || isMacOS || isLinux;
}

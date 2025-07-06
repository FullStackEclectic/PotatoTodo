import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtil {
  // 检查是否是网页平台
  static bool get isWeb => kIsWeb;

  // 检查是否是移动平台（Android或iOS）
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // 检查是否是桌面平台（Windows、macOS或Linux）
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // 检查是否是Android平台
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  // 检查是否是iOS平台
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  // 检查是否是Windows平台
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  // 检查是否是macOS平台
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  // 检查是否是Linux平台
  static bool get isLinux => !kIsWeb && Platform.isLinux;
} 
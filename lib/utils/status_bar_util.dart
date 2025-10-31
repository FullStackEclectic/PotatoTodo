import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBarUtil {
  /// 设置状态栏为透明，适用于浅色主题
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 设置状态栏为透明，适用于深色主题
  static void setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// 根据主题自动设置状态栏
  static void setStatusBarForTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      setDarkStatusBar();
    } else {
      setLightStatusBar();
    }
  }

  /// 获取状态栏高度
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
}
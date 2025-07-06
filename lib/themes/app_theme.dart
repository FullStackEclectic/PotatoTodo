import 'package:flutter/material.dart';

class AppTheme {
  // 定义新颜色
  static const Color _primaryYellow = Color(0xFFFDD000);
  static const Color _accentOrange = Color(0xFFF27E00);
  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _darkBackground = Color(0xFF121212); // 使用深灰色代替纯黑，更常见

  // 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryYellow,
        onPrimary: _black, // 在黄色主色上的文本颜色
        secondary: _accentOrange,
        onSecondary: _white, // 在橙色强调色上的文本颜色
        background: _white,
        onBackground: _black,
        surface: _white,
        onSurface: _black,
        error: Colors.redAccent,
        onError: _white,
      ),
      scaffoldBackgroundColor: _white,
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryYellow,
        foregroundColor: _black, // AppBar 上的标题和图标颜色
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: _white,
        surfaceTintColor: Colors.transparent, // 避免M3的表面染色
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentOrange,
        foregroundColor: _white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return _accentOrange; // 选中时的颜色
          }
          return null; // 默认颜色
        }),
        checkColor: MaterialStateProperty.all(_white), // 复选框勾号的颜色
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryYellow, width: 2.0),
        ),
      ),
       chipTheme: ChipThemeData(
         backgroundColor: _primaryYellow.withOpacity(0.1),
         selectedColor: _accentOrange,
         labelStyle: const TextStyle(color: _black),
         secondaryLabelStyle: const TextStyle(color: _white),
         secondarySelectedColor: _accentOrange,
         selectedShadowColor: Colors.black26,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       ),
    );
  }

  // 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryYellow,
        onPrimary: _black, // 在黄色主色上的文本颜色
        secondary: _accentOrange,
        onSecondary: _black, // 在橙色强调色上的文本颜色 (可调整为白色如果黑色对比度不足)
        background: _darkBackground,
        onBackground: _white,
        surface: _darkBackground, // 或者使用稍亮的深灰 Color(0xFF1E1E1E)
        onSurface: _white,
        error: Colors.red,
        onError: _black,
      ),
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground, // 深色模式下 AppBar 使用背景色
        foregroundColor: _primaryYellow, // AppBar 上的标题和图标颜色设为主色
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF1E1E1E), // 卡片颜色比背景稍亮
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentOrange,
        foregroundColor: _black, // 同上，可调整为白色
      ),
       checkboxTheme: CheckboxThemeData(
         fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
           if (states.contains(MaterialState.selected)) {
             return _accentOrange; // 选中时的颜色
           }
           return _white.withOpacity(0.6); // 未选中时的边框颜色
         }),
         checkColor: MaterialStateProperty.all(_black), // 复选框勾号的颜色 (可调整为白色)
       ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          foregroundColor: _black, // 同上，可调整为白色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _primaryYellow, width: 2.0),
        ),
      ),
       chipTheme: ChipThemeData(
         backgroundColor: _primaryYellow.withOpacity(0.2),
         selectedColor: _accentOrange,
         labelStyle: const TextStyle(color: _white),
         secondaryLabelStyle: const TextStyle(color: _black),
         secondarySelectedColor: _accentOrange,
         selectedShadowColor: Colors.black54,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       ),
    );
  }

  static ThemeData get systemTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: WidgetsBinding.instance.platformDispatcher.platformBrightness,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
  );
} 
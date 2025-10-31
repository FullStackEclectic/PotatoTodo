import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _followSystem = true;

  ThemeProvider() {
    _loadThemePreferences();
  }

  bool get isDarkMode => _isDarkMode;
  bool get followSystem => _followSystem;
  ThemeMode get themeMode => _followSystem ? ThemeMode.system : (_isDarkMode ? ThemeMode.dark : ThemeMode.light);

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _followSystem = prefs.getBool('followSystem') ?? true;
    debugPrint('[ThemeProvider] 从SharedPreferences加载主题设置：');
    debugPrint('  - isDarkMode: $_isDarkMode');
    debugPrint('  - followSystem: $_followSystem');
    notifyListeners();
  }

  Future<void> setFollowSystem(bool value) async {
    debugPrint('[ThemeProvider] 设置followSystem: $value');
    _followSystem = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('followSystem', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    debugPrint('[ThemeProvider] 设置darkMode: $value');
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    debugPrint('[ThemeProvider] 切换主题模式，当前isDarkMode: $_isDarkMode，切换后: ${!_isDarkMode}');
    await setDarkMode(!_isDarkMode);
  }
} 
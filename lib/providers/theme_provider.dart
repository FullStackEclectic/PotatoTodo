import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _followSystem = true;
  late final Future<void> initialization;
  Future<void> _saveQueue = Future<void>.value();
  bool _hasLocalChanges = false;
  bool _disposed = false;

  ThemeProvider() {
    initialization = _loadThemePreferences();
  }

  bool get isDarkMode => _isDarkMode;
  bool get followSystem => _followSystem;
  ThemeMode get themeMode =>
      _followSystem
          ? ThemeMode.system
          : (_isDarkMode ? ThemeMode.dark : ThemeMode.light);

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;

    // A setting changed before the async read completed. Preserve that local
    // choice instead of replacing it with the stale stored value.
    if (!_hasLocalChanges) {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _followSystem = prefs.getBool('followSystem') ?? true;
    }
    debugPrint('[ThemeProvider] 从SharedPreferences加载主题设置：');
    debugPrint('  - isDarkMode: $_isDarkMode');
    debugPrint('  - followSystem: $_followSystem');
    notifyListeners();
  }

  Future<void> setFollowSystem(bool value) async {
    debugPrint('[ThemeProvider] 设置followSystem: $value');
    _hasLocalChanges = true;
    _followSystem = value;
    notifyListeners();
    await _enqueueSave((prefs) => prefs.setBool('followSystem', value));
  }

  Future<void> setDarkMode(bool value) async {
    debugPrint('[ThemeProvider] 设置darkMode: $value');
    _hasLocalChanges = true;
    _isDarkMode = value;
    notifyListeners();
    await _enqueueSave((prefs) => prefs.setBool('darkMode', value));
  }

  Future<void> toggleThemeMode() async {
    debugPrint(
      '[ThemeProvider] 切换主题模式，当前isDarkMode: $_isDarkMode，切换后: ${!_isDarkMode}',
    );
    await setDarkMode(!_isDarkMode);
  }

  Future<void> _enqueueSave(
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    final save = _saveQueue.then((_) async {
      try {
        await write(await SharedPreferences.getInstance());
      } catch (e) {
        debugPrint('[ThemeProvider] 保存主题设置出错: $e');
      }
    });
    _saveQueue = save;
    await save;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

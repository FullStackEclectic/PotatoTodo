import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();

  factory HapticService() {
    return _instance;
  }

  HapticService._internal();

  static Future<void> initialize() async {
    await _isHapticEnabled();
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback', enabled);
  }

  static Future<bool> get isEnabled => _isHapticEnabled();

  static Future<bool> _isHapticEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('haptic_feedback') ?? true;
  }

  static Future<void> lightImpact() async {
    if (await _isHapticEnabled()) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (await _isHapticEnabled()) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> heavyImpact() async {
    if (await _isHapticEnabled()) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> selectionClick() async {
    if (await _isHapticEnabled()) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> vibrate() async {
    if (await _isHapticEnabled()) {
      await HapticFeedback.vibrate();
    }
  }
} 
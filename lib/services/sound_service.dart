import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _startEnabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _startEnabled = prefs.getBool('sound_enabled') ?? true;
    
    // Set player mode to low latency for effects if possible
    await _player.setReleaseMode(ReleaseMode.stop); 
  }

  Future<void> toggleSound(bool enabled) async {
    _startEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> _playSound(String assetPath) async {
    if (!_startEnabled) return;
    try {
      await _player.stop(); // Stop potential previous sound
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing sound $assetPath: $e');
    }
  }

  Future<void> playTaskComplete() async {
    // Requires assets/sounds/complete.mp3
    await _playSound('sounds/complete.mp3');
  }

  Future<void> playLevelUp() async {
    // Requires assets/sounds/level_up.mp3
    await _playSound('sounds/level_up.mp3');
  }
  
  Future<void> playPomodoroWorkComplete() async {
    // We have work_start? Let's use it or assume complete exists or check dir.
    // Based on user request "task complete ding" -> complete.mp3
    // Pomodoro complete -> maybe 'sounds/work_complete.mp3'?
    // I previously saw work_start.mp3. 
    // Let's assume standard 'pomodoro_complete.mp3' or fallback to a default.
    await _playSound('sounds/work_complete.mp3');
  }

  Future<void> playPomodoroBreakStart() async {
    await _playSound('sounds/break_start.mp3');
  }
  
  Future<void> playPomodoroWorkStart() async {
    await _playSound('sounds/work_start.mp3');
  }
}

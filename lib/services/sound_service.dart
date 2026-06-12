import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _startEnabled = true;

  static const List<String> _soundPaths = [
    'sounds/complete.mp3',
    'sounds/level_up.mp3',
    'sounds/work_complete.mp3',
    'sounds/break_start.mp3',
    'sounds/work_start.mp3',
  ];

  bool get isSoundEnabled => _startEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _startEnabled = prefs.getBool('sound_enabled') ?? true;
    
    // Preload audio players to minimize latency
    for (final path in _soundPaths) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(path));
        _players[path] = player;
      } catch (e) {
        debugPrint('Error preloading sound $path: $e');
      }
    }
  }

  Future<void> toggleSound(bool enabled) async {
    _startEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> _playSound(String assetPath) async {
    if (!_startEnabled) return;
    try {
      var player = _players[assetPath];
      if (player == null) {
        player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(assetPath));
        _players[assetPath] = player;
      }
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('Error playing sound $assetPath: $e');
    }
  }

  Future<void> playTaskComplete() async {
    await _playSound('sounds/complete.mp3');
  }

  Future<void> playLevelUp() async {
    await _playSound('sounds/level_up.mp3');
  }
  
  Future<void> playPomodoroWorkComplete() async {
    await _playSound('sounds/work_complete.mp3');
  }

  Future<void> playPomodoroBreakStart() async {
    await _playSound('sounds/break_start.mp3');
  }
  
  Future<void> playPomodoroWorkStart() async {
    await _playSound('sounds/work_start.mp3');
  }
}

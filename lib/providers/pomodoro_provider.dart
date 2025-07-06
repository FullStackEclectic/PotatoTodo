import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';
import 'package:audioplayers/audioplayers.dart';

// 定义番茄钟状态
enum PomodoroState {
  stopped,
  running,
  paused,
}

// 定义会话类型
enum SessionType {
  work,
  shortBreak,
  longBreak,
}

class PomodoroProvider with ChangeNotifier {
  // --- Settings ---
  int _workDuration = 25 * 60; // 25 minutes
  int _shortBreakDuration = 5 * 60; // 5 minutes
  int _longBreakDuration = 15 * 60; // 15 minutes
  int _pomodorosPerLongBreak = 4; // Pomodoros before a long break
  bool _isSoundEnabled = true; // 音效开关
  bool _isVibrationEnabled = true; // 振动开关
  bool _hasValidSoundFiles = false; // 是否有有效的音频文件

  // --- State ---
  PomodoroState _currentState = PomodoroState.stopped;
  SessionType _currentSession = SessionType.work;
  int _remainingTime = 0; // in seconds
  int _currentPomodoroCount = 0; // Pomodoros completed in the current cycle
  Timer? _timer;
  AudioPlayer? _audioPlayer;

  // --- Getters ---
  PomodoroState get currentState => _currentState;
  SessionType get currentSession => _currentSession;
  int get remainingTime => _remainingTime;
  int get totalDuration {
    switch (_currentSession) {
      case SessionType.work:
        return _workDuration;
      case SessionType.shortBreak:
        return _shortBreakDuration;
      case SessionType.longBreak:
        return _longBreakDuration;
    }
  }
  int get currentPomodoroCount => _currentPomodoroCount;
  int get workDuration => _workDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get pomodorosPerLongBreak => _pomodorosPerLongBreak;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;

  // --- Initialization ---
  PomodoroProvider() {
    _resetTimerInternal(notify: false); // Initialize with work session
    _initAudioPlayer();
    _loadSettings();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // 在Web平台上，我们需要更加小心地处理音频
      if (kIsWeb) {
        _hasValidSoundFiles = false;
        debugPrint('在Web平台上禁用音频播放功能');
        return;
      }
      
      _audioPlayer = AudioPlayer();
      _hasValidSoundFiles = false; // 默认禁用音频，除非我们确认文件存在
      debugPrint('音频播放器初始化完成，但音频文件可能不可用');
    } catch (e) {
      debugPrint('初始化音频播放器失败: $e');
      _hasValidSoundFiles = false;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _workDuration = prefs.getInt('pomodoro_work_duration') ?? 25 * 60;
      _shortBreakDuration = prefs.getInt('pomodoro_short_break_duration') ?? 5 * 60;
      _longBreakDuration = prefs.getInt('pomodoro_long_break_duration') ?? 15 * 60;
      _pomodorosPerLongBreak = prefs.getInt('pomodoro_cycles') ?? 4;
      _isSoundEnabled = prefs.getBool('pomodoro_sound_enabled') ?? true;
      _isVibrationEnabled = prefs.getBool('pomodoro_vibration_enabled') ?? true;
      
      // 重置计时器以应用新设置
      _resetTimerInternal();
    } catch (e) {
      debugPrint('加载番茄钟设置出错: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('pomodoro_work_duration', _workDuration);
      await prefs.setInt('pomodoro_short_break_duration', _shortBreakDuration);
      await prefs.setInt('pomodoro_long_break_duration', _longBreakDuration);
      await prefs.setInt('pomodoro_cycles', _pomodorosPerLongBreak);
      await prefs.setBool('pomodoro_sound_enabled', _isSoundEnabled);
      await prefs.setBool('pomodoro_vibration_enabled', _isVibrationEnabled);
    } catch (e) {
      debugPrint('保存番茄钟设置出错: $e');
    }
  }

  // --- Actions ---
  void startPauseTimer() {
    if (_currentState == PomodoroState.running) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_currentState != PomodoroState.running) {
      _currentState = PomodoroState.running;
      _timer?.cancel(); // Cancel any existing timer
      _timer = Timer.periodic(const Duration(seconds: 1), _timerTick);
      notifyListeners();
    }
  }

  void _pauseTimer() {
    if (_currentState == PomodoroState.running) {
      _timer?.cancel();
      _currentState = PomodoroState.paused;
      notifyListeners();
    }
  }

  void resetTimer() {
    _resetTimerInternal();
  }

  void skipSession() {
    _moveToNextSession();
  }

  // --- Internal Logic ---
  void _timerTick(Timer timer) {
    if (_remainingTime > 0) {
      _remainingTime--;
      
      // 当剩余时间为5秒、3秒或1秒时播放提示音
      if (_isSoundEnabled && (_remainingTime == 5 || _remainingTime == 3 || _remainingTime == 1)) {
        _playTickSound();
      }
    } else {
      _moveToNextSession();
    }
    notifyListeners();
  }

  void _moveToNextSession() {
    _timer?.cancel();
    _currentState = PomodoroState.stopped;

    // 播放完成音效和震动
    _playCompletionSound();
    _vibrate();

    if (_currentSession == SessionType.work) {
      _currentPomodoroCount++;
      if (_currentPomodoroCount % _pomodorosPerLongBreak == 0) {
        _currentSession = SessionType.longBreak;
      } else {
        _currentSession = SessionType.shortBreak;
      }
    } else {
      // After any break, go back to work
      _currentSession = SessionType.work;
    }

    _resetTimerInternal(notify: false); // Reset time for the new session
    notifyListeners(); // Notify after state is fully updated
  }

  void _resetTimerInternal({bool notify = true}) {
     _timer?.cancel();
     _currentState = PomodoroState.stopped;
    switch (_currentSession) {
      case SessionType.work:
        _remainingTime = _workDuration;
        break;
      case SessionType.shortBreak:
        _remainingTime = _shortBreakDuration;
        break;
      case SessionType.longBreak:
        _remainingTime = _longBreakDuration;
        break;
    }
    if (notify) {
      notifyListeners();
    }
  }

  // --- Sound and Vibration ---
  Future<void> _playTickSound() async {
    // 在Web平台上完全跳过音频播放
    if (kIsWeb || !_hasValidSoundFiles || !_isSoundEnabled || _audioPlayer == null) {
      return;
    }
    
    try {
      await _audioPlayer!.play(AssetSource('sounds/tick.mp3'))
          .catchError((error) {
        debugPrint('播放滴答音效失败: $error');
        return null;
      });
    } catch (e) {
      debugPrint('播放计时音效出错: $e');
    }
  }

  Future<void> _playCompletionSound() async {
    // 在Web平台上完全跳过音频播放
    if (kIsWeb || !_hasValidSoundFiles || !_isSoundEnabled || _audioPlayer == null) {
      return;
    }
    
    try {
      final soundFile = _currentSession == SessionType.work 
          ? 'sounds/break_start.mp3' 
          : 'sounds/work_start.mp3';
      await _audioPlayer!.play(AssetSource(soundFile))
          .catchError((error) {
        debugPrint('播放完成音效失败: $error');
        return null;
      });
    } catch (e) {
      debugPrint('播放完成音效出错: $e');
    }
  }

  Future<void> _vibrate() async {
    // 在Web平台上跳过振动功能
    if (kIsWeb || !_isVibrationEnabled) {
      return;
    }
    
    try {
      if (_currentSession == SessionType.work) {
        // 工作阶段结束时使用强震动
        await HapticService.heavyImpact();
      } else {
        // 休息阶段结束时使用中等震动
        await HapticService.mediumImpact();
      }
    } catch (e) {
      debugPrint('执行震动反馈失败: $e');
    }
  }

  // --- Settings Management ---
  void setWorkDuration(int minutes) {
    _workDuration = minutes * 60;
    if (_currentSession == SessionType.work && _currentState == PomodoroState.stopped) {
       _resetTimerInternal();
    }
    _saveSettings();
  }
  
  void setShortBreakDuration(int minutes) {
    _shortBreakDuration = minutes * 60;
    if (_currentSession == SessionType.shortBreak && _currentState == PomodoroState.stopped) {
       _resetTimerInternal();
    }
    _saveSettings();
  }
  
  void setLongBreakDuration(int minutes) {
    _longBreakDuration = minutes * 60;
    if (_currentSession == SessionType.longBreak && _currentState == PomodoroState.stopped) {
       _resetTimerInternal();
    }
    _saveSettings();
  }
  
  void setPomodorosPerLongBreak(int count) {
    _pomodorosPerLongBreak = count;
    _saveSettings();
  }
  
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    _saveSettings();
  }
  
  void setVibrationEnabled(bool enabled) {
    _isVibrationEnabled = enabled;
    _saveSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
} 
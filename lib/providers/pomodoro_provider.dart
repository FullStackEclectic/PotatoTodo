import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'gamification_provider.dart';

// 定义番茄钟状态
enum PomodoroState { stopped, running, paused }

// 定义会话类型
enum SessionType { work, shortBreak, longBreak }

class PomodoroProvider with ChangeNotifier, WidgetsBindingObserver {
  static const int minWorkMinutes = 1;
  static const int maxWorkMinutes = 1440;
  static const int minBreakMinutes = 1;
  static const int maxBreakMinutes = 720;
  static const int minPomodorosPerLongBreak = 1;
  static const int maxPomodorosPerLongBreak = 20;

  GamificationProvider? _gamificationProvider;

  set gamificationProvider(GamificationProvider? provider) {
    _gamificationProvider = provider;
  }

  // --- Settings ---
  int _workDuration = 25 * 60; // 25 minutes
  int _shortBreakDuration = 5 * 60; // 5 minutes
  int _longBreakDuration = 15 * 60; // 15 minutes
  int _pomodorosPerLongBreak = 4; // Pomodoros before a long break
  bool _isSoundEnabled = true; // 音效开关
  bool _isVibrationEnabled = true; // 振动开关

  // --- State ---
  PomodoroState _currentState = PomodoroState.stopped;
  SessionType _currentSession = SessionType.work;
  int _remainingTime = 0; // in seconds
  int _currentPomodoroCount = 0; // Pomodoros completed in the current cycle
  Timer? _timer;
  DateTime? _backgroundTime; // Track when the app goes to background
  late final Future<void> initialization;
  final Set<String> _changedSettingsBeforeLoad = <String>{};
  Future<void> _settingsSaveQueue = Future<void>.value();
  bool _disposed = false;

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

  // Callbacks
  Function(int minutes)? onWorkCompleteCallback;

  // --- Initialization ---
  PomodoroProvider() {
    _resetTimerInternal(notify: false); // Initialize with work session
    initialization = _loadSettings();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;

      if (!_changedSettingsBeforeLoad.contains('workDuration')) {
        _workDuration = _clamp(
          prefs.getInt('pomodoro_work_duration') ?? 25 * 60,
          minWorkMinutes * 60,
          maxWorkMinutes * 60,
        );
      }
      if (!_changedSettingsBeforeLoad.contains('shortBreakDuration')) {
        _shortBreakDuration = _clamp(
          prefs.getInt('pomodoro_short_break_duration') ?? 5 * 60,
          minBreakMinutes * 60,
          maxBreakMinutes * 60,
        );
      }
      if (!_changedSettingsBeforeLoad.contains('longBreakDuration')) {
        _longBreakDuration = _clamp(
          prefs.getInt('pomodoro_long_break_duration') ?? 15 * 60,
          minBreakMinutes * 60,
          maxBreakMinutes * 60,
        );
      }
      if (!_changedSettingsBeforeLoad.contains('pomodorosPerLongBreak')) {
        _pomodorosPerLongBreak = _clamp(
          prefs.getInt('pomodoro_cycles') ?? 4,
          minPomodorosPerLongBreak,
          maxPomodorosPerLongBreak,
        );
      }
      if (!_changedSettingsBeforeLoad.contains('soundEnabled')) {
        _isSoundEnabled = prefs.getBool('pomodoro_sound_enabled') ?? true;
      }
      if (!_changedSettingsBeforeLoad.contains('vibrationEnabled')) {
        _isVibrationEnabled =
            prefs.getBool('pomodoro_vibration_enabled') ?? true;
      }

      // Apply loaded settings without interrupting an interaction that started
      // before SharedPreferences finished loading.
      if (!_disposed && _currentState == PomodoroState.stopped) {
        _resetTimerInternal();
      }
    } catch (e) {
      debugPrint('加载番茄钟设置出错: $e');
    }
  }

  Future<void> _saveSettings() async {
    final save = _settingsSaveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('pomodoro_work_duration', _workDuration);
        await prefs.setInt(
          'pomodoro_short_break_duration',
          _shortBreakDuration,
        );
        await prefs.setInt('pomodoro_long_break_duration', _longBreakDuration);
        await prefs.setInt('pomodoro_cycles', _pomodorosPerLongBreak);
        await prefs.setBool('pomodoro_sound_enabled', _isSoundEnabled);
        await prefs.setBool('pomodoro_vibration_enabled', _isVibrationEnabled);
      } catch (e) {
        debugPrint('保存番茄钟设置出错: $e');
      }
    });
    _settingsSaveQueue = save;
    await save;
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
      if (_remainingTime == 0) {
        _moveToNextSession();
        return;
      }
    } else {
      _moveToNextSession();
      return;
    }
    notifyListeners();
  }

  void _moveToNextSession({bool keepRunning = false}) {
    _timer?.cancel();
    _currentState = PomodoroState.stopped;

    // 播放完成音效和震动
    _playCompletionSound();
    _vibrate();

    if (_currentSession == SessionType.work) {
      _gamificationProvider?.onFocusSessionCompleted(_workDuration ~/ 60);
      if (onWorkCompleteCallback != null) {
        onWorkCompleteCallback!(_workDuration ~/ 60);
      }
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
    if (keepRunning) {
      _currentState = PomodoroState.running;
      _timer = Timer.periodic(const Duration(seconds: 1), _timerTick);
    }
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

  Future<void> _playCompletionSound() async {
    if (kIsWeb || !_isSoundEnabled) return;

    if (_currentSession == SessionType.work) {
      await SoundService()
          .playPomodoroWorkComplete(); // Actually break starts effectively
    } else {
      await SoundService().playPomodoroWorkStart(); // Break ends, work starts
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
    _changedSettingsBeforeLoad.add('workDuration');
    _workDuration = _clampMinutes(minutes, minWorkMinutes, maxWorkMinutes) * 60;
    if (_currentSession == SessionType.work &&
        _currentState == PomodoroState.stopped) {
      _resetTimerInternal();
    }
    _saveSettings();
  }

  void setShortBreakDuration(int minutes) {
    _changedSettingsBeforeLoad.add('shortBreakDuration');
    _shortBreakDuration =
        _clampMinutes(minutes, minBreakMinutes, maxBreakMinutes) * 60;
    if (_currentSession == SessionType.shortBreak &&
        _currentState == PomodoroState.stopped) {
      _resetTimerInternal();
    }
    _saveSettings();
  }

  void setLongBreakDuration(int minutes) {
    _changedSettingsBeforeLoad.add('longBreakDuration');
    _longBreakDuration =
        _clampMinutes(minutes, minBreakMinutes, maxBreakMinutes) * 60;
    if (_currentSession == SessionType.longBreak &&
        _currentState == PomodoroState.stopped) {
      _resetTimerInternal();
    }
    _saveSettings();
  }

  void setPomodorosPerLongBreak(int count) {
    _changedSettingsBeforeLoad.add('pomodorosPerLongBreak');
    _pomodorosPerLongBreak = _clamp(
      count,
      minPomodorosPerLongBreak,
      maxPomodorosPerLongBreak,
    );
    _saveSettings();
  }

  static int _clamp(int value, int min, int max) =>
      value.clamp(min, max).toInt();

  static int _clampMinutes(int value, int min, int max) =>
      _clamp(value, min, max);

  void setSoundEnabled(bool enabled) {
    _changedSettingsBeforeLoad.add('soundEnabled');
    _isSoundEnabled = enabled;
    _saveSettings();
  }

  void setVibrationEnabled(bool enabled) {
    _changedSettingsBeforeLoad.add('vibrationEnabled');
    _isVibrationEnabled = enabled;
    _saveSettings();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state, {
    DateTime? mockTime,
  }) {
    if (_currentState != PomodoroState.running) return;

    final now = mockTime ?? DateTime.now();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundTime = now;
    } else if (state == AppLifecycleState.resumed && _backgroundTime != null) {
      var elapsed = now.difference(_backgroundTime!).inSeconds;
      _backgroundTime = null; // Reset

      if (elapsed > 0) {
        while (_remainingTime > 0 && elapsed >= _remainingTime) {
          elapsed -= _remainingTime;
          _moveToNextSession(keepRunning: true);
        }
        if (elapsed > 0 && _remainingTime > elapsed) {
          _remainingTime -= elapsed;
          notifyListeners();
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

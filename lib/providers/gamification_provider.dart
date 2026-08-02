import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge.dart';
import '../services/sound_service.dart';

class GamificationProvider with ChangeNotifier {
  int _xp = 0;
  int _level = 1;
  List<UserBadge> _badges = UserBadge.presets;

  // Streak tracking variables
  String? _lastMorningTaskDate;
  int _consecutiveMorningDays = 0;
  String? _lastCheckInDate;
  int _consecutiveCheckInDays = 0;
  late final Future<void> initialization;
  Future<void> _saveQueue = Future<void>.value();
  bool _disposed = false;

  // Getters
  int get xp => _xp;
  int get level => _level;
  List<UserBadge> get badges => _badges;

  String? get lastMorningTaskDate => _lastMorningTaskDate;
  int get consecutiveMorningDays => _consecutiveMorningDays;
  String? get lastCheckInDate => _lastCheckInDate;
  int get consecutiveCheckInDays => _consecutiveCheckInDays;

  // Level Calculation: Level = sqrt(XP / 100) + 1 approx, or simplified steps
  // Level 1: 0-100 XP
  // Level 2: 101-300 XP (Next Level need 200)
  // Level N: Need 100 * N XP to progress
  int get xpToNextLevel => _level * 100;
  double get levelProgress => ((_xp - _totalXpForLevel(_level)) /
          (_totalXpForLevel(_level + 1) - _totalXpForLevel(_level)))
      .clamp(0.0, 1.0);

  // Helper to calculate cumulative XP needed for a level
  int _totalXpForLevel(int lvl) {
    if (lvl <= 1) return 0;
    return (lvl - 1) * 100 * (lvl) ~/ 2; // Arithmetic sum
  }

  GamificationProvider() {
    initialization = _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _xp = (prefs.getInt('user_xp') ?? 0).clamp(0, 1 << 30);
    _level = (prefs.getInt('user_level') ?? 1).clamp(1, 1 << 20);

    // Load badges progress
    final badgesJson = prefs.getString('user_badges');
    if (badgesJson != null) {
      try {
        final decoded = jsonDecode(badgesJson);
        if (decoded is! Map) throw const FormatException('invalid badge state');
        final badgeMap = Map<String, dynamic>.from(decoded);
        _badges =
            _badges.map((b) {
              if (!badgeMap.containsKey(b.id)) return b;
              final data = Map<String, dynamic>.from(badgeMap[b.id] as Map);
              final progress = data['progress'];
              if (progress is! int || progress < 0) {
                throw const FormatException('invalid badge progress');
              }
              final unlockedAt = data['unlockedAt'];
              return b.copyWith(
                progress: progress.clamp(0, b.target),
                unlockedAt:
                    unlockedAt != null
                        ? DateTime.parse(unlockedAt as String)
                        : null,
              );
            }).toList();
      } catch (error) {
        debugPrint('徽章数据损坏，已清除损坏数据: $error');
        _badges = UserBadge.presets;
        await prefs.remove('user_badges');
      }
    }

    _lastMorningTaskDate = prefs.getString('last_morning_task_date');
    _consecutiveMorningDays = prefs.getInt('consecutive_morning_days') ?? 0;
    _lastCheckInDate = prefs.getString('last_check_in_date');
    _consecutiveCheckInDays = prefs.getInt('consecutive_check_in_days') ?? 0;

    if (_disposed) return;
    notifyListeners();
    await checkInDaily();
  }

  Future<void> _saveState() async {
    final save = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_xp', _xp);
      await prefs.setInt('user_level', _level);

      final Map<String, dynamic> badgeMap = {};
      for (var b in _badges) {
        badgeMap[b.id] = {
          'progress': b.progress,
          'unlockedAt': b.unlockedAt?.toIso8601String(),
        };
      }
      await prefs.setString('user_badges', jsonEncode(badgeMap));

      if (_lastMorningTaskDate != null) {
        await prefs.setString('last_morning_task_date', _lastMorningTaskDate!);
      } else {
        await prefs.remove('last_morning_task_date');
      }
      await prefs.setInt('consecutive_morning_days', _consecutiveMorningDays);

      if (_lastCheckInDate != null) {
        await prefs.setString('last_check_in_date', _lastCheckInDate!);
      } else {
        await prefs.remove('last_check_in_date');
      }
      await prefs.setInt('consecutive_check_in_days', _consecutiveCheckInDays);
    });
    _saveQueue = save;
    await save;
  }

  void addXp(int amount, {bool save = true}) {
    _xp += amount;
    // Check level up
    int nextLevelXp = _totalXpForLevel(_level + 1);
    while (_xp >= nextLevelXp) {
      _level++;
      nextLevelXp = _totalXpForLevel(_level + 1);
      // Can trigger level up effect here or notify UI via listener
      SoundService().playLevelUp();
    }
    notifyListeners();
    if (save) {
      _saveState();
    }
  }

  // --- Badge Logic ---

  void updateBadgeProgress(BadgeType type, int amount, {bool save = true}) {
    bool dirty = false;
    _badges =
        _badges.map((b) {
          if (b.type == type && !b.isUnlocked) {
            final newProgress = b.progress + amount;
            if (newProgress >= b.target) {
              // Unlock!
              b = b.copyWith(progress: b.target, unlockedAt: DateTime.now());
              addXp(500, save: false); // Bonus XP for badge
              dirty = true;
            } else {
              b = b.copyWith(progress: newProgress);
              dirty = true;
            }
          }
          return b;
        }).toList();

    if (dirty) {
      notifyListeners();
      if (save) {
        _saveState();
      }
    }
  }

  void setBadgeProgress(BadgeType type, int value, {bool save = true}) {
    bool dirty = false;
    _badges =
        _badges.map((b) {
          if (b.type == type && !b.isUnlocked) {
            if (value >= b.target) {
              // Unlock!
              b = b.copyWith(progress: b.target, unlockedAt: DateTime.now());
              addXp(500, save: false); // Bonus XP for badge
              dirty = true;
            } else {
              b = b.copyWith(progress: value);
              dirty = true;
            }
          }
          return b;
        }).toList();

    if (dirty) {
      notifyListeners();
      if (save) {
        _saveState();
      }
    }
  }

  // Daily App Launch check-in hook
  Future<void> checkInDaily({DateTime? mockTime}) async {
    final now = mockTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    if (_lastCheckInDate == todayStr) {
      // Already checked in today
      return;
    }

    if (_lastCheckInDate == yesterdayStr) {
      _consecutiveCheckInDays += 1;
    } else {
      _consecutiveCheckInDays = 1;
    }
    _lastCheckInDate = todayStr;

    setBadgeProgress(
      BadgeType.streakFire,
      _consecutiveCheckInDays,
      save: false,
    );
    await _saveState();
  }

  // Hook for completing a task
  void onTaskCompleted({DateTime? mockTime}) {
    addXp(10, save: false); // 10 XP per task
    SoundService().playTaskComplete();
    updateBadgeProgress(BadgeType.taskMachine, 1, save: false);

    // Check for early bird
    final now = mockTime ?? DateTime.now();
    if (now.hour < 8) {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final yesterdayStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      if (_lastMorningTaskDate != todayStr) {
        if (_lastMorningTaskDate == yesterdayStr) {
          _consecutiveMorningDays += 1;
        } else {
          _consecutiveMorningDays = 1;
        }
        _lastMorningTaskDate = todayStr;
        setBadgeProgress(
          BadgeType.earlyBird,
          _consecutiveMorningDays,
          save: false,
        );
      }
    }
    _saveState();
  }

  // Hook for Pomodoro
  void onFocusSessionCompleted(int minutes) {
    addXp(minutes, save: false); // 1 XP per minute
    updateBadgeProgress(BadgeType.focusMaster, minutes, save: false);
    _saveState();
  }

  // --- Backup Support ---

  Map<String, dynamic> exportState() {
    final Map<String, dynamic> badgeMap = {};
    for (var b in _badges) {
      if (b.progress > 0 || b.isUnlocked) {
        badgeMap[b.id] = {
          'progress': b.progress,
          'unlockedAt': b.unlockedAt?.toIso8601String(),
        };
      }
    }
    return {
      'xp': _xp,
      'level': _level,
      'badges': badgeMap,
      'last_morning_task_date': _lastMorningTaskDate,
      'consecutive_morning_days': _consecutiveMorningDays,
      'last_check_in_date': _lastCheckInDate,
      'consecutive_check_in_days': _consecutiveCheckInDays,
    };
  }

  Future<void> importState(Map<String, dynamic> data) async {
    validateState(data);

    var importedXp = _xp;
    var importedLevel = _level;
    var importedBadges = _badges;
    var importedMorningDate = _lastMorningTaskDate;
    var importedMorningDays = _consecutiveMorningDays;
    var importedCheckInDate = _lastCheckInDate;
    var importedCheckInDays = _consecutiveCheckInDays;

    if (data.containsKey('xp')) importedXp = data['xp'] as int;
    if (data.containsKey('level')) importedLevel = data['level'] as int;

    if (data.containsKey('badges')) {
      if (data['badges'] is! Map) {
        throw const FormatException('游戏化字段 badges 无效');
      }
      final Map<String, dynamic> badgeMap = Map<String, dynamic>.from(
        data['badges'] as Map,
      );
      importedBadges =
          UserBadge.presets.map((b) {
            if (badgeMap.containsKey(b.id)) {
              final d = Map<String, dynamic>.from(badgeMap[b.id] as Map);
              return b.copyWith(
                progress: d['progress'] as int,
                unlockedAt:
                    d['unlockedAt'] != null
                        ? DateTime.parse(d['unlockedAt'])
                        : null,
              );
            }
            return b;
          }).toList();
    }

    if (data.containsKey('last_morning_task_date')) {
      importedMorningDate = data['last_morning_task_date'] as String?;
    }
    if (data.containsKey('consecutive_morning_days')) {
      importedMorningDays = data['consecutive_morning_days'] as int;
    }
    if (data.containsKey('last_check_in_date')) {
      importedCheckInDate = data['last_check_in_date'] as String?;
    }
    if (data.containsKey('consecutive_check_in_days')) {
      importedCheckInDays = data['consecutive_check_in_days'] as int;
    }

    _xp = importedXp;
    _level = importedLevel;
    _badges = importedBadges;
    _lastMorningTaskDate = importedMorningDate;
    _consecutiveMorningDays = importedMorningDays;
    _lastCheckInDate = importedCheckInDate;
    _consecutiveCheckInDays = importedCheckInDays;

    if (!_disposed) {
      notifyListeners();
    }
    await _saveState();
  }

  static void validateState(Map<String, dynamic> data) {
    void validateNonNegativeInt(Object? value, String name) {
      if (value is! int || value < 0) {
        throw FormatException('游戏化字段 $name 无效');
      }
    }

    if (data.containsKey('xp')) validateNonNegativeInt(data['xp'], 'xp');
    if (data.containsKey('level') &&
        (data['level'] is! int || (data['level'] as int) < 1)) {
      throw const FormatException('游戏化字段 level 无效');
    }

    final badges = data['badges'];
    if (data.containsKey('badges')) {
      if (badges is! Map) {
        throw const FormatException('游戏化字段 badges 无效');
      }
      for (final entry in badges.entries) {
        if (entry.key is! String || entry.value is! Map) {
          throw const FormatException('游戏化徽章数据无效');
        }
        final badge = Map<String, dynamic>.from(entry.value as Map);
        validateNonNegativeInt(badge['progress'], 'badges.progress');
        final unlockedAt = badge['unlockedAt'];
        if (unlockedAt != null) {
          if (unlockedAt is! String || DateTime.tryParse(unlockedAt) == null) {
            throw const FormatException('游戏化徽章解锁时间无效');
          }
        }
      }
    }

    for (final field in [
      'consecutive_morning_days',
      'consecutive_check_in_days',
    ]) {
      if (data.containsKey(field)) validateNonNegativeInt(data[field], field);
    }

    for (final field in ['last_morning_task_date', 'last_check_in_date']) {
      final value = data[field];
      if (value != null &&
          (value is! String || DateTime.tryParse(value) == null)) {
        throw FormatException('游戏化字段 $field 无效');
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

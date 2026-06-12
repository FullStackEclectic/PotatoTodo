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
  double get levelProgress => (_xp - _totalXpForLevel(_level)) / (_totalXpForLevel(_level + 1) - _totalXpForLevel(_level));

  // Helper to calculate cumulative XP needed for a level
  int _totalXpForLevel(int lvl) {
    if (lvl <= 1) return 0;
    return (lvl - 1) * 100 * (lvl) ~/ 2; // Arithmetic sum
  }

  GamificationProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('user_xp') ?? 0;
    _level = prefs.getInt('user_level') ?? 1;
    
    // Load badges progress
    final badgesJson = prefs.getString('user_badges');
    if (badgesJson != null) {
      final Map<String, dynamic> badgeMap = jsonDecode(badgesJson);
      _badges = _badges.map((b) {
        if (badgeMap.containsKey(b.id)) {
           final data = badgeMap[b.id];
           return b.copyWith(
             progress: data['progress'],
             unlockedAt: data['unlockedAt'] != null ? DateTime.parse(data['unlockedAt']) : null,
           );
        }
        return b;
      }).toList();
    }

    _lastMorningTaskDate = prefs.getString('last_morning_task_date');
    _consecutiveMorningDays = prefs.getInt('consecutive_morning_days') ?? 0;
    _lastCheckInDate = prefs.getString('last_check_in_date');
    _consecutiveCheckInDays = prefs.getInt('consecutive_check_in_days') ?? 0;

    notifyListeners();
    await checkInDaily();
  }

  Future<void> _saveState() async {
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
    _badges = _badges.map((b) {
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
    _badges = _badges.map((b) {
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
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

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

    setBadgeProgress(BadgeType.streakFire, _consecutiveCheckInDays, save: false);
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
      final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      if (_lastMorningTaskDate != todayStr) {
        if (_lastMorningTaskDate == yesterdayStr) {
          _consecutiveMorningDays += 1;
        } else {
          _consecutiveMorningDays = 1;
        }
        _lastMorningTaskDate = todayStr;
        setBadgeProgress(BadgeType.earlyBird, _consecutiveMorningDays, save: false);
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
    if (data.containsKey('xp')) _xp = data['xp'];
    if (data.containsKey('level')) _level = data['level'];
    
    if (data.containsKey('badges')) {
       final Map<String, dynamic> badgeMap = data['badges'];
       _badges = UserBadge.presets.map((b) {
        if (badgeMap.containsKey(b.id)) {
           final d = badgeMap[b.id];
           return b.copyWith(
             progress: d['progress'],
             unlockedAt: d['unlockedAt'] != null ? DateTime.parse(d['unlockedAt']) : null,
           );
        }
        return b;
      }).toList();
    }
    
    if (data.containsKey('last_morning_task_date')) _lastMorningTaskDate = data['last_morning_task_date'];
    if (data.containsKey('consecutive_morning_days')) _consecutiveMorningDays = data['consecutive_morning_days'];
    if (data.containsKey('last_check_in_date')) _lastCheckInDate = data['last_check_in_date'];
    if (data.containsKey('consecutive_check_in_days')) _consecutiveCheckInDays = data['consecutive_check_in_days'];
    
    notifyListeners();
    _saveState();
  }
}

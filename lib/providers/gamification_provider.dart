import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge.dart';
import '../services/sound_service.dart';

class GamificationProvider with ChangeNotifier {
  int _xp = 0;
  int _level = 1;
  List<UserBadge> _badges = UserBadge.presets;
  
  // Getters
  int get xp => _xp;
  int get level => _level;
  List<UserBadge> get badges => _badges;
  
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
      // Logic to parse saved badge states
      // Simple for now: just load progress map?
      // Let's iterate and update progress
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
    notifyListeners();
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
  }

  void addXp(int amount) {
    _xp += amount;
    // Check level up
    int nextLevelXp = _totalXpForLevel(_level + 1);
    while (_xp >= nextLevelXp) {
      _level++;
      nextLevelXp = _totalXpForLevel(_level + 1);
      nextLevelXp = _totalXpForLevel(_level + 1);
      // Can trigger level up effect here or notify UI via listener
      SoundService().playLevelUp();
    }
    notifyListeners();
    _saveState();
  }

  // --- Badge Logic ---
  
  void updateBadgeProgress(BadgeType type, int amount) {
    bool dirty = false;
    _badges = _badges.map((b) {
      if (b.type == type && !b.isUnlocked) {
        final newProgress = b.progress + amount;
        if (newProgress >= b.target) {
          // Unlock!
          b = b.copyWith(progress: b.target, unlockedAt: DateTime.now());
          addXp(500); // Bonus XP for badge
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
      _saveState();
    }
  }

  // Hook for completing a task
  void onTaskCompleted() {
    addXp(10); // 10 XP per task
    SoundService().playTaskComplete();
    updateBadgeProgress(BadgeType.taskMachine, 1);
    
    // Check for early bird
    final now = DateTime.now();
    if (now.hour < 8) {
       // Logic for consecutive days is complex, simple increment for now
       updateBadgeProgress(BadgeType.earlyBird, 1);
    }
  }

  // Hook for Pomodoro
  void onFocusSessionCompleted(int minutes) {
    addXp(minutes); // 1 XP per minute
    updateBadgeProgress(BadgeType.focusMaster, minutes);
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
    
    notifyListeners();
    _saveState();
  }
}

import 'package:flutter/material.dart';

enum BadgeType {
  earlyBird, // 早起鸟：连续7天早上8点前打卡
  focusMaster, // 专注大师：累计专注100小时
  taskMachine, // 任务机器：累计完成1000个任务
  planner, // 规划达人：连续30天有创建任务
  streakFire, // 连胜火焰：连续打卡30天
}

class UserBadge {
  final String id;
  final BadgeType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime? unlockedAt;
  final int progress;
  final int target;

  bool get isUnlocked => unlockedAt != null;

  UserBadge({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.unlockedAt,
    this.progress = 0,
    required this.target,
  });

  UserBadge copyWith({
    String? id,
    BadgeType? type,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    DateTime? unlockedAt,
    int? progress,
    int? target,
  }) {
    return UserBadge(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  // Define static presets
  static List<UserBadge> get presets => [
    UserBadge(
      id: 'early_bird',
      type: BadgeType.earlyBird,
      name: '早起鸟',
      description: '连续7天在早上8点前完成任务',
      icon: Icons.wb_sunny_rounded,
      color: Colors.orange,
      target: 7,
    ),
    UserBadge(
      id: 'focus_master',
      type: BadgeType.focusMaster,
      name: '专注大师',
      description: '累计专注时间达到 100 分钟', // Reduced for easier testing
      icon: Icons.timelapse_rounded,
      color: Colors.purple,
      target: 100, // Minutes
    ),
    UserBadge(
      id: 'task_machine',
      type: BadgeType.taskMachine,
      name: '任务收割机',
      description: '累计完成 50 个任务',
      icon: Icons.done_all_rounded,
      color: Colors.blueAccent,
      target: 50,
    ),
    UserBadge(
      id: 'streak_fire',
      type: BadgeType.streakFire,
      name: '坚持不懈',
      description: '连续打卡 3 天',
      icon: Icons.local_fire_department_rounded,
      color: Colors.redAccent,
      target: 3,
    ),
  ];
}

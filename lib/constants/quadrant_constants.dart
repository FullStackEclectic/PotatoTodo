import 'package:flutter/material.dart';

/// 四象限类型枚举
enum QuadrantType {
  importantUrgent,     // 重要且紧急 - 第一象限
  importantNotUrgent,  // 重要不紧急 - 第二象限
  notImportantUrgent,  // 紧急不重要 - 第三象限
  notImportantNotUrgent, // 不重要不紧急 - 第四象限
}

/// 四象限相关常量
class QuadrantConstants {
  /// 获取象限名称
  static String getQuadrantName(QuadrantType type) {
    switch (type) {
      case QuadrantType.importantUrgent:
        return '重要且紧急';
      case QuadrantType.importantNotUrgent:
        return '重要不紧急';
      case QuadrantType.notImportantUrgent:
        return '紧急不重要';
      case QuadrantType.notImportantNotUrgent:
        return '不重要不紧急';
    }
  }

  /// 获取象限描述
  static String getQuadrantDescription(QuadrantType type) {
    switch (type) {
      case QuadrantType.importantUrgent:
        return '需要立即处理的重要任务';
      case QuadrantType.importantNotUrgent:
        return '需要计划时间的重要任务';
      case QuadrantType.notImportantUrgent:
        return '可以委派给他人的紧急任务';
      case QuadrantType.notImportantNotUrgent:
        return '可以延后或不做的任务';
    }
  }

  /// 获取象限图标
  static IconData getQuadrantIcon(QuadrantType type) {
    switch (type) {
      case QuadrantType.importantUrgent:
        return Icons.whatshot;
      case QuadrantType.importantNotUrgent:
        return Icons.schedule;
      case QuadrantType.notImportantUrgent:
        return Icons.bolt;
      case QuadrantType.notImportantNotUrgent:
        return Icons.more_horiz;
    }
  }

  /// 获取象限颜色
  static Color getQuadrantColor(QuadrantType type) {
    switch (type) {
      case QuadrantType.importantUrgent:
        return Colors.red;
      case QuadrantType.importantNotUrgent:
        return Colors.blue;
      case QuadrantType.notImportantUrgent:
        return Colors.amber;
      case QuadrantType.notImportantNotUrgent:
        return Colors.green;
    }
  }
} 
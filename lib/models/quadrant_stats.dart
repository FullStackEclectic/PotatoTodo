import '../constants/quadrant_constants.dart';

/// 四象限统计数据模型
class QuadrantStats {
  // 各象限的任务数量
  final int totalTasks;
  final int importantUrgent;
  final int importantNotUrgent;
  final int notImportantUrgent;
  final int notImportantNotUrgent;

  // 已完成任务数量
  final int completedImportantUrgent;
  final int completedImportantNotUrgent;
  final int completedNotImportantUrgent;
  final int completedNotImportantNotUrgent;

  // 总任务数量
  final int totalCount;

  // 已完成任务数量
  final int completedCount;

  // 未完成任务数量
  int get pendingCount => totalCount - completedCount;

  // 各象限任务占比
  double get importantUrgentPercent =>
      totalCount > 0 ? importantUrgent / totalCount * 100 : 0;
  double get importantNotUrgentPercent =>
      totalCount > 0 ? importantNotUrgent / totalCount * 100 : 0;
  double get notImportantUrgentPercent =>
      totalCount > 0 ? notImportantUrgent / totalCount * 100 : 0;
  double get notImportantNotUrgentPercent =>
      totalCount > 0 ? notImportantNotUrgent / totalCount * 100 : 0;

  // 完成率
  double get completionRate =>
      totalCount > 0 ? completedCount / totalCount * 100 : 0;

  // 构造函数
  QuadrantStats({
    required this.totalTasks,
    this.importantUrgent = 0,
    this.importantNotUrgent = 0,
    this.notImportantUrgent = 0,
    this.notImportantNotUrgent = 0,
    this.completedImportantUrgent = 0,
    this.completedImportantNotUrgent = 0,
    this.completedNotImportantUrgent = 0,
    this.completedNotImportantNotUrgent = 0,
    int? completedCount,
    int? importantUrgentCount,
    int? importantNotUrgentCount,
    int? notImportantUrgentCount,
    int? notImportantNotUrgentCount,
  }) : totalCount =
           (importantUrgentCount ?? importantUrgent) +
           (importantNotUrgentCount ?? importantNotUrgent) +
           (notImportantUrgentCount ?? notImportantUrgent) +
           (notImportantNotUrgentCount ?? notImportantNotUrgent),
       completedCount =
           completedCount ??
           (completedImportantUrgent +
               completedImportantNotUrgent +
               completedNotImportantUrgent +
               completedNotImportantNotUrgent);

  // 根据象限类型获取任务数量
  int getCountByQuadrant(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return importantUrgent;
      case QuadrantType.importantNotUrgent:
        return importantNotUrgent;
      case QuadrantType.notImportantUrgent:
        return notImportantUrgent;
      case QuadrantType.notImportantNotUrgent:
        return notImportantNotUrgent;
    }
  }

  // 根据象限类型获取任务占比
  double getPercentByQuadrant(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return importantUrgentPercent;
      case QuadrantType.importantNotUrgent:
        return importantNotUrgentPercent;
      case QuadrantType.notImportantUrgent:
        return notImportantUrgentPercent;
      case QuadrantType.notImportantNotUrgent:
        return notImportantNotUrgentPercent;
    }
  }
}

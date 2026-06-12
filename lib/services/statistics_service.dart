import '../models/task.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';

class TimeRangeStats {
  final int totalTasks;
  final int completedTasks;
  final int importantTasks;
  final int urgentTasks;
  final double completionRate;
  final DateTime startDate;
  final DateTime endDate;

  TimeRangeStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.importantTasks,
    required this.urgentTasks,
    required this.startDate,
    required this.endDate,
  }) : completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;
}

class StatisticsService {
  final TaskProvider taskProvider;
  final CategoryProvider categoryProvider;

  StatisticsService({
    required this.taskProvider,
    required this.categoryProvider,
  });

  // 获取特定日期的任务统计
  static TimeRangeStats getDailyStats(List<Task> tasks, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    
    // 筛选出目标日期的任务
    final filteredTasks = tasks.where((task) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      return taskDate.isAtSameMomentAs(targetDate);
    }).toList();
    
    return _calculateStats(filteredTasks, targetDate, targetDate);
  }
  
  // 获取特定周的任务统计
  static TimeRangeStats getWeeklyStats(List<Task> tasks, DateTime date) {
    // 找到所在周的起始日期（周一）和结束日期（周日）
    final firstDayOfWeek = _findFirstDayOfWeek(date);
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
    
    // 筛选出该周的任务
    final filteredTasks = tasks.where((task) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      return !taskDate.isBefore(firstDayOfWeek) && 
             !taskDate.isAfter(lastDayOfWeek);
    }).toList();
    
    return _calculateStats(filteredTasks, firstDayOfWeek, lastDayOfWeek);
  }
  
  // 获取特定月的任务统计
  static TimeRangeStats getMonthlyStats(List<Task> tasks, DateTime date) {
    // 当月第一天
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    // 当月最后一天
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    
    // 筛选出该月的任务
    final filteredTasks = tasks.where((task) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      return !taskDate.isBefore(firstDayOfMonth) && 
             !taskDate.isAfter(lastDayOfMonth);
    }).toList();
    
    return _calculateStats(filteredTasks, firstDayOfMonth, lastDayOfMonth);
  }
  
  // 获取自定义日期范围的任务统计
  static TimeRangeStats getCustomRangeStats(List<Task> tasks, DateTime startDate, DateTime endDate) {
    // 确保开始日期和结束日期只包含日期部分
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    // 筛选出日期范围内的任务
    final filteredTasks = tasks.where((task) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      return !taskDate.isBefore(start) && 
             !taskDate.isAfter(end);
    }).toList();
    
    return _calculateStats(filteredTasks, start, end);
  }
  
  // 计算统计数据
  static TimeRangeStats _calculateStats(List<Task> tasks, DateTime startDate, DateTime endDate) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final importantTasks = tasks.where((task) => task.isImportant).length;
    final urgentTasks = tasks.where((task) => task.isUrgent).length;
    
    return TimeRangeStats(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      importantTasks: importantTasks,
      urgentTasks: urgentTasks,
      startDate: startDate,
      endDate: endDate,
    );
  }
  
  // 寻找日期所在周的第一天（周一）
  static DateTime _findFirstDayOfWeek(DateTime date) {
    final day = date.weekday;
    return day == 1 
        ? DateTime(date.year, date.month, date.day)
        : DateTime(date.year, date.month, date.day - (day - 1));
  }
  
  // 获取最近30天每天的任务完成情况
  static List<DailyCompletionData> getLast30DaysCompletion(List<Task> tasks) {
    final today = DateTime.now();
    final result = <DailyCompletionData>[];
    
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      // 筛选出当天的任务
      final dailyTasks = tasks.where((task) {
        final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
        return taskDate.isAtSameMomentAs(dateOnly);
      }).toList();
      
      final totalTasks = dailyTasks.length;
      final completedTasks = dailyTasks.where((task) => task.isCompleted).length;
      
      result.add(DailyCompletionData(
        date: dateOnly,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
      ));
    }
    
    return result;
  }
  
  // 获取最近12个月每月的任务完成情况
  static List<MonthlyCompletionData> getLast12MonthsCompletion(List<Task> tasks) {
    final now = DateTime.now();
    final result = <MonthlyCompletionData>[];
    
    for (int i = 11; i >= 0; i--) {
      // 计算月份：当前月-i
      final year = now.month - i <= 0 ? now.year - 1 : now.year;
      final month = now.month - i <= 0 ? now.month - i + 12 : now.month - i;
      
      // 当月第一天
      final firstDayOfMonth = DateTime(year, month, 1);
      // 当月最后一天
      final lastDayOfMonth = DateTime(year, month + 1, 0);
      
      // 筛选出该月的任务
      final monthlyTasks = tasks.where((task) {
        final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
        return !taskDate.isBefore(firstDayOfMonth) && 
               !taskDate.isAfter(lastDayOfMonth);
      }).toList();
      
      final totalTasks = monthlyTasks.length;
      final completedTasks = monthlyTasks.where((task) => task.isCompleted).length;
      
      result.add(MonthlyCompletionData(
        year: year,
        month: month,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
      ));
    }
    
    return result;
  }

  // 获取分类任务统计
  Map<TaskCategory, CategoryStats> getCategoryStats() {
    final categories = categoryProvider.categories;
    final tasks = taskProvider.tasks;
    
    final Map<TaskCategory, CategoryStats> stats = {};
    
    for (final category in categories) {
      final categoryTasks = tasks.where((task) => task.categoryId == category.id).toList();
      final completedTasks = categoryTasks.where((task) => task.isCompleted).length;
      final totalTasks = categoryTasks.length;
      
      stats[category] = CategoryStats(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        completionRate: totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0,
        importantTasks: categoryTasks.where((task) => task.isImportant).length,
        urgentTasks: categoryTasks.where((task) => task.isUrgent).length,
      );
    }
    
    return stats;
  }
  
  // 获取分类任务趋势（最近30天）
  Map<TaskCategory, List<DailyStats>> getCategoryTrends() {
    final categories = categoryProvider.categories;
    final tasks = taskProvider.tasks;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final Map<TaskCategory, List<DailyStats>> trends = {};
    
    for (final category in categories) {
      final categoryTasks = tasks.where((task) => task.categoryId == category.id).toList();
      final List<DailyStats> dailyStats = [];
      
      for (int i = 0; i < 30; i++) {
        final date = thirtyDaysAgo.add(Duration(days: i));
        final dayTasks = categoryTasks.where((task) {
          final taskDate = task.createdAt;
          return taskDate.year == date.year &&
                 taskDate.month == date.month &&
                 taskDate.day == date.day;
        }).toList();
        
        dailyStats.add(DailyStats(
          date: date,
          totalTasks: dayTasks.length,
          completedTasks: dayTasks.where((task) => task.isCompleted).length,
          importantTasks: dayTasks.where((task) => task.isImportant).length,
          urgentTasks: dayTasks.where((task) => task.isUrgent).length,
        ));
      }
      
      trends[category] = dailyStats;
    }
    
    return trends;
  }
}

class CategoryStats {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int importantTasks;
  final int urgentTasks;
  
  CategoryStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.importantTasks,
    required this.urgentTasks,
  });
}

class DailyStats {
  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  final int importantTasks;
  final int urgentTasks;
  
  DailyStats({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.importantTasks,
    required this.urgentTasks,
  });
}

// 每日任务完成数据
class DailyCompletionData {
  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  
  DailyCompletionData({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
  });
  
  double get completionRate => totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;
}

// 每月任务完成数据
class MonthlyCompletionData {
  final int year;
  final int month;
  final int totalTasks;
  final int completedTasks;
  
  MonthlyCompletionData({
    required this.year,
    required this.month,
    required this.totalTasks,
    required this.completedTasks,
  });
  
  String get monthName {
    const monthNames = ['一月', '二月', '三月', '四月', '五月', '六月', 
                         '七月', '八月', '九月', '十月', '十一月', '十二月'];
    return monthNames[month - 1];
  }
  
  double get completionRate => totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0;
} 
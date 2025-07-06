import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityRecommendationService {
  // 计算任务的优先级分数（0-100）
  static int calculatePriorityScore(Task task) {
    int score = 0;
    
    // 重要性和紧急性评分
    if (task.isImportant) score += 2;
    if (task.isUrgent) score += 2;
    
    // 截止日期评分
    if (task.dueDate != null) {
      final daysUntilDue = task.dueDate!.difference(DateTime.now()).inDays;
      if (daysUntilDue <= 1) {
        score += 3;
      } else if (daysUntilDue <= 3) {
        score += 2;
      } else if (daysUntilDue <= 7) {
        score += 1;
      }
    }
    
    return score;
  }
  
  // 获取优先级建议
  static String getPrioritySuggestion(Task task) {
    final score = calculatePriorityScore(task);
    
    if (score >= 6) {
      return '建议设置为高优先级';
    } else if (score >= 3) {
      return '建议设置为中优先级';
    } else {
      return '建议设置为低优先级';
    }
  }
  
  // 获取优先级颜色
  static Color getPriorityColor(Task task) {
    final score = calculatePriorityScore(task);
    
    if (score >= 6) {
      return Colors.red;
    } else if (score >= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  // 获取优先级图标
  static IconData getPriorityIcon(Task task) {
    final score = calculatePriorityScore(task);
    
    if (score >= 6) {
      return Icons.arrow_upward;
    } else if (score >= 3) {
      return Icons.remove;
    } else {
      return Icons.arrow_downward;
    }
  }
} 
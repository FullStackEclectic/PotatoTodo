import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/category.dart';
import '../models/task.dart';

class BackupService {
  static Future<String> createBackupJson(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final gameProvider = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );

    final Map<String, dynamic> backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'tasks': taskProvider.allTasks.map((t) => t.toJson()).toList(),
      'categories': categoryProvider.categories.map((c) => c.toJson()).toList(),
      'gamification': gameProvider.exportState(),
    };

    return jsonEncode(backupData);
  }

  static Future<void> exportData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final jsonString = await createBackupJson(context);
      final bytes = utf8.encode(jsonString);
      final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'potato_todo_backup_$nowStr.json';

      final xfile = XFile.fromData(
        bytes,
        mimeType: 'application/json',
        name: fileName,
      );

      await SharePlus.instance.share(
        ShareParams(files: [xfile], text: 'Potato Todo Data Backup'),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  static Future<void> importData(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final gameProvider = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);

    try {
      const jsonTypeGroup = XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
      );
      final file = await openFile(acceptedTypeGroups: [jsonTypeGroup]);

      if (file != null) {
        final jsonString = await file.readAsString();
        await restoreBackupWithProviders(
          taskProvider,
          categoryProvider,
          gameProvider,
          jsonString,
        );

        messenger.showSnackBar(const SnackBar(content: Text('数据恢复成功')));
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      messenger.showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  static Future<void> restoreBackupWithProviders(
    TaskProvider taskProvider,
    CategoryProvider categoryProvider,
    GamificationProvider gameProvider,
    String jsonString,
  ) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    if (data['version'] != 1) {
      throw const FormatException('不支持的备份版本');
    }

    final categories = _readRecords(data['categories'], 'categories');
    final tasks = _readRecords(data['tasks'], 'tasks');
    final parsedCategories = _parseCategories(categories);
    final parsedTasks = _parseTasks(tasks);
    _validateReferences(parsedCategories, parsedTasks);

    final gamification = _readGamificationState(data['gamification']);
    if (gamification != null) {
      GamificationProvider.validateState(gamification);
    }

    // Keep a complete in-memory snapshot so a database or notification error
    // during replacement cannot leave the user's workspace partially empty.
    final originalCategories =
        categoryProvider.categories
            .map((category) => category.toJson())
            .toList();
    final originalTasks =
        taskProvider.allTasks.map((task) => task.toJson()).toList();
    final originalGamification = gameProvider.exportState();

    try {
      await _replaceData(
        taskProvider,
        categoryProvider,
        gameProvider,
        categories,
        tasks,
        gamification,
      );
    } catch (error, stackTrace) {
      try {
        await _replaceData(
          taskProvider,
          categoryProvider,
          gameProvider,
          originalCategories,
          originalTasks,
          originalGamification,
        );
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError('恢复备份失败，且无法回滚原数据: $rollbackError'),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static Future<void> _replaceData(
    TaskProvider taskProvider,
    CategoryProvider categoryProvider,
    GamificationProvider gameProvider,
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> tasks,
    Map<String, dynamic>? gamification,
  ) async {
    await taskProvider.clearAllTasks();
    await categoryProvider.clearAllCategories(recreateDefaults: false);
    await categoryProvider.importCategories(categories);
    await taskProvider.importTasks(tasks);
    if (gamification != null) {
      await gameProvider.importState(gamification);
    }
  }

  static List<Map<String, dynamic>> _readRecords(
    Object? value,
    String fieldName,
  ) {
    if (value == null) return [];
    if (value is! List) {
      throw FormatException('备份字段 $fieldName 必须是数组');
    }

    return value.map((record) {
      if (record is! Map) {
        throw FormatException('备份字段 $fieldName 包含无效记录');
      }
      return Map<String, dynamic>.from(record);
    }).toList();
  }

  static List<TaskCategory> _parseCategories(
    List<Map<String, dynamic>> records,
  ) {
    try {
      return records.map(TaskCategory.fromJson).toList();
    } catch (error) {
      throw FormatException('备份中的分类数据无效: $error');
    }
  }

  static List<Task> _parseTasks(List<Map<String, dynamic>> records) {
    try {
      return records.map(Task.fromJson).toList();
    } catch (error) {
      throw FormatException('备份中的任务数据无效: $error');
    }
  }

  static Map<String, dynamic>? _readGamificationState(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('备份字段 gamification 无效');
    }
    return Map<String, dynamic>.from(value);
  }

  static void _validateReferences(
    List<TaskCategory> categories,
    List<Task> tasks,
  ) {
    final categoryIds = categories.map((category) => category.id).toSet();
    final taskIds = tasks.map((task) => task.id).toSet();

    if (categoryIds.length != categories.length ||
        categoryIds.any((id) => id == null || id <= 0)) {
      throw const FormatException('备份中的分类ID无效或重复');
    }
    if (taskIds.length != tasks.length ||
        taskIds.any((id) => id == null || id <= 0)) {
      throw const FormatException('备份中的任务ID无效或重复');
    }

    for (final category in categories) {
      final parentId = category.parentId;
      if (parentId != null && !categoryIds.contains(parentId)) {
        throw FormatException('分类 ${category.id} 引用了不存在的父分类');
      }
      if (parentId == category.id) {
        throw FormatException('分类 ${category.id} 存在循环父引用');
      }
    }
    for (final task in tasks) {
      final parentId = task.parentTaskId;
      if (parentId != null && !taskIds.contains(parentId)) {
        throw FormatException('任务 ${task.id} 引用了不存在的父任务');
      }
      if (parentId == task.id) {
        throw FormatException('任务 ${task.id} 存在循环父引用');
      }
      if (task.categoryId != null && !categoryIds.contains(task.categoryId)) {
        throw FormatException('任务 ${task.id} 引用了不存在的分类');
      }
    }

    _validateCategoryCycles(categories);
    _validateTaskCycles(tasks);
  }

  static void _validateCategoryCycles(List<TaskCategory> categories) {
    final byId = <int, TaskCategory>{
      for (final category in categories) category.id!: category,
    };
    for (final category in categories) {
      final visited = <int>{};
      TaskCategory? current = category;
      while (current?.parentId != null) {
        if (!visited.add(current!.id!)) {
          throw const FormatException('备份中的分类层级存在循环引用');
        }
        current = byId[current.parentId];
      }
    }
  }

  static void _validateTaskCycles(List<Task> tasks) {
    final byId = <int, Task>{for (final task in tasks) task.id!: task};
    for (final task in tasks) {
      final visited = <int>{};
      Task? current = task;
      while (current?.parentTaskId != null) {
        if (!visited.add(current!.id!)) {
          throw const FormatException('备份中的任务层级存在循环引用');
        }
        current = byId[current.parentTaskId];
      }
    }
  }
}

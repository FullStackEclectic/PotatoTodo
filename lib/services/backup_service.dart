import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/task.dart';
import '../models/category.dart';

class BackupService {
  
  static Future<String> createBackupJson(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final gameProvider = Provider.of<GamificationProvider>(context, listen: false);

    // Ensure all data is loaded
    // taskProvider.allTasks should already be loaded if app is running
    
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
    try {
      final jsonString = await createBackupJson(context);
      
      // Get temporary directory to save file
      final directory = await getTemporaryDirectory();
      final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'potato_todo_backup_$nowStr.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      // Share file - this works on Mobile to open share sheet (Save to Files, Email, etc.)
      // On desktop, it might open a dialog.
      await Share.shareXFiles([XFile(file.path)], text: 'Potato Todo Data Backup');
      
    } catch (e) {
      debugPrint('Export failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  static Future<void> importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        
        await restoreBackup(context, jsonString);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据恢复成功！请重启应用以确保所有状态刷新。')),
        );
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  static Future<void> restoreBackup(BuildContext context, String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      if (data['version'] != 1) {
        throw Exception('Unsupported backup version');
      }

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final gameProvider = Provider.of<GamificationProvider>(context, listen: false);

      // Clean existing data first to prevent duplicate entries and key conflicts
      await taskProvider.clearAllTasks();
      await categoryProvider.clearAllCategories(recreateDefaults: false);

      // Restore Categories
      if (data['categories'] != null) {
        final List<dynamic> cats = data['categories'];
        await categoryProvider.importCategories(cats.cast<Map<String, dynamic>>());
      }

      // Restore Tasks
      if (data['tasks'] != null) {
        final List<dynamic> tasks = data['tasks'];
        await taskProvider.importTasks(tasks.cast<Map<String, dynamic>>());
      }
      
      // Restore Gamification
      if (data['gamification'] != null) {
        await gameProvider.importState(data['gamification']);
      }

    } catch (e) {
      rethrow;
    }
  }
}

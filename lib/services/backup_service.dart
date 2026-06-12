import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../providers/gamification_provider.dart';

class BackupService {
  
  static Future<String> createBackupJson(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final gameProvider = Provider.of<GamificationProvider>(context, listen: false);

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
      
      await Share.shareXFiles([xfile], text: 'Potato Todo Data Backup');
      
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  static Future<void> importData(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final gameProvider = Provider.of<GamificationProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String jsonString;
        
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes != null) {
            jsonString = utf8.decode(bytes);
          } else {
            throw Exception('Failed to read backup file bytes');
          }
        } else {
          final path = file.path;
          if (path != null) {
            final ioFile = File(path);
            jsonString = await ioFile.readAsString();
          } else if (file.bytes != null) {
            jsonString = utf8.decode(file.bytes!);
          } else {
            throw Exception('File path and bytes are both unavailable');
          }
        }
        
        await restoreBackupWithProviders(taskProvider, categoryProvider, gameProvider, jsonString);
        
        messenger.showSnackBar(
          const SnackBar(content: Text('数据恢复成功！请重启应用以确保所有状态刷新。')),
        );
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  static Future<void> restoreBackupWithProviders(
    TaskProvider taskProvider,
    CategoryProvider categoryProvider,
    GamificationProvider gameProvider,
    String jsonString,
  ) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      if (data['version'] != 1) {
        throw Exception('Unsupported backup version');
      }

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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../utils/platform_util.dart';

class DataExportService {
  final TaskProvider taskProvider;
  final CategoryProvider categoryProvider;

  DataExportService({
    required this.taskProvider,
    required this.categoryProvider,
  });

  // 导出数据为JSON格式
  Future<Map<String, dynamic>> getExportData() async {
    try {
      final tasks = await taskProvider.tasks;
      final categories = await categoryProvider.categories;

      final Map<String, dynamic> exportData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'tasks': tasks.map((task) => task.toMap()).toList(),
        'categories': categories.map((category) => category.toMap()).toList(),
      };

      return exportData;
    } catch (e) {
      debugPrint('导出数据出错: $e');
      rethrow;
    }
  }

  // 将数据保存为文件并分享
  Future<void> exportAndShare() async {
    try {
      final exportData = await getExportData();
      final jsonString = jsonEncode(exportData);

      if (PlatformUtil.isWeb) {
        // Web平台处理
        _shareDataWeb(jsonString);
      } else {
        // 移动平台处理
        await _shareDataMobile(jsonString);
      }
    } catch (e) {
      debugPrint('导出并分享数据出错: $e');
      rethrow;
    }
  }

  // Web平台分享数据
  void _shareDataWeb(String jsonString) {
    // 使用clipboard API复制到剪贴板
    Clipboard.setData(ClipboardData(text: jsonString));
    // 注：Web平台无法直接下载文件，所以这里只是复制到剪贴板
    // 在实际应用中，可以提供一个UI提示用户手动保存数据
  }

  // 移动平台分享数据
  Future<void> _shareDataMobile(String jsonString) async {
    final directory = await getTemporaryDirectory();
    final fileName = 'potato_todo_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '土豆Todo数据备份',
      text: '这是您的土豆Todo应用数据备份，请妥善保管。',
    );
  }

  // 导入数据
  Future<void> importData(Map<String, dynamic> importData) async {
    try {
      // 版本检查
      final version = importData['version'] as int?;
      if (version == null || version > 1) {
        throw '不支持的数据格式版本';
      }

      // 导入分类
      final categoriesData = importData['categories'] as List<dynamic>?;
      if (categoriesData != null) {
        for (var categoryMap in categoriesData) {
          final category = TaskCategory.fromMap(categoryMap as Map<String, dynamic>);
          await categoryProvider.addCategory(category);
        }
      }

      // 导入任务
      final tasksData = importData['tasks'] as List<dynamic>?;
      if (tasksData != null) {
        for (var taskMap in tasksData) {
          final task = Task.fromMap(taskMap as Map<String, dynamic>);
          await taskProvider.addTask(task);
        }
      }
    } catch (e) {
      debugPrint('导入数据出错: $e');
      rethrow;
    }
  }

  // 从文件导入数据
  Future<void> importFromFile() async {
    try {
      if (PlatformUtil.isWeb) {
        // Web平台处理
        await _importFromFileWeb();
      } else {
        // 移动平台处理
        await _importFromFileMobile();
      }
    } catch (e) {
      debugPrint('从文件导入数据出错: $e');
      rethrow;
    }
  }

  // Web平台从文件导入
  Future<void> _importFromFileWeb() async {
    // 使用FilePicker选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final fileBytes = file.bytes;
      
      if (fileBytes != null) {
        final jsonString = String.fromCharCodes(fileBytes);
        final jsonData = jsonDecode(jsonString);
        await importData(jsonData);
      }
    }
  }

  // 移动平台从文件导入
  Future<void> _importFromFileMobile() async {
    // 使用FilePicker选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final filePath = file.path;
      
      if (filePath != null) {
        final jsonFile = File(filePath);
        final jsonString = await jsonFile.readAsString();
        final jsonData = jsonDecode(jsonString);
        await importData(jsonData);
      }
    }
  }
} 
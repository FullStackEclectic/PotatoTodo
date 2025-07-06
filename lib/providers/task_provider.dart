import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/quadrant_stats.dart';
import '../services/database_interface.dart';
import '../services/database_factory.dart';
import '../services/notification_service.dart';
import '../constants/quadrant_constants.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseInterface _db;
  final NotificationService _notificationService;
  
  List<Task> _tasks = [];
  String? _searchQuery;
  int? _selectedCategoryId;
  QuadrantType? _selectedQuadrant;
  bool _showCompletedTasks = true;
  DateTime? _startDate;
  DateTime? _endDate;

  TaskProvider(this._db, this._notificationService);

  List<Task> get tasks => _filteredTasks;
  String? get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  QuadrantType? get selectedQuadrant => _selectedQuadrant;
  bool get showCompletedTasks => _showCompletedTasks;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  
  // 获取所有任务（不过滤）
  List<Task> get allTasks => _tasks;

  List<Task> get _filteredTasks {
    List<Task> filteredTasks = List.from(_tasks);

    // 按完成状态筛选
    if (!_showCompletedTasks) {
      filteredTasks = filteredTasks.where((task) => !task.isCompleted).toList();
    }

    // 按分类筛选
    if (_selectedCategoryId != null) {
      filteredTasks = filteredTasks.where((task) => task.categoryId == _selectedCategoryId).toList();
    }

    // 按象限筛选
    if (_selectedQuadrant != null) {
      switch (_selectedQuadrant) {
        case QuadrantType.importantUrgent:
          filteredTasks = filteredTasks.where((task) => task.isImportant && task.isUrgent).toList();
          break;
        case QuadrantType.importantNotUrgent:
          filteredTasks = filteredTasks.where((task) => task.isImportant && !task.isUrgent).toList();
          break;
        case QuadrantType.notImportantUrgent:
          filteredTasks = filteredTasks.where((task) => !task.isImportant && task.isUrgent).toList();
          break;
        case QuadrantType.notImportantNotUrgent:
          filteredTasks = filteredTasks.where((task) => !task.isImportant && !task.isUrgent).toList();
          break;
        default:
          break;
      }
    }

    // 按日期范围筛选
    if (_startDate != null || _endDate != null) {
      filteredTasks = filteredTasks.where((task) {
        if (task.dueDate == null) return false;
        final taskDate = task.dueDate;
        if (_startDate != null && taskDate!.isBefore(_startDate!)) return false;
        if (_endDate != null && taskDate!.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    // 按搜索关键词筛选
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
            (task.description.isNotEmpty && task.description.toLowerCase().contains(query));
      }).toList();
    }

    return filteredTasks;
  }

  Future<void> initialize() async {
    debugPrint('[TaskProvider] 初始化TaskProvider');
    await loadTasks();
    
    // 如果没有任务，创建示例任务
    if (_tasks.isEmpty) {
      await createSampleTasks();
    }
  }

  Future<void> loadTasks() async {
    debugPrint('[TaskProvider] 开始加载任务');
    _tasks = await _db.getTasks();
    debugPrint('[TaskProvider] 加载完成，获取到 ${_tasks.length} 个任务');
    
    // 调试打印每个任务详情
    for (var task in _tasks) {
      debugPrint('任务ID: ${task.id}, 标题: ${task.title}, 重要: ${task.isImportant}, 紧急: ${task.isUrgent}, 完成: ${task.isCompleted}');
    }
    
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    final newTask = await _db.insertTask(task);
    _tasks.add(newTask);
    if (newTask.dueDate != null) {
      await _notificationService.scheduleTaskReminder(newTask);
    }
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      if (task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
    }
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    await _notificationService.cancelNotification(id);
    notifyListeners();
  }

  Future<void> setTaskDueDate(Task task, DateTime? dueDate) async {
    final updatedTask = task.copyWith(dueDate: dueDate);
    await updateTask(updatedTask);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> setTaskImportance(Task task, bool isImportant) async {
    final updatedTask = task.copyWith(isImportant: isImportant);
    await updateTask(updatedTask);
  }

  Future<void> setTaskUrgency(Task task, bool isUrgent) async {
    final updatedTask = task.copyWith(isUrgent: isUrgent);
    await updateTask(updatedTask);
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);

    // 更新所有任务的位置
    final reorderedTasks = List<Task>.from(_tasks);
    for (var i = 0; i < reorderedTasks.length; i++) {
      final task = reorderedTasks[i];
      await updateTask(task);
    }
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    // 如果设置了分类，清除象限筛选
    if (categoryId != null) {
      _selectedQuadrant = null;
    }
    notifyListeners();
  }

  void setSelectedQuadrant(QuadrantType? quadrant) {
    _selectedQuadrant = quadrant;
    notifyListeners();
  }

  void setShowCompletedTasks(bool show) {
    _showCompletedTasks = show;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  List<Task> getTasksByDate(DateTime date) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = task.dueDate;
      return taskDate!.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();
  }

  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = task.dueDate;
      return taskDate!.isAfter(start) && taskDate.isBefore(end);
    }).toList();
  }

  List<Task> getTasksByCategory(int categoryId) {
    return _tasks.where((task) => task.categoryId == categoryId).toList();
  }

  List<Task> getTasksByQuadrant(QuadrantType quadrant) {
    List<Task> result;
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        result = _tasks.where((task) => task.isImportant && task.isUrgent).toList();
        break;
      case QuadrantType.importantNotUrgent:
        result = _tasks.where((task) => task.isImportant && !task.isUrgent).toList();
        break;
      case QuadrantType.notImportantUrgent:
        result = _tasks.where((task) => !task.isImportant && task.isUrgent).toList();
        break;
      case QuadrantType.notImportantNotUrgent:
        result = _tasks.where((task) => !task.isImportant && !task.isUrgent).toList();
        break;
      default:
        result = [];
        break;
    }
    debugPrint('[TaskProvider] 获取象限 $quadrant 的任务，数量: ${result.length}');
    return result;
  }

  // 获取四象限统计数据
  QuadrantStats getQuadrantStats() {
    // 计算各象限任务数量
    int importantUrgentCount = 0;
    int importantNotUrgentCount = 0;
    int notImportantUrgentCount = 0;
    int notImportantNotUrgentCount = 0;
    int completedCount = 0;
    
    for (var task in _tasks) {
      // 统计已完成任务数量
      if (task.isCompleted) {
        completedCount++;
      }
      
      // 按四象限分类统计
      if (task.isImportant && task.isUrgent) {
        importantUrgentCount++;
      } else if (task.isImportant && !task.isUrgent) {
        importantNotUrgentCount++;
      } else if (!task.isImportant && task.isUrgent) {
        notImportantUrgentCount++;
      } else {
        notImportantNotUrgentCount++;
      }
    }
    
    return QuadrantStats(
      totalTasks: _tasks.length,
      importantUrgentCount: importantUrgentCount,
      importantNotUrgentCount: importantNotUrgentCount,
      notImportantUrgentCount: notImportantUrgentCount,
      notImportantNotUrgentCount: notImportantNotUrgentCount,
      completedCount: completedCount,
    );
  }
  
  // 获取特定象限的任务数量
  int getCountByQuadrant(QuadrantType quadrant) {
    return getTasksByQuadrant(quadrant).length;
  }
  
  // 获取特定象限的已完成任务数量
  int getCompletedCountByQuadrant(QuadrantType quadrant) {
    return getTasksByQuadrant(quadrant).where((task) => task.isCompleted).length;
  }
  
  // 获取特定象限的完成率
  double getCompletionRateByQuadrant(QuadrantType quadrant) {
    final totalInQuadrant = getTasksByQuadrant(quadrant).length;
    if (totalInQuadrant == 0) return 0;
    
    final completedInQuadrant = getCompletedCountByQuadrant(quadrant);
    return completedInQuadrant / totalInQuadrant * 100;
  }

  int getPendingCountByQuadrant(QuadrantType quadrant) {
    return getTasksByQuadrant(quadrant).where((task) => !task.isCompleted).length;
  }

  // 创建示例任务数据
  Future<void> createSampleTasks() async {
    debugPrint('[TaskProvider] 创建示例任务');
    
    // 重要且紧急的任务
    await addTask(Task(
      title: '完成项目报告',
      description: '明天截止的项目季度报告',
      isImportant: true,
      isUrgent: true,
      isCompleted: false,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ));
    
    await addTask(Task(
      title: '准备客户演示',
      description: '为下午的客户会议准备演示材料',
      isImportant: true,
      isUrgent: true,
      isCompleted: false,
      dueDate: DateTime.now(),
    ));
    
    // 重要不紧急的任务
    await addTask(Task(
      title: '学习Flutter高级主题',
      description: '深入学习状态管理和性能优化',
      isImportant: true,
      isUrgent: false,
      isCompleted: false,
    ));
    
    await addTask(Task(
      title: '开始健身计划',
      description: '每周三天，包括有氧和力量训练',
      isImportant: true,
      isUrgent: false,
      isCompleted: false,
    ));
    
    // 紧急不重要的任务
    await addTask(Task(
      title: '回复邮件',
      description: '回复积压的非关键邮件',
      isImportant: false,
      isUrgent: true,
      isCompleted: false,
    ));
    
    await addTask(Task(
      title: '购买办公用品',
      description: '纸张、笔和其他办公用品快用完了',
      isImportant: false,
      isUrgent: true,
      isCompleted: false,
    ));
    
    // 不重要不紧急的任务
    await addTask(Task(
      title: '整理电子邮件文件夹',
      description: '删除旧邮件，创建新的分类文件夹',
      isImportant: false,
      isUrgent: false,
      isCompleted: false,
    ));
    
    await addTask(Task(
      title: '浏览新技术博客',
      description: '了解行业最新动态和趋势',
      isImportant: false,
      isUrgent: false,
      isCompleted: false,
    ));
    
    debugPrint('[TaskProvider] 创建了8个示例任务');
  }

  // 计算指定象限的任务数量
  int countTasksByQuadrant(QuadrantType quadrant) {
    return _tasks.where((task) {
      return task.quadrant == quadrant;
    }).length;
  }

  // 计算指定象限已完成的任务数量
  int countCompletedTasksByQuadrant(QuadrantType quadrant) {
    return _tasks.where((task) {
      return task.quadrant == quadrant && task.isCompleted;
    }).length;
  }
} 
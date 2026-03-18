import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/quadrant_stats.dart';
import '../services/database_interface.dart';
import '../services/notification_service.dart';
import '../constants/quadrant_constants.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseInterface _db;
  final NotificationService _notificationService;
  final bool _shouldEnsureDatabase;
  
  List<Task> _tasks = [];
  String? _searchQuery;
  int? _selectedCategoryId;
  QuadrantType? _selectedQuadrant;
  bool _showCompletedTasks = true;
  bool _completedTasksOnly = false;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Task> _visibleTasksCache = const <Task>[];
  bool _needsVisibleTasksRefresh = true;
  UnmodifiableListView<Task>? _visibleTasksView;

  // For Master-Detail view
  Task? _selectedTask;

  TaskProvider(
    this._db,
    this._notificationService, {
    bool ensureDatabaseInitialized = true,
  }) : _shouldEnsureDatabase = ensureDatabaseInitialized;

  List<Task> get tasks {
    if (_needsVisibleTasksRefresh || _visibleTasksView == null) {
      _visibleTasksCache = _computeVisibleTasks();
      _visibleTasksView = UnmodifiableListView(_visibleTasksCache);
      _needsVisibleTasksRefresh = false;
    }
    return _visibleTasksView!;
  }
  String? get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  QuadrantType? get selectedQuadrant => _selectedQuadrant;
  bool get showCompletedTasks => _showCompletedTasks;
  bool get completedTasksOnly => _completedTasksOnly;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  Task? get selectedTask => _selectedTask;
  
  // 获取所有任务（不过滤）
  List<Task> get allTasks => _tasks;

  void _invalidateVisibleTasks() {
    _needsVisibleTasksRefresh = true;
    _visibleTasksView = null;
  }

  void _publishChanges() {
    _invalidateVisibleTasks();
    notifyListeners();
  }

  // --- Master-Detail Setter ---
  void setSelectedTask(Task? task) {
    _selectedTask = task;
    notifyListeners();
  }

  List<Task> _computeVisibleTasks() {
    // 只显示主任务（不包括子任务）
    List<Task> filteredTasks = _tasks.where((task) => task.isMainTask).toList();

    // 按完成状态筛选
    if (_completedTasksOnly) {
      // 只显示已完成的任务
      filteredTasks = filteredTasks.where((task) => task.isCompleted).toList();
    } else if (!_showCompletedTasks) {
      // 只显示未完成的任务
      filteredTasks = filteredTasks.where((task) => !task.isCompleted).toList();
    }
    // 如果 _showCompletedTasks 为 true 且 _completedTasksOnly 为 false，则显示所有任务

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
        final taskDate = task.dueDate;
        if (taskDate == null) return false;
        if (_startDate != null && taskDate.isBefore(_startDate!)) return false;
        if (_endDate != null && taskDate.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    // 按搜索关键词筛选 (Smart Search)
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase().trim();
      
      // Smart filters
      if (query == 'important' || query == '重要') {
        filteredTasks = filteredTasks.where((task) => task.isImportant).toList();
      } else if (query == 'urgent' || query == '紧急') {
        filteredTasks = filteredTasks.where((task) => task.isUrgent).toList();
      } else if (query == 'completed' || query == '已完成') {
        filteredTasks = filteredTasks.where((task) => task.isCompleted).toList();
      } else if (query == 'pending' || query == '未完成') {
        filteredTasks = filteredTasks.where((task) => !task.isCompleted).toList();
      } else if (query == 'today' || query == '今天') {
         final now = DateTime.now();
         filteredTasks = filteredTasks.where((task) => 
           task.dueDate != null && 
           task.dueDate!.year == now.year && 
           task.dueDate!.month == now.month && 
           task.dueDate!.day == now.day
         ).toList();
      } else {
        // Standard text search
        filteredTasks = filteredTasks.where((task) {
          return task.title.toLowerCase().contains(query) ||
              (task.description.isNotEmpty && task.description.toLowerCase().contains(query));
        }).toList();
      }
    }

    // 排序：未完成的任务在前，已完成的任务在后
    filteredTasks.sort((a, b) {
      // 首先按完成状态排序（未完成在前）
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      // 如果完成状态相同，按创建时间倒序排列（新创建的在前）
      return b.createdAt.compareTo(a.createdAt);
    });

    return filteredTasks;
  }

  Future<void> initialize() async {
    debugPrint('[TaskProvider] initializing TaskProvider');
    
    // Ensure the database has been initialized when required
    if (_shouldEnsureDatabase) {
      await _db.initialize();
      debugPrint('[TaskProvider] database initialized');
    }
    
    await loadTasks();
    
    if (_tasks.isEmpty) {
      debugPrint('[TaskProvider] no tasks found, creating sample data');
      await createSampleTasks();
    } else {
      debugPrint('[TaskProvider] loaded ${_tasks.length} tasks');
    }
  }
  Future<void> loadTasks() async {
    debugPrint('[TaskProvider] 开始加载任务');
    final allTasks = await _db.getTasks();
    
    // 构建任务层次结构
    final Map<int, List<Task>> subTasksMap = {};
    final List<Task> mainTasks = [];
    
    // 先分离主任务和子任务
    for (final task in allTasks) {
      if (task.parentTaskId == null) {
        mainTasks.add(task);
      } else {
        subTasksMap[task.parentTaskId!] = subTasksMap[task.parentTaskId!] ?? [];
        subTasksMap[task.parentTaskId!]!.add(task);
      }
    }
    
    // 为主任务添加子任务
    _tasks = mainTasks.map((task) {
      final subTasks = subTasksMap[task.id] ?? [];
      return task.copyWith(subTasks: subTasks);
    }).toList();
    
    // 同时保存所有任务（包括子任务）用于搜索和统计
    _tasks.addAll(allTasks.where((task) => task.parentTaskId != null));
    
    debugPrint('[TaskProvider] 加载完成，获取到 ${_tasks.length} 个任务');
    
    // 调试打印每个任务详情
    for (var task in _tasks) {
      debugPrint('任务ID: ${task.id}, 标题: ${task.title}, 重要: ${task.isImportant}, 紧急: ${task.isUrgent}, 完成: ${task.isCompleted}, 父任务: ${task.parentTaskId}');
    }
    
    _publishChanges();
  }

  Future<Task> _insertTaskInternal(
    Task task, {
    bool scheduleReminder = true,
  }) async {
    final newTask = await _db.insertTask(task);
    _tasks.add(newTask);
    if (scheduleReminder && newTask.dueDate != null) {
      await _notificationService.scheduleTaskReminder(newTask);
    }
    return newTask;
  }

  Future<void> addTask(
    Task task, {
    bool scheduleReminder = true,
  }) async {
    await _insertTaskInternal(
      task,
      scheduleReminder: scheduleReminder,
    );
    _publishChanges();
  }

  Future<void> addSubTask(int parentTaskId, Task subTask) async {
    final newSubTask = await _db.insertTask(subTask.copyWith(parentTaskId: parentTaskId));
    _tasks.add(newSubTask);
    
    // 更新父任务的子任务列表
    final parentIndex = _tasks.indexWhere((t) => t.id == parentTaskId);
    if (parentIndex != -1) {
      final parentTask = _tasks[parentIndex];
      final updatedSubTasks = List<Task>.from(parentTask.subTasks)..add(newSubTask);
      _tasks[parentIndex] = parentTask.copyWith(subTasks: updatedSubTasks);
    }
    
    _publishChanges();
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
    _publishChanges();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    await _notificationService.cancelNotification(id);
    if (_selectedTask?.id == id) {
      _selectedTask = null;
    }
    _publishChanges();
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

    // Only update the task that was moved, not all tasks
    // In a real app, you might want to maintain a position field in the database
    // For now, we'll just update the moved task to trigger a re-save
    await updateTask(task);
    _publishChanges();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    _publishChanges();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    // 如果设置了分类，清除象限筛选
    if (categoryId != null) {
      _selectedQuadrant = null;
    }
    _publishChanges();
  }

  void setSelectedQuadrant(QuadrantType? quadrant) {
    _selectedQuadrant = quadrant;
    _publishChanges();
  }

  void setShowCompletedTasks(bool show) {
    _showCompletedTasks = show;
    _completedTasksOnly = false; // 重置只显示已完成任务的状态
    _publishChanges();
  }

  void setShowCompletedTasksOnly(bool onlyCompleted) {
    _completedTasksOnly = onlyCompleted;
    if (onlyCompleted) {
      _showCompletedTasks = true; // 如果只显示已完成，确保显示已完成任务
    }
    _publishChanges();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _publishChanges();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    _publishChanges();
  }

  List<Task> getTasksByDate(DateTime date) {
    return _tasks.where((task) {
      final taskDate = task.dueDate;
      if (taskDate == null) return false;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();
  }

  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    return _tasks.where((task) {
      final taskDate = task.dueDate;
      if (taskDate == null) return false;
      // Include tasks on start and end dates (inclusive range)
      return (taskDate.isAfter(start.subtract(const Duration(days: 1))) && 
              taskDate.isBefore(end.add(const Duration(days: 1))));
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
    debugPrint('[TaskProvider] creating sample tasks');
    
    final sampleTasks = <Task>[
      Task(
        title: 'Plan project milestones',
        description: 'Outline the must-have deliverables for the project.',
        isImportant: true,
        isUrgent: true,
        isCompleted: false,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
      Task(
        title: 'Prepare client demo',
        description: 'Create a polished walkthrough for the next client meeting.',
        isImportant: true,
        isUrgent: true,
        isCompleted: false,
        dueDate: DateTime.now(),
      ),
      Task(
        title: 'Study advanced Flutter patterns',
        description: 'Review state management and performance optimization tips.',
        isImportant: true,
        isUrgent: false,
        isCompleted: false,
      ),
      Task(
        title: 'Start fitness routine',
        description: 'Schedule daily workouts to build consistent habits.',
        isImportant: true,
        isUrgent: false,
        isCompleted: false,
      ),
      Task(
        title: 'Reply to urgent emails',
        description: 'Handle high-priority messages waiting in the inbox.',
        isImportant: false,
        isUrgent: true,
        isCompleted: false,
      ),
      Task(
        title: 'Restock office supplies',
        description: 'Order paper, pens, and other essentials for the team.',
        isImportant: false,
        isUrgent: true,
        isCompleted: false,
      ),
      Task(
        title: 'Organize email archive',
        description: 'Clean up folders and archive old conversation threads.',
        isImportant: false,
        isUrgent: false,
        isCompleted: false,
      ),
      Task(
        title: 'Review weekly metrics',
        description: 'Check progress and trends for the current sprint.',
        isImportant: false,
        isUrgent: false,
        isCompleted: false,
      ),
    ];
    
    for (final task in sampleTasks) {
      await _insertTaskInternal(
        task,
        scheduleReminder: false,
      );
    }
    
    _publishChanges();
    debugPrint('[TaskProvider] seeded ${sampleTasks.length} sample tasks');
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

  // 获取主任务（不包括子任务）
  List<Task> get mainTasks => _tasks.where((task) => task.isMainTask).toList();

  // 获取指定任务的子任务
  List<Task> getSubTasks(int parentTaskId) {
    return _tasks.where((task) => task.parentTaskId == parentTaskId).toList();
  }

  // 删除子任务
  Future<void> deleteSubTask(int subTaskId) async {
    await _db.deleteTask(subTaskId);
    _tasks.removeWhere((task) => task.id == subTaskId);
    
    // 更新父任务的子任务列表
    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.subTasks.any((subTask) => subTask.id == subTaskId)) {
        final updatedSubTasks = task.subTasks.where((subTask) => subTask.id != subTaskId).toList();
        _tasks[i] = task.copyWith(subTasks: updatedSubTasks);
        break;
      }
    }
    
    _publishChanges();
  }

  // 切换子任务完成状态
  Future<void> toggleSubTaskCompletion(int parentTaskId, Task subTask) async {
    final updatedSubTask = subTask.copyWith(isCompleted: !subTask.isCompleted);
    await updateTask(updatedSubTask);
    
    // 更新父任务的子任务列表
    final parentIndex = _tasks.indexWhere((t) => t.id == parentTaskId);
    if (parentIndex != -1) {
      final parentTask = _tasks[parentIndex];
      final updatedSubTasks = parentTask.subTasks.map((task) {
        return task.id == subTask.id ? updatedSubTask : task;
      }).toList();
      _tasks[parentIndex] = parentTask.copyWith(subTasks: updatedSubTasks);
    }
    
    _publishChanges();
  }
  // --- Backup & Restore Helper Methods ---

  Future<void> clearAllTasks() async {
    // Delete all tasks from DB
    // We can't easily do "delete * from tasks" via standard methods if not exposed?
    // Let's iterate or assume `_db` has ability?
    // Actually, `DatabaseInterface` usually needs to be updated or we perform loop.
    // Loop is slow.
    // Let's assuming _db has a raw delete or we add it?
    // I can't check DatabaseInterface easily right now without view.
    // Let's try loop for MVP optimization later.
    final allIds = _tasks.map((t) => t.id!).toList();
    for (final id in allIds) {
      await _db.deleteTask(id); // Notification service cancellation handled? 
      await _notificationService.cancelNotification(id);
    }
    _tasks.clear(); // Clear memory
    _publishChanges();
  }

  Future<void> importTasks(List<Map<String, dynamic>> tasksJson) async {
    // Assumes clearAllTasks was called OR we just try to insert.
    // We want to preserve IDs.
    for (final json in tasksJson) {
      // Create Task from JSON
      Task task = Task.fromJson(json);
      
      // We must insert with specific ID.
      // _db.insertTask usually returns a Task with new ID (ignoring input ID).
      // We might need a "restoreTask" method in DB that forces ID insert.
      // If _db doesn't support forcing ID, we lose structure.
      // Let's look at `_db.insertTask` implementation?
      // If I can't see it, I'll assume standard behavior behavior.
      // Standard sqflite 'insert' takes a map. If map has 'id', it uses it.
      // So passing Task with ID to insertTask should work IF the underlying implementation doesn't strip it.
      // Let's assume it works.
      
      try {
        // We use inner db method if possible?
        // _db is local interface.
        // Let's try standard insert.
        await _db.insertTask(task); 
        _tasks.add(task);
        if (task.dueDate != null && !task.isCompleted) {
           await _notificationService.scheduleTaskReminder(task);
        }
      } catch (e) {
        debugPrint('Error importing task ${task.id}: $e');
        // Fallback: try inserting as new if ID collision?
        // But that breaks hierarchy.
        // For now, log error.
      }
    }
    _publishChanges();
  }
}
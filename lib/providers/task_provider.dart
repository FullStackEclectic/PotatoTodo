import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/quadrant_stats.dart';
import '../services/database_interface.dart';
import '../services/notification_service.dart';
import '../constants/quadrant_constants.dart';
import 'gamification_provider.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseInterface _db;
  final NotificationService _notificationService;
  final bool _shouldEnsureDatabase;
  GamificationProvider? _gamificationProvider;

  set gamificationProvider(GamificationProvider? provider) {
    _gamificationProvider = provider;
  }

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
  List<Task> get allTasks => UnmodifiableListView(_tasks);

  void _rebuildTaskHierarchy() {
    final childrenByParentId = <int, List<Task>>{};
    for (final task in _tasks) {
      if (task.id != null && task.parentTaskId != null) {
        childrenByParentId.putIfAbsent(task.parentTaskId!, () => []).add(task);
      }
    }

    Task attachChildren(Task task, Set<int> ancestors) {
      final taskId = task.id;
      if (taskId == null || !ancestors.add(taskId)) {
        return task.copyWith(subTasks: const []);
      }

      final children =
          childrenByParentId[taskId]
              ?.map((child) => attachChildren(child, {...ancestors}))
              .toList() ??
          const <Task>[];
      return task.copyWith(subTasks: children);
    }

    _tasks = _tasks.map((task) => attachChildren(task, {})).toList();
  }

  Set<int> _getTaskTreeIds(int rootId) {
    final ids = <int>{rootId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final task in _tasks) {
        if (task.id != null &&
            task.parentTaskId != null &&
            ids.contains(task.parentTaskId) &&
            ids.add(task.id!)) {
          changed = true;
        }
      }
    }
    return ids;
  }

  void _replaceTaskInMemory(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) return;

    _tasks[index] = updatedTask;
    _rebuildTaskHierarchy();
  }

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
      filteredTasks =
          filteredTasks
              .where((task) => task.categoryId == _selectedCategoryId)
              .toList();
    }

    // 按象限筛选
    if (_selectedQuadrant != null) {
      switch (_selectedQuadrant) {
        case QuadrantType.importantUrgent:
          filteredTasks =
              filteredTasks
                  .where((task) => task.isImportant && task.isUrgent)
                  .toList();
          break;
        case QuadrantType.importantNotUrgent:
          filteredTasks =
              filteredTasks
                  .where((task) => task.isImportant && !task.isUrgent)
                  .toList();
          break;
        case QuadrantType.notImportantUrgent:
          filteredTasks =
              filteredTasks
                  .where((task) => !task.isImportant && task.isUrgent)
                  .toList();
          break;
        case QuadrantType.notImportantNotUrgent:
          filteredTasks =
              filteredTasks
                  .where((task) => !task.isImportant && !task.isUrgent)
                  .toList();
          break;
        default:
          break;
      }
    }

    // 按日期范围筛选
    if (_startDate != null || _endDate != null) {
      filteredTasks =
          filteredTasks.where((task) {
            final taskDate = task.dueDate;
            if (taskDate == null) return false;
            if (_startDate != null && taskDate.isBefore(_startDate!)) {
              return false;
            }
            if (_endDate != null && taskDate.isAfter(_endDate!)) {
              return false;
            }
            return true;
          }).toList();
    }

    // 按搜索关键词筛选 (Smart Search)
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase().trim();

      // Smart filters
      if (query == 'important' || query == '重要') {
        filteredTasks =
            filteredTasks.where((task) => task.isImportant).toList();
      } else if (query == 'urgent' || query == '紧急') {
        filteredTasks = filteredTasks.where((task) => task.isUrgent).toList();
      } else if (query == 'completed' || query == '已完成') {
        filteredTasks =
            filteredTasks.where((task) => task.isCompleted).toList();
      } else if (query == 'pending' || query == '未完成') {
        filteredTasks =
            filteredTasks.where((task) => !task.isCompleted).toList();
      } else if (query == 'today' || query == '今天') {
        final now = DateTime.now();
        filteredTasks =
            filteredTasks
                .where(
                  (task) =>
                      task.dueDate != null &&
                      task.dueDate!.year == now.year &&
                      task.dueDate!.month == now.month &&
                      task.dueDate!.day == now.day,
                )
                .toList();
      } else {
        // Standard text search
        filteredTasks =
            filteredTasks.where((task) {
              return task.title.toLowerCase().contains(query) ||
                  (task.description.isNotEmpty &&
                      task.description.toLowerCase().contains(query));
            }).toList();
      }
    }

    // 排序：未完成的任务在前，同组按用户排序位置排列。
    filteredTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final positionOrder = a.position.compareTo(b.position);
      if (positionOrder != 0) return positionOrder;
      final createdOrder = b.createdAt.compareTo(a.createdAt);
      if (createdOrder != 0) return createdOrder;
      return (a.id ?? 0).compareTo(b.id ?? 0);
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

    final dataWasInitialized = await _db.isTaskDataInitialized();
    if (_tasks.isEmpty && !dataWasInitialized) {
      debugPrint('[TaskProvider] no tasks found, creating sample data');
      await _createSampleTasks();
      await _db.markTaskDataInitialized();
    } else {
      debugPrint('[TaskProvider] loaded ${_tasks.length} tasks');
    }
  }

  Future<void> loadTasks() async {
    debugPrint('[TaskProvider] 开始加载任务');
    final allTasks = await _db.getTasks();

    // 保留扁平列表供统计和筛选，再由统一方法构建嵌套子任务。
    _tasks = List<Task>.from(allTasks);
    _rebuildTaskHierarchy();

    debugPrint('[TaskProvider] 加载完成，获取到 ${_tasks.length} 个任务');

    // 调试打印每个任务详情
    for (var task in _tasks) {
      debugPrint(
        '任务ID: ${task.id}, 标题: ${task.title}, 重要: ${task.isImportant}, 紧急: ${task.isUrgent}, 完成: ${task.isCompleted}, 父任务: ${task.parentTaskId}',
      );
    }

    _publishChanges();
  }

  Future<Task> _insertTaskInternal(
    Task task, {
    bool scheduleReminder = true,
  }) async {
    if (task.id != null && _tasks.any((candidate) => candidate.id == task.id)) {
      throw ArgumentError.value(task.id, 'id', 'Task id already exists');
    }
    if (task.parentTaskId != null) {
      _validateTaskParent(task.id, task.parentTaskId);
    }

    final preparedTask =
        task.id == null
            ? task.copyWith(position: _nextTaskPosition(task.parentTaskId))
            : task;
    final newTask = await _db.insertTask(preparedTask);
    _tasks.add(newTask);
    _rebuildTaskHierarchy();
    if (scheduleReminder && newTask.dueDate != null) {
      await _notificationService.scheduleTaskReminder(newTask);
    }
    return newTask;
  }

  Future<void> addTask(Task task, {bool scheduleReminder = true}) async {
    await _insertTaskInternal(task, scheduleReminder: scheduleReminder);
    _publishChanges();
  }

  Future<void> addSubTask(int parentTaskId, Task subTask) async {
    if (!_tasks.any((task) => task.id == parentTaskId)) {
      throw ArgumentError.value(
        parentTaskId,
        'parentTaskId',
        'Parent task does not exist',
      );
    }

    await _insertTaskInternal(subTask.copyWith(parentTaskId: parentTaskId));
    _publishChanges();
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update a task without an id');
    }

    final currentTask = _tasks.firstWhere(
      (candidate) => candidate.id == task.id,
      orElse: () => throw StateError('Task ${task.id} does not exist'),
    );
    _validateTaskParent(task.id, task.parentTaskId);

    final now = DateTime.now();
    Object? completedAt = task.completedAt;
    if (!currentTask.isCompleted && task.isCompleted) {
      completedAt = now;
    } else if (currentTask.isCompleted && !task.isCompleted) {
      completedAt = null;
    }
    final updatedTask = task.copyWith(completedAt: completedAt, updatedAt: now);
    await _db.updateTask(updatedTask);
    _replaceTaskInMemory(updatedTask);
    if (_selectedTask?.id == updatedTask.id) {
      _selectedTask = updatedTask;
    }
    await _notificationService.scheduleTaskReminder(updatedTask);
    _publishChanges();
  }

  Future<void> deleteTask(int id) async {
    final taskIds = _getTaskTreeIds(id).toList();
    for (final taskId in taskIds.where((taskId) => taskId != id)) {
      await _db.deleteTask(taskId);
    }
    await _db.deleteTask(id);

    _tasks.removeWhere((task) => task.id != null && taskIds.contains(task.id));
    _rebuildTaskHierarchy();
    for (final taskId in taskIds) {
      await _notificationService.cancelNotification(taskId);
    }

    if (_selectedTask?.id != null && taskIds.contains(_selectedTask!.id)) {
      _selectedTask = null;
    }
    _publishChanges();
  }

  void removeCategoryFromTasks(int categoryId) {
    removeCategoriesFromTasks({categoryId});
  }

  void removeCategoriesFromTasks(Iterable<int> categoryIds) {
    final ids = categoryIds.toSet();
    _tasks =
        _tasks.map((task) {
          if (ids.contains(task.categoryId)) {
            return task.copyWith(categoryId: null);
          }
          return task;
        }).toList();
    _rebuildTaskHierarchy();
    if (_selectedCategoryId != null && ids.contains(_selectedCategoryId)) {
      _selectedCategoryId = null;
    }
    _publishChanges();
  }

  Future<void> setTaskDueDate(Task task, DateTime? dueDate) async {
    final updatedTask = task.copyWith(dueDate: dueDate);
    await updateTask(updatedTask);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final wasCompleted = task.isCompleted;
    final newCompleted = !wasCompleted;
    final updatedTask = task.copyWith(isCompleted: newCompleted);

    await updateTask(updatedTask);

    if (!wasCompleted && newCompleted) {
      _gamificationProvider?.onTaskCompleted();
      if (task.isRepeating) {
        await _handleRepeatingTask(task);
      }
    }
  }

  Future<void> _handleRepeatingTask(Task task) async {
    final now = DateTime.now();
    final baseDate = task.dueDate ?? now;
    final interval = task.repeatInterval ?? 1;
    DateTime nextDueDate;

    switch (task.repeatFrequency) {
      case 'daily':
        nextDueDate = baseDate.add(Duration(days: interval));
        break;
      case 'weekly':
        nextDueDate = baseDate.add(Duration(days: interval * 7));
        break;
      case 'monthly':
        int year = baseDate.year;
        int month = baseDate.month + interval;
        while (month > 12) {
          year += 1;
          month -= 12;
        }
        int day = baseDate.day;
        final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        if (day > lastDayOfNextMonth) {
          day = lastDayOfNextMonth;
        }
        nextDueDate = DateTime(
          year,
          month,
          day,
          baseDate.hour,
          baseDate.minute,
          baseDate.second,
        );
        break;
      case 'yearly':
        int year = baseDate.year + interval;
        int month = baseDate.month;
        int day = baseDate.day;
        if (month == 2 && day == 29) {
          final isLeapYear =
              (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
          if (!isLeapYear) {
            day = 28;
          }
        }
        nextDueDate = DateTime(
          year,
          month,
          day,
          baseDate.hour,
          baseDate.minute,
          baseDate.second,
        );
        break;
      default:
        nextDueDate = baseDate.add(Duration(days: interval));
        break;
    }

    final nextTask = Task(
      title: task.title,
      description: task.description,
      isCompleted: false,
      isImportant: task.isImportant,
      isUrgent: task.isUrgent,
      categoryId: task.categoryId,
      dueDate: nextDueDate,
      createdAt: now,
      reminderPriority: task.reminderPriority,
      repeatFrequency: task.repeatFrequency,
      repeatInterval: task.repeatInterval,
      isRepeating: true,
      parentTaskId: task.parentTaskId,
    );

    if (task.parentTaskId != null) {
      await addSubTask(task.parentTaskId!, nextTask);
    } else {
      await addTask(nextTask);
    }
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
    if (oldIndex < 0 || oldIndex >= _tasks.length) {
      throw RangeError.index(oldIndex, _tasks, 'oldIndex');
    }
    if (newIndex < 0 || newIndex > _tasks.length) {
      throw RangeError.index(newIndex, _tasks, 'newIndex');
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedTasks = List<Task>.from(_tasks);
    final task = reorderedTasks.removeAt(oldIndex);
    reorderedTasks.insert(newIndex, task);

    final persistedTasks = <Task>[];
    for (var index = 0; index < reorderedTasks.length; index++) {
      final updatedTask = reorderedTasks[index].copyWith(position: index);
      persistedTasks.add(updatedTask);
      if (updatedTask.id != null &&
          updatedTask.position != reorderedTasks[index].position) {
        await _db.updateTask(updatedTask);
      }
    }
    _tasks = persistedTasks;
    _rebuildTaskHierarchy();
    _publishChanges();
  }

  int _nextTaskPosition(int? parentTaskId) {
    final siblingPositions = _tasks
        .where((task) => task.parentTaskId == parentTaskId)
        .map((task) => task.position);
    if (siblingPositions.isEmpty) return 0;
    return siblingPositions.reduce((a, b) => a > b ? a : b) + 1;
  }

  void _validateTaskParent(int? taskId, int? parentTaskId) {
    if (parentTaskId == null) return;
    if (taskId != null && taskId == parentTaskId) {
      throw ArgumentError.value(
        parentTaskId,
        'parentTaskId',
        'A task cannot be its own parent',
      );
    }
    if (!_tasks.any((candidate) => candidate.id == parentTaskId)) {
      throw ArgumentError.value(
        parentTaskId,
        'parentTaskId',
        'Parent task does not exist',
      );
    }
    if (taskId != null && _getTaskTreeIds(taskId).contains(parentTaskId)) {
      throw ArgumentError.value(
        parentTaskId,
        'parentTaskId',
        'A task cannot be moved below one of its descendants',
      );
    }
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
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    final rangeStart = startDate.isBefore(endDate) ? startDate : endDate;
    final rangeEnd = startDate.isBefore(endDate) ? endDate : startDate;

    return _tasks.where((task) {
      final taskDate = task.dueDate;
      if (taskDate == null) return false;
      final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);
      return !taskDay.isBefore(rangeStart) && !taskDay.isAfter(rangeEnd);
    }).toList();
  }

  List<Task> getTasksByCategory(int categoryId) {
    return _tasks.where((task) => task.categoryId == categoryId).toList();
  }

  List<Task> getTasksByQuadrant(QuadrantType quadrant) {
    List<Task> result;
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        result =
            _tasks.where((task) => task.isImportant && task.isUrgent).toList();
        break;
      case QuadrantType.importantNotUrgent:
        result =
            _tasks.where((task) => task.isImportant && !task.isUrgent).toList();
        break;
      case QuadrantType.notImportantUrgent:
        result =
            _tasks.where((task) => !task.isImportant && task.isUrgent).toList();
        break;
      case QuadrantType.notImportantNotUrgent:
        result =
            _tasks
                .where((task) => !task.isImportant && !task.isUrgent)
                .toList();
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
    return getTasksByQuadrant(
      quadrant,
    ).where((task) => task.isCompleted).length;
  }

  // 获取特定象限的完成率
  double getCompletionRateByQuadrant(QuadrantType quadrant) {
    final totalInQuadrant = getTasksByQuadrant(quadrant).length;
    if (totalInQuadrant == 0) return 0;

    final completedInQuadrant = getCompletedCountByQuadrant(quadrant);
    return completedInQuadrant / totalInQuadrant * 100;
  }

  int getPendingCountByQuadrant(QuadrantType quadrant) {
    return getTasksByQuadrant(
      quadrant,
    ).where((task) => !task.isCompleted).length;
  }

  // 创建示例任务数据
  Future<void> _createSampleTasks() async {
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
        description:
            'Create a polished walkthrough for the next client meeting.',
        isImportant: true,
        isUrgent: true,
        isCompleted: false,
        dueDate: DateTime.now(),
      ),
      Task(
        title: 'Study advanced Flutter patterns',
        description:
            'Review state management and performance optimization tips.',
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

    final insertedIds = <int>[];
    try {
      for (final task in sampleTasks) {
        final inserted = await _insertTaskInternal(
          task,
          scheduleReminder: false,
        );
        if (inserted.id != null) insertedIds.add(inserted.id!);
      }
    } catch (error) {
      for (final id in insertedIds) {
        await _db.deleteTask(id);
      }
      _tasks.removeWhere(
        (task) => task.id != null && insertedIds.contains(task.id),
      );
      _rebuildTaskHierarchy();
      rethrow;
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
    await deleteTask(subTaskId);
  }

  // 切换子任务完成状态
  Future<void> toggleSubTaskCompletion(int parentTaskId, Task subTask) async {
    final updatedSubTask = subTask.copyWith(isCompleted: !subTask.isCompleted);
    await updateTask(updatedSubTask);
  }
  // --- Backup & Restore Helper Methods ---

  Future<void> clearAllTasks() async {
    final allIds =
        _tasks.map((task) => task.id).whereType<int>().toSet().toList();
    for (final id in allIds) {
      await _db.deleteTask(id);
      await _notificationService.cancelNotification(id);
    }
    _tasks.clear();
    _selectedTask = null;
    await _db.markTaskDataInitialized();
    _publishChanges();
  }

  Future<void> importTasks(List<Map<String, dynamic>> tasksJson) async {
    final pending = <Task>[];
    for (var index = 0; index < tasksJson.length; index++) {
      final record = tasksJson[index];
      final parsed = Task.fromJson(record);
      pending.add(
        record.containsKey('position')
            ? parsed
            : parsed.copyWith(position: index),
      );
    }
    final taskIds = <int>{};
    for (final task in pending) {
      final taskId = task.id;
      if (taskId == null || !taskIds.add(taskId)) {
        throw const FormatException('备份中的任务ID无效或重复');
      }
      if (task.parentTaskId != null &&
          !pending.any((candidate) => candidate.id == task.parentTaskId)) {
        throw FormatException('任务 ${task.id} 引用了不存在的父任务');
      }
    }

    final insertedIds = <int>{};
    while (pending.isNotEmpty) {
      final readyTasks =
          pending
              .where(
                (task) =>
                    task.parentTaskId == null ||
                    insertedIds.contains(task.parentTaskId),
              )
              .toList();
      if (readyTasks.isEmpty) {
        throw const FormatException('备份中的任务层级存在循环引用');
      }

      for (final task in readyTasks) {
        final persistedTask = await _db.insertTask(task);
        _tasks.add(persistedTask);
        insertedIds.add(task.id!);
        pending.remove(task);
        if (persistedTask.dueDate != null && !persistedTask.isCompleted) {
          await _notificationService.scheduleTaskReminder(persistedTask);
        }
      }
    }

    _rebuildTaskHierarchy();
    await _db.markTaskDataInitialized();
    _publishChanges();
  }
}

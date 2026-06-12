import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_todo/models/task.dart';
import 'package:potato_todo/models/category.dart';
import 'package:potato_todo/providers/task_provider.dart';
import 'package:potato_todo/services/database_interface.dart';
import 'package:potato_todo/services/notification_service.dart';
import 'package:potato_todo/constants/quadrant_constants.dart';
import 'package:potato_todo/providers/gamification_provider.dart';
import 'package:potato_todo/services/sound_service.dart';

// Mock database service for testing
class MockDatabaseService implements DatabaseInterface {
  final List<Task> _tasks = [];
  final List<TaskCategory> _categories = [];
  
  @override
  Future<void> initialize() async {}
  
  @override
  Future<Task> insertTask(Task task) async {
    final newTask = task.copyWith(id: _tasks.length + 1);
    _tasks.add(newTask);
    return newTask;
  }
  
  @override
  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }
  
  @override
  Future<void> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id);
  }
  
  @override
  Future<List<Task>> getTasks() async {
    return List.from(_tasks);
  }
  
  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    return _tasks.where((task) => task.categoryId == categoryId).toList();
  }
  
  @override
  Future<List<Task>> searchTasks(String query) async {
    return _tasks.where((task) => 
        task.title.toLowerCase().contains(query.toLowerCase())).toList();
  }
  
  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    final newCat = category.copyWith(id: _categories.length + 1);
    _categories.add(newCat);
    return newCat;
  }
  
  @override
  Future<void> updateCategory(TaskCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }
  
  @override
  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((category) => category.id == id);
  }
  
  @override
  Future<List<TaskCategory>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    return _categories.where((c) => c.level == 0).toList();
  }

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<void> updateCategoryOrder(List<TaskCategory> reorderedCategories) async {
    _categories.clear();
    _categories.addAll(reorderedCategories);
  }

  @override
  Future<void> clearCategoriesTable() async {
    _categories.clear();
  }
}

// Mock notification service for testing
class MockNotificationService extends NotificationService {
  MockNotificationService() : super.internal();

  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> scheduleTaskReminder(Task task) async {}
  
  @override
  Future<void> cancelNotification(int id) async {}
  
  @override
  Future<void> cancelAllNotifications() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskProvider Bug Fixes', () {
    late TaskProvider taskProvider;
    late MockDatabaseService mockDb;
    late MockNotificationService mockNotification;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseService();
      mockNotification = MockNotificationService();
      taskProvider = TaskProvider(mockDb, mockNotification);
      await SoundService().toggleSound(false);
    });

    test('getTasksByDateRange should include start and end dates', () async {
      // Create test tasks
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      
      final task1 = Task(
        title: 'Yesterday Task', 
        dueDate: yesterday,
        isImportant: true,
        isUrgent: false,
      );
      final task2 = Task(
        title: 'Today Task', 
        dueDate: today,
        isImportant: false,
        isUrgent: true,
      );
      final task3 = Task(
        title: 'Tomorrow Task', 
        dueDate: tomorrow,
        isImportant: false,
        isUrgent: false,
      );
      final task4 = Task(
        title: 'No Due Date Task', 
        dueDate: null, // This should be excluded
        isImportant: true,
        isUrgent: true,
      );
      
      await taskProvider.addTask(task1);
      await taskProvider.addTask(task2);
      await taskProvider.addTask(task3);
      await taskProvider.addTask(task4);
      
      // Test inclusive date range
      final tasksInRange = taskProvider.getTasksByDateRange(yesterday, tomorrow);
      
      // Should include all three tasks with dates (inclusive range)
      expect(tasksInRange.length, equals(3));
      expect(tasksInRange.any((task) => task.title == 'Yesterday Task'), isTrue);
      expect(tasksInRange.any((task) => task.title == 'Today Task'), isTrue);
      expect(tasksInRange.any((task) => task.title == 'Tomorrow Task'), isTrue);
      expect(tasksInRange.any((task) => task.title == 'No Due Date Task'), isFalse);
    });

    test('reorderTasks should not update all tasks unnecessarily', () async {
      // Create test tasks
      final task1 = Task(title: 'Task 1', isImportant: true, isUrgent: true);
      final task2 = Task(title: 'Task 2', isImportant: true, isUrgent: false);
      final task3 = Task(title: 'Task 3', isImportant: false, isUrgent: true);
      
      await taskProvider.addTask(task1);
      await taskProvider.addTask(task2);
      await taskProvider.addTask(task3);
      
      final initialTaskCount = mockDb._tasks.length;
      
      // Reorder tasks
      await taskProvider.reorderTasks(0, 3);
      
      // The number of tasks should remain the same
      expect(mockDb._tasks.length, equals(initialTaskCount));
      
      // Task order should be changed in the provider
      expect(taskProvider.allTasks[0].title, equals('Task 2'));
      expect(taskProvider.allTasks[1].title, equals('Task 3'));
      expect(taskProvider.allTasks[2].title, equals('Task 1'));
    });

    test('Task quadrant getter returns correct quadrant', () {
      final urgentImportantTask = Task(
        title: 'Urgent Important',
        isImportant: true,
        isUrgent: true,
      );
      expect(urgentImportantTask.quadrant, equals(QuadrantType.importantUrgent));

      final importantNotUrgentTask = Task(
        title: 'Important Not Urgent',
        isImportant: true,
        isUrgent: false,
      );
      expect(importantNotUrgentTask.quadrant, equals(QuadrantType.importantNotUrgent));

      final urgentNotImportantTask = Task(
        title: 'Urgent Not Important',
        isImportant: false,
        isUrgent: true,
      );
      expect(urgentNotImportantTask.quadrant, equals(QuadrantType.notImportantUrgent));

      final notUrgentNotImportantTask = Task(
        title: 'Not Urgent Not Important',
        isImportant: false,
        isUrgent: false,
      );
      expect(notUrgentNotImportantTask.quadrant, equals(QuadrantType.notImportantNotUrgent));
    });

    test('Task toMap and fromMap should preserve all fields', () {
      final originalTask = Task(
        id: 1,
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        isImportant: true,
        isUrgent: false,
        categoryId: 2,
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reminderPriority: 3,
        repeatFrequency: 'daily',
        repeatInterval: 2,
        isRepeating: true,
      );

      final map = originalTask.toMap();
      final reconstructedTask = Task.fromMap(map);

      expect(reconstructedTask.id, equals(originalTask.id));
      expect(reconstructedTask.title, equals(originalTask.title));
      expect(reconstructedTask.description, equals(originalTask.description));
      expect(reconstructedTask.isCompleted, equals(originalTask.isCompleted));
      expect(reconstructedTask.isImportant, equals(originalTask.isImportant));
      expect(reconstructedTask.isUrgent, equals(originalTask.isUrgent));
      expect(reconstructedTask.categoryId, equals(originalTask.categoryId));
      expect(reconstructedTask.repeatFrequency, equals(originalTask.repeatFrequency));
      expect(reconstructedTask.repeatInterval, equals(originalTask.repeatInterval));
      expect(reconstructedTask.isRepeating, equals(originalTask.isRepeating));
    });

    test('deleteTask should cascade delete subtasks in memory and database', () async {
      // 1. Add parent task
      final parentTask = Task(title: 'Parent Task');
      await taskProvider.addTask(parentTask);
      final parentId = taskProvider.allTasks.last.id!;

      // 2. Add subtask
      final subTask = Task(title: 'Sub Task', parentTaskId: parentId);
      await taskProvider.addSubTask(parentId, subTask);

      expect(taskProvider.allTasks.length, equals(2));

      // 3. Delete parent task
      await taskProvider.deleteTask(parentId);

      // 4. Verification: Memory should be cleared of parent and subtasks
      expect(taskProvider.allTasks.isEmpty, isTrue);

      // 5. Verification: Mock Database should be cleared of parent and subtasks
      expect(mockDb._tasks.isEmpty, isTrue);
    });

    test('removeCategoryFromTasks should clear category references and active filters', () async {
      // 1. Add task in category 10
      final task = Task(title: 'Categorized Task', categoryId: 10);
      await taskProvider.addTask(task);

      // 2. Set current filter to category 10
      taskProvider.setSelectedCategory(10);
      expect(taskProvider.selectedCategoryId, equals(10));

      // 3. Trigger category cleanup
      taskProvider.removeCategoryFromTasks(10);

      // 4. Task categoryId should be null
      expect(taskProvider.allTasks.first.categoryId, isNull);

      // 5. Selected filter should be reset to null
      expect(taskProvider.selectedCategoryId, isNull);
    });

    test('toggleTaskCompletion on repeating task should spawn a new task with correct next due date', () async {
      // 1. Add repeating daily task with due date
      final baseDate = DateTime(2026, 6, 12, 10, 0, 0);
      final originalTask = Task(
        title: 'Daily Task',
        dueDate: baseDate,
        isRepeating: true,
        repeatFrequency: 'daily',
        repeatInterval: 2, // every 2 days
      );
      
      await taskProvider.addTask(originalTask);
      final addedTask = taskProvider.allTasks.first;

      expect(taskProvider.allTasks.length, equals(1));

      // 2. Toggle completion (from incomplete to complete)
      await taskProvider.toggleTaskCompletion(addedTask);

      // 3. Verifications
      // Original task should be completed
      expect(taskProvider.allTasks.firstWhere((t) => t.id == addedTask.id).isCompleted, isTrue);

      // A new task should be spawned
      expect(taskProvider.allTasks.length, equals(2));

      // The new task should be incomplete, repeating, and have next due date (baseDate + 2 days)
      final spawnedTask = taskProvider.allTasks.firstWhere((t) => t.id != addedTask.id);
      expect(spawnedTask.isCompleted, isFalse);
      expect(spawnedTask.isRepeating, isTrue);
      expect(spawnedTask.repeatFrequency, equals('daily'));
      expect(spawnedTask.repeatInterval, equals(2));
      expect(spawnedTask.dueDate, equals(DateTime(2026, 6, 14, 10, 0, 0))); // 12 + 2 = 14
    });

    test('toggleTaskCompletion from incomplete to completed should automatically award XP through GamificationProvider', () async {
      final gamification = GamificationProvider();
      taskProvider.gamificationProvider = gamification;
      
      final task = Task(title: 'XP Task', isCompleted: false);
      await taskProvider.addTask(task);
      final addedTask = taskProvider.allTasks.first;
      
      final initialXp = gamification.xp;
      await taskProvider.toggleTaskCompletion(addedTask);
      
      expect(gamification.xp, equals(initialXp + 10)); // 10 XP awarded per completed task
    });
  });
}
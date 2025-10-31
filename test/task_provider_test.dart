import 'package:flutter_test/flutter_test.dart';
import 'package:potato_todo/models/task.dart';
import 'package:potato_todo/providers/task_provider.dart';
import 'package:potato_todo/services/database_interface.dart';
import 'package:potato_todo/services/notification_service.dart';
import 'package:potato_todo/constants/quadrant_constants.dart';

// Mock database service for testing
class MockDatabaseService implements DatabaseInterface {
  List<Task> _tasks = [];
  
  @override
  Future<void> initialize() async {}
  
  @override
  Future<Task> insertTask(Task task) async {
    final newTask = task.copyWith(id: _tasks.length + 1);
    _tasks.add(newTask);
    return newTask;
  }
  
  @override
  Future<int> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    return 1;
  }
  
  @override
  Future<int> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id);
    return 1;
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
  Future<dynamic> insertCategory(category) async {
    throw UnimplementedError();
  }
  
  @override
  Future<int> updateCategory(category) async {
    throw UnimplementedError();
  }
  
  @override
  Future<int> deleteCategory(int id) async {
    throw UnimplementedError();
  }
  
  @override
  Future<List> getCategories() async {
    return [];
  }
}

// Mock notification service for testing
class MockNotificationService extends NotificationService {
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
  group('TaskProvider Bug Fixes', () {
    late TaskProvider taskProvider;
    late MockDatabaseService mockDb;
    late MockNotificationService mockNotification;

    setUp(() {
      mockDb = MockDatabaseService();
      mockNotification = MockNotificationService();
      taskProvider = TaskProvider(mockDb, mockNotification);
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
      await taskProvider.reorderTasks(0, 2);
      
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
      expect(reconstructedTask.reminderPriority, equals(originalTask.reminderPriority));
      expect(reconstructedTask.repeatFrequency, equals(originalTask.repeatFrequency));
      expect(reconstructedTask.repeatInterval, equals(originalTask.repeatInterval));
      expect(reconstructedTask.isRepeating, equals(originalTask.isRepeating));
    });
  });
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:potato_todo/models/category.dart';
import 'package:potato_todo/models/task.dart';
import 'package:potato_todo/providers/category_provider.dart';
import 'package:potato_todo/providers/gamification_provider.dart';
import 'package:potato_todo/providers/task_provider.dart';
import 'package:potato_todo/services/backup_service.dart';
import 'package:potato_todo/services/database_interface.dart';
import 'package:potato_todo/services/notification_service.dart';

class BackupDatabase implements DatabaseInterface {
  final List<Task> tasks = <Task>[];
  final List<TaskCategory> categories = <TaskCategory>[];
  String? failingTaskTitle;
  bool tasksInitialized = false;
  bool categoriesInitialized = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Task>> getTasks() async => List<Task>.from(tasks);

  @override
  Future<Task> insertTask(Task task) async {
    if (task.title == failingTaskTitle) {
      throw StateError('simulated task insert failure');
    }
    final id = task.id ?? _nextTaskId();
    final inserted = task.copyWith(id: id);
    tasks.add(inserted);
    return inserted;
  }

  @override
  Future<void> updateTask(Task task) async {
    final index = tasks.indexWhere((candidate) => candidate.id == task.id);
    if (index != -1) tasks[index] = task;
  }

  @override
  Future<void> deleteTask(int id) async {
    tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async =>
      tasks.where((task) => task.categoryId == categoryId).toList();

  @override
  Future<List<Task>> searchTasks(String query) async =>
      tasks.where((task) => task.title.contains(query)).toList();

  @override
  Future<bool> isTaskDataInitialized() async => tasksInitialized;

  @override
  Future<void> markTaskDataInitialized() async {
    tasksInitialized = true;
  }

  @override
  Future<List<TaskCategory>> getCategories() async =>
      List<TaskCategory>.from(categories);

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async =>
      categories.where((category) => category.level == 0).toList();

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async =>
      categories.where((category) => category.parentId == parentId).toList();

  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    final id = category.id ?? _nextCategoryId();
    final inserted = category.copyWith(id: id);
    categories.add(inserted);
    return inserted;
  }

  @override
  Future<void> updateCategory(TaskCategory category) async {
    final index = categories.indexWhere(
      (candidate) => candidate.id == category.id,
    );
    if (index != -1) categories[index] = category;
  }

  @override
  Future<void> deleteCategory(int id) async {
    categories.removeWhere((category) => category.id == id);
  }

  @override
  Future<void> updateCategoryOrder(
    List<TaskCategory> reorderedCategories,
  ) async {}

  int _nextTaskId() =>
      tasks.fold(0, (max, task) => task.id! > max ? task.id! : max) + 1;

  int _nextCategoryId() =>
      categories.fold(
        0,
        (max, category) => category.id! > max ? category.id! : max,
      ) +
      1;

  @override
  Future<bool> isCategoryDataInitialized() async => categoriesInitialized;

  @override
  Future<void> markCategoryDataInitialized() async {
    categoriesInitialized = true;
  }
}

class BackupNotificationService extends NotificationService {
  BackupNotificationService() : super.internal();

  @override
  Future<void> scheduleTaskReminder(Task task) async {}

  @override
  Future<void> cancelNotification(int id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackupDatabase database;
  late TaskProvider taskProvider;
  late CategoryProvider categoryProvider;
  late GamificationProvider gameProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = BackupDatabase();
    taskProvider = TaskProvider(
      database,
      BackupNotificationService(),
      ensureDatabaseInitialized: false,
    );
    categoryProvider = CategoryProvider(database);
    gameProvider = GamificationProvider();
  });

  test(
    'invalid task payload is rejected before clearing existing data',
    () async {
      final category = TaskCategory(
        id: 1,
        name: 'Existing',
        color: Colors.blue,
        iconCodePoint: Icons.work.codePoint,
      );
      await categoryProvider.addCategory(category);
      await taskProvider.addTask(Task(id: 1, title: 'Keep me'));

      final invalidBackup = jsonEncode({
        'version': 1,
        'categories': [category.toJson()],
        // createdAt is intentionally missing.
        'tasks': [
          {'id': 2, 'title': 'Invalid'},
        ],
      });

      await expectLater(
        BackupService.restoreBackupWithProviders(
          taskProvider,
          categoryProvider,
          gameProvider,
          invalidBackup,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(taskProvider.allTasks.single.title, 'Keep me');
      expect(categoryProvider.categories.single.name, 'Existing');
    },
  );

  test('failed replacement rolls back existing tasks and categories', () async {
    final oldCategory = TaskCategory(
      id: 1,
      name: 'Old category',
      color: Colors.blue,
      iconCodePoint: Icons.work.codePoint,
    );
    final oldTask = Task(id: 1, title: 'Old task', categoryId: 1);
    await categoryProvider.addCategory(oldCategory);
    await taskProvider.addTask(oldTask);

    final newCategory = oldCategory.copyWith(id: 2, name: 'New category');
    final newTask = Task(id: 2, title: 'New task', categoryId: 2);
    database.failingTaskTitle = newTask.title;

    final backup = jsonEncode({
      'version': 1,
      'categories': [newCategory.toJson()],
      'tasks': [newTask.toJson()],
      'gamification': gameProvider.exportState(),
    });

    await expectLater(
      BackupService.restoreBackupWithProviders(
        taskProvider,
        categoryProvider,
        gameProvider,
        backup,
      ),
      throwsA(isA<StateError>()),
    );

    expect(taskProvider.allTasks.map((task) => task.title), ['Old task']);
    expect(categoryProvider.categories.map((category) => category.name), [
      'Old category',
    ]);
    expect(database.tasks.map((task) => task.title), ['Old task']);
    expect(database.categories.map((category) => category.name), [
      'Old category',
    ]);
  });
}

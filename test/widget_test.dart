// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:potato_todo/main.dart';
import 'package:potato_todo/providers/task_provider.dart';
import 'package:potato_todo/providers/category_provider.dart';
import 'package:potato_todo/providers/theme_provider.dart';
import 'package:potato_todo/providers/pomodoro_provider.dart';
import 'package:potato_todo/providers/gamification_provider.dart';
import 'package:potato_todo/services/database_interface.dart';
import 'package:potato_todo/services/notification_service.dart';
import 'package:potato_todo/models/task.dart';
import 'package:potato_todo/models/category.dart';

// Mock database service for testing
class MockDatabaseService implements DatabaseInterface {
  final List<Task> _tasks = [];
  final List<TaskCategory> _categories = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<List<Task>> getTasks() async => _tasks;

  @override
  Future<Task> insertTask(Task task) async {
    final t = task.copyWith(id: _tasks.length + 1);
    _tasks.add(t);
    return t;
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
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    return _tasks.where((t) => t.categoryId == categoryId).toList();
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    return _tasks.where((t) => t.title.contains(query)).toList();
  }

  @override
  Future<List<TaskCategory>> getCategories() async => _categories;

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    return _categories.where((c) => c.level == 0).toList();
  }

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    final c = category.copyWith(id: _categories.length + 1);
    _categories.add(c);
    return c;
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
    _categories.removeWhere((c) => c.id == id);
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
  late MockDatabaseService mockDb;
  late MockNotificationService mockNotification;

  setUp(() {
    mockDb = MockDatabaseService();
    mockNotification = MockNotificationService();
  });

  testWidgets('PotatoTodo app loads and shows main content', (WidgetTester tester) async {
    // Set view size to mobile constraints to force mobile layout with BottomNavigationBar
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(mockDb),
          ),
          ChangeNotifierProvider(
            create: (_) => TaskProvider(mockDb, mockNotification, ensureDatabaseInitialized: false),
          ),
          ChangeNotifierProvider(
            create: (_) => PomodoroProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => GamificationProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Let the app initialize
    await tester.pumpAndSettle();

    // Verify that the app title exists
    expect(find.text('土豆 Todo'), findsOneWidget);
    
    // Verify that we can find some basic navigation elements
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('App navigation works correctly', (WidgetTester tester) async {
    // Set view size to mobile constraints to force mobile layout with BottomNavigationBar
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(mockDb),
          ),
          ChangeNotifierProvider(
            create: (_) => TaskProvider(mockDb, mockNotification, ensureDatabaseInitialized: false),
          ),
          ChangeNotifierProvider(
            create: (_) => PomodoroProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => GamificationProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Let the app initialize
    await tester.pumpAndSettle();

    // Verify the bottom navigation exists
    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);
  });
}

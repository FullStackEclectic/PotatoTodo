import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:potato_todo/models/category.dart';
import 'package:potato_todo/models/task.dart';
import 'package:potato_todo/providers/category_provider.dart';
import 'package:potato_todo/services/database_interface.dart';

// Mock database service for testing
class MockDatabaseService implements DatabaseInterface {
  List<TaskCategory> _categories = [];
  int _nextId = 1;
  bool _categoriesInitialized = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    final newCategory = category.copyWith(id: _nextId++);
    _categories.add(newCategory);
    return newCategory;
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
    // 模拟级联删除
    _categories.removeWhere((cat) => cat.id == id || cat.parentId == id);
  }

  @override
  Future<void> updateCategoryOrder(
    List<TaskCategory> reorderedCategories,
  ) async {
    _categories = List<TaskCategory>.from(reorderedCategories);
  }

  @override
  Future<List<TaskCategory>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    return _categories.where((cat) => cat.level == 0).toList();
  }

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    return _categories.where((cat) => cat.parentId == parentId).toList();
  }

  @override
  Future<bool> isCategoryDataInitialized() async => _categoriesInitialized;

  @override
  Future<void> markCategoryDataInitialized() async {
    _categoriesInitialized = true;
  }

  // 其他未使用的方法
  @override
  Future<List<Task>> getTasks() async => [];

  @override
  Future<Task> insertTask(Task task) async => task;

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<void> deleteTask(int id) async {}

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async => [];

  @override
  Future<List<Task>> searchTasks(String query) async => [];

  @override
  Future<bool> isTaskDataInitialized() async => true;

  @override
  Future<void> markTaskDataInitialized() async {}

  Future<void> clearCategoriesTable() async {
    _categories.clear();
  }
}

void main() {
  group('CategoryProvider Tests', () {
    late MockDatabaseService mockDb;
    late CategoryProvider categoryProvider;

    setUp(() {
      mockDb = MockDatabaseService();
      categoryProvider = CategoryProvider(mockDb);
    });

    test('should create top-level categories correctly', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 由于初始化时会创建默认分类，我们需要先清除它们
      await mockDb.clearCategoriesTable();
      await categoryProvider.loadCategories();

      final workCategory = TaskCategory(
        name: '工作',
        color: Colors.blue,
        iconCodePoint: Icons.work.codePoint,
        level: 0,
      );

      await categoryProvider.addCategory(workCategory);

      expect(categoryProvider.topLevelCategories.length, 1);
      expect(categoryProvider.topLevelCategories.first.name, '工作');
      expect(categoryProvider.topLevelCategories.first.level, 0);
    });

    test('should create sub-categories correctly', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 由于初始化时会创建默认分类，我们需要先清除它们
      await mockDb.clearCategoriesTable();
      await categoryProvider.loadCategories();

      // 创建父分类
      final workCategory = TaskCategory(
        name: '工作',
        color: Colors.blue,
        iconCodePoint: Icons.work.codePoint,
        level: 0,
      );

      await categoryProvider.addCategory(workCategory);
      final workCategoryWithId = categoryProvider.categories.first;

      // 创建子分类
      final meetingCategory = TaskCategory(
        name: '会议',
        color: Colors.red,
        iconCodePoint: Icons.meeting_room.codePoint,
        parentId: workCategoryWithId.id,
        level: 1,
      );

      await categoryProvider.addCategory(meetingCategory);

      // 验证顶级分类
      expect(categoryProvider.topLevelCategories.length, 1);
      expect(categoryProvider.topLevelCategories.first.name, '工作');

      // 验证子分类
      final subCategories = categoryProvider.getSubCategories(
        workCategoryWithId.id!,
      );
      expect(subCategories.length, 1);
      expect(subCategories.first.name, '会议');
      expect(subCategories.first.level, 1);
      expect(subCategories.first.parentId, workCategoryWithId.id);
    });

    test('should get category full name correctly', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 由于初始化时会创建默认分类，我们需要先清除它们
      await mockDb.clearCategoriesTable();
      await categoryProvider.loadCategories();

      // 创建父分类
      final workCategory = TaskCategory(
        name: '工作',
        color: Colors.blue,
        iconCodePoint: Icons.work.codePoint,
        level: 0,
      );

      await categoryProvider.addCategory(workCategory);
      final workCategoryWithId = categoryProvider.categories.first;

      // 创建子分类
      final meetingCategory = TaskCategory(
        name: '会议',
        color: Colors.red,
        iconCodePoint: Icons.meeting_room.codePoint,
        parentId: workCategoryWithId.id,
        level: 1,
      );

      await categoryProvider.addCategory(meetingCategory);
      final meetingCategoryWithId = categoryProvider.categories.last;

      // 验证完整路径名称
      expect(categoryProvider.getCategoryFullName(workCategoryWithId), '工作');
      expect(
        categoryProvider.getCategoryFullName(meetingCategoryWithId),
        '工作 > 会议',
      );
    });

    test('should delete category with sub-categories correctly', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 由于初始化时会创建默认分类，我们需要先清除它们
      await mockDb.clearCategoriesTable();
      await categoryProvider.loadCategories();

      // 创建父分类
      final workCategory = TaskCategory(
        name: '工作',
        color: Colors.blue,
        iconCodePoint: Icons.work.codePoint,
        level: 0,
      );

      await categoryProvider.addCategory(workCategory);
      final workCategoryWithId = categoryProvider.categories.first;

      // 创建子分类
      final meetingCategory = TaskCategory(
        name: '会议',
        color: Colors.red,
        iconCodePoint: Icons.meeting_room.codePoint,
        parentId: workCategoryWithId.id,
        level: 1,
      );

      await categoryProvider.addCategory(meetingCategory);

      // 验证初始状态
      expect(categoryProvider.topLevelCategories.length, 1);
      expect(
        categoryProvider.getSubCategories(workCategoryWithId.id!).length,
        1,
      );

      // 删除父分类
      await categoryProvider.deleteCategory(workCategoryWithId.id!);

      // 验证删除后状态
      expect(categoryProvider.topLevelCategories.length, 0);
      expect(
        categoryProvider.getSubCategories(workCategoryWithId.id!).length,
        0,
      );
      expect(categoryProvider.categories.length, 0);
    });

    test('should handle category hierarchy correctly', () async {
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 由于初始化时会创建默认分类，我们需要先清除它们
      await mockDb.clearCategoriesTable();
      await categoryProvider.loadCategories();

      // 创建多个层级的分类
      await categoryProvider.addCategory(
        TaskCategory(
          name: '工作',
          color: Colors.blue,
          iconCodePoint: Icons.work.codePoint,
          level: 0,
        ),
      );

      final workCategory = categoryProvider.categories.first;

      await categoryProvider.addCategory(
        TaskCategory(
          name: '项目',
          color: Colors.green,
          iconCodePoint: Icons.folder.codePoint,
          parentId: workCategory.id,
          level: 1,
        ),
      );

      final projectCategory = categoryProvider.categories[1];

      await categoryProvider.addCategory(
        TaskCategory(
          name: '前端',
          color: Colors.orange,
          iconCodePoint: Icons.code.codePoint,
          parentId: projectCategory.id,
          level: 2,
        ),
      );

      final frontendCategory = categoryProvider.categories[2];

      // 验证层级结构
      expect(categoryProvider.topLevelCategories.length, 1);
      expect(categoryProvider.getSubCategories(workCategory.id!).length, 1);
      expect(categoryProvider.getSubCategories(projectCategory.id!).length, 1);

      // 验证完整路径名称
      expect(categoryProvider.getCategoryFullName(workCategory), '工作');
      expect(categoryProvider.getCategoryFullName(projectCategory), '工作 > 项目');
      expect(
        categoryProvider.getCategoryFullName(frontendCategory),
        '工作 > 项目 > 前端',
      );
    });

    test('should reject self-parent and descendant-parent cycles', () async {
      await categoryProvider.addCategory(
        TaskCategory(
          name: 'Root',
          color: Colors.blue,
          iconCodePoint: Icons.folder.codePoint,
        ),
      );
      final root = categoryProvider.categories.single;
      await categoryProvider.addCategory(
        TaskCategory(
          name: 'Child',
          color: Colors.green,
          iconCodePoint: Icons.folder_open.codePoint,
          parentId: root.id,
        ),
      );
      final child = categoryProvider.categories.last;

      await expectLater(
        categoryProvider.updateCategory(root.copyWith(parentId: root.id)),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        categoryProvider.updateCategory(root.copyWith(parentId: child.id)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

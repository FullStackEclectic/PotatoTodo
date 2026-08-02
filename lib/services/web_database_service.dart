import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import '../models/task.dart';
import '../models/category.dart';
import 'database_interface.dart';

class WebDatabaseService implements DatabaseInterface {
  static final WebDatabaseService _instance = WebDatabaseService._internal();

  final String _dbName = 'potato_todo_web';
  final int _version = 6;

  IdbFactory? _idbFactory;
  Database? _db;
  bool _isInitialized = false;

  factory WebDatabaseService() {
    debugPrint('[WebDatabaseService] 创建 WebDatabaseService 实例');
    return _instance;
  }

  WebDatabaseService._internal() {
    debugPrint('[WebDatabaseService] WebDatabaseService._internal() 被调用');
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized && _db != null) {
      debugPrint('[WebDatabaseService] 数据库已初始化，跳过');
      return;
    }

    try {
      debugPrint('[WebDatabaseService] 开始初始化数据库');
      _idbFactory = getIdbFactory();
      if (_idbFactory == null) {
        debugPrint('[WebDatabaseService] 错误：无法获取IndexedDB工厂');
        return;
      }

      await _initializeDatabase();
      debugPrint('[WebDatabaseService] 初始化完成，数据库已准备好');
    } catch (e) {
      debugPrint('[WebDatabaseService] 初始化IndexedDB出错: $e');
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      debugPrint('[WebDatabaseService] 开始打开数据库: $_dbName, 版本: $_version');
      // 打开数据库
      _db = await _idbFactory!.open(
        _dbName,
        version: _version,
        onUpgradeNeeded: (VersionChangeEvent event) {
          Database db = event.database;
          debugPrint(
            '[WebDatabaseService] 正在创建或升级Web数据库，当前版本：${event.oldVersion}，新版本：${event.newVersion}',
          );

          // 创建任务表并确保分类索引存在。
          late final ObjectStore taskStore;
          if (!db.objectStoreNames.contains('tasks')) {
            taskStore = db.createObjectStore('tasks', autoIncrement: true);
            debugPrint('[WebDatabaseService] 创建了任务表');
          } else {
            taskStore = event.transaction.objectStore('tasks');
          }
          if (!taskStore.indexNames.contains('categoryId')) {
            taskStore.createIndex('categoryId', 'categoryId', unique: false);
            debugPrint('[WebDatabaseService] 补建了任务分类索引');
          }

          // 创建分类表 (如果不存在)
          if (!db.objectStoreNames.contains('categories')) {
            db.createObjectStore('categories', autoIncrement: true);
            debugPrint('[WebDatabaseService] 创建了分类表');
          }

          if (!db.objectStoreNames.contains('app_meta')) {
            db.createObjectStore('app_meta');
            debugPrint('[WebDatabaseService] 创建了初始化状态表');
          }

          // 处理数据库升级情况
          if (event.oldVersion < 2) {
            debugPrint('[WebDatabaseService] 从版本${event.oldVersion}升级到版本2');
          }

          if (event.oldVersion < 3) {
            debugPrint(
              '[WebDatabaseService] 从版本${event.oldVersion}升级到版本3，添加提醒优先级',
            );
          }

          if (event.oldVersion < 4) {
            debugPrint(
              '[WebDatabaseService] 从版本${event.oldVersion}升级到版本4，添加二级分类支持',
            );
          }
        },
      );

      await _migrateTaskRecords();
      _isInitialized = true;
      debugPrint('[WebDatabaseService] Web数据库初始化成功');
    } catch (e) {
      debugPrint('[WebDatabaseService] 初始化Web数据库出错: $e');
      rethrow;
    }
  }

  Future<void> _migrateTaskRecords() async {
    final transaction = _db!.transaction('tasks', idbModeReadOnly);
    final store = transaction.objectStore('tasks');
    final records = <Map<String, dynamic>>[];
    final keys = <dynamic>[];

    await store.openCursor(autoAdvance: true).listen((cursor) {
      records.add(Map<String, dynamic>.from(cursor.value as Map));
      keys.add(cursor.key);
    }).asFuture();
    await transaction.completed;

    final needsPosition = records.any((record) => record['position'] is! int);
    final needsCompletedAt = records.any(
      (record) =>
          (record['isCompleted'] == true || record['isCompleted'] == 1) &&
          record['completedAt'] == null &&
          record['updatedAt'] != null,
    );
    if (!needsPosition && !needsCompletedAt) return;

    final indexed = List.generate(
      records.length,
      (index) => (record: records[index], key: keys[index]),
    );
    indexed.sort((a, b) {
      final aCreated = DateTime.tryParse(
        a.record['createdAt'] as String? ?? '',
      );
      final bCreated = DateTime.tryParse(
        b.record['createdAt'] as String? ?? '',
      );
      if (aCreated == null && bCreated == null) return 0;
      if (aCreated == null) return 1;
      if (bCreated == null) return -1;
      final createdOrder = bCreated.compareTo(aCreated);
      if (createdOrder != 0) return createdOrder;
      return (a.key as int).compareTo(b.key as int);
    });

    final writeTransaction = _db!.transaction('tasks', idbModeReadWrite);
    final writeStore = writeTransaction.objectStore('tasks');
    for (var index = 0; index < indexed.length; index++) {
      final item = indexed[index];
      final record = Map<String, dynamic>.from(item.record);
      record['position'] =
          record['position'] is int ? record['position'] : index;
      if ((record['isCompleted'] == true || record['isCompleted'] == 1) &&
          record['completedAt'] == null &&
          record['updatedAt'] != null) {
        record['completedAt'] = record['updatedAt'];
      }
      await writeStore.put(record, item.key);
    }
    await writeTransaction.completed;
  }

  // 任务相关操作
  @override
  Future<Task> insertTask(Task task) async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('tasks', idbModeReadWrite);
      ObjectStore store = txn.objectStore('tasks');

      // 这里将Task转换为Map时，不包含id字段，因为我们使用autoIncrement
      Map<String, dynamic> taskMap = task.toMap();
      final originalId = taskMap['id'];
      if (taskMap.containsKey('id')) {
        taskMap.remove('id');
      }

      int id;
      if (originalId != null) {
        id = await store.add(taskMap, originalId) as int;
      } else {
        id = await store.add(taskMap) as int;
      }
      await txn.completed;
      return task.copyWith(id: id);
    } catch (e) {
      debugPrint('插入任务出错: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    await initialize();

    try {
      if (task.id == null) return;

      Transaction txn = _db!.transaction('tasks', idbModeReadWrite);
      ObjectStore store = txn.objectStore('tasks');

      await store.put(task.toMap(), task.id);
      await txn.completed;
    } catch (e) {
      debugPrint('更新任务出错: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('tasks', idbModeReadWrite);
      ObjectStore store = txn.objectStore('tasks');

      await store.delete(id);
      await txn.completed;
    } catch (e) {
      debugPrint('删除任务出错: $e');
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasks() async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('tasks', idbModeReadOnly);
      ObjectStore store = txn.objectStore('tasks');

      List<Map<String, dynamic>> tasks = [];
      await store.openCursor(autoAdvance: true).listen((
        CursorWithValue cursor,
      ) {
        Map<String, dynamic> value = cursor.value as Map<String, dynamic>;
        value['id'] = cursor.key;
        tasks.add(value);
      }).asFuture();

      // 排序：先按position，再按createdAt降序
      tasks.sort((a, b) {
        int posA = a['position'] ?? 999999;
        int posB = b['position'] ?? 999999;
        if (posA != posB) return posA - posB;

        DateTime dateA = DateTime.parse(a['createdAt'] as String);
        DateTime dateB = DateTime.parse(b['createdAt'] as String);
        return dateB.compareTo(dateA); // 降序
      });

      return tasks.map((e) => Task.fromMap(e)).toList();
    } catch (e) {
      debugPrint('获取所有任务出错: $e');
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('tasks', idbModeReadOnly);
      ObjectStore store = txn.objectStore('tasks');
      Index index = store.index('categoryId');

      List<Map<String, dynamic>> tasks = [];
      await index.openCursor(key: categoryId, autoAdvance: true).listen((
        CursorWithValue cursor,
      ) {
        Map<String, dynamic> value = cursor.value as Map<String, dynamic>;
        value['id'] = cursor.primaryKey;
        tasks.add(value);
      }).asFuture();

      // 排序：先按position，再按createdAt降序
      tasks.sort((a, b) {
        int posA = a['position'] ?? 999999;
        int posB = b['position'] ?? 999999;
        if (posA != posB) return posA - posB;

        DateTime dateA = DateTime.parse(a['createdAt'] as String);
        DateTime dateB = DateTime.parse(b['createdAt'] as String);
        return dateB.compareTo(dateA); // 降序
      });

      return tasks.map((e) => Task.fromMap(e)).toList();
    } catch (e) {
      debugPrint('按分类获取任务出错: $e');
      rethrow;
    }
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    await initialize();

    try {
      // 获取所有任务并在内存中过滤
      List<Task> allTasks = await getTasks();
      String lowercaseQuery = query.toLowerCase();

      return allTasks.where((task) {
        return task.title.toLowerCase().contains(lowercaseQuery) ||
            task.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      debugPrint('搜索任务出错: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isTaskDataInitialized() async {
    await initialize();
    final transaction = _db!.transaction('app_meta', idbModeReadOnly);
    final value = await transaction
        .objectStore('app_meta')
        .getObject('tasks_initialized');
    await transaction.completed;
    if (value == true) return true;

    final tasks = await getTasks();
    if (tasks.isNotEmpty) {
      await markTaskDataInitialized();
      return true;
    }
    return false;
  }

  @override
  Future<void> markTaskDataInitialized() async {
    await initialize();
    final transaction = _db!.transaction('app_meta', idbModeReadWrite);
    await transaction.objectStore('app_meta').put(true, 'tasks_initialized');
    await transaction.completed;
  }

  // 分类相关操作
  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    debugPrint('[WebDatabaseService] 开始插入分类: ${category.name}');
    await initialize();

    try {
      if (_db == null) {
        debugPrint('[WebDatabaseService] 错误：数据库未初始化');
        throw Exception('数据库未初始化');
      }

      Transaction txn = _db!.transaction('categories', idbModeReadWrite);
      ObjectStore store = txn.objectStore('categories');

      // 这里将Category转换为Map时，不包含id字段，因为我们使用autoIncrement
      Map<String, dynamic> categoryMap = category.toMap();
      final originalId = categoryMap['id'];
      if (categoryMap.containsKey('id')) {
        categoryMap.remove('id');
      }

      debugPrint('[WebDatabaseService] 分类Map数据: $categoryMap');
      int id;
      if (originalId != null) {
        id = await store.add(categoryMap, originalId) as int;
      } else {
        id = await store.add(categoryMap) as int;
      }
      debugPrint('[WebDatabaseService] 分类插入成功，ID: $id');
      await txn.completed;
      return category.copyWith(id: id);
    } catch (e) {
      debugPrint('[WebDatabaseService] 插入分类出错: $e');
      if (e is Error) {
        debugPrint('[WebDatabaseService] 错误堆栈: ${e.stackTrace}');
      }
      throw Exception('插入分类失败: $e');
    }
  }

  @override
  Future<void> updateCategory(TaskCategory category) async {
    await initialize();

    try {
      if (category.id == null) return;

      Transaction txn = _db!.transaction('categories', idbModeReadWrite);
      ObjectStore store = txn.objectStore('categories');

      await store.put(category.toMap(), category.id);
      await txn.completed;
    } catch (e) {
      debugPrint('更新分类出错: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    await initialize();

    try {
      final categories = await getCategories();
      final categoryIds = <int>{id};
      var changed = true;
      while (changed) {
        changed = false;
        for (final category in categories) {
          if (category.id != null &&
              category.parentId != null &&
              categoryIds.contains(category.parentId) &&
              categoryIds.add(category.id!)) {
            changed = true;
          }
        }
      }

      // Remove all category references before deleting the category tree.
      final tasks = await getTasks();
      for (Task task in tasks) {
        if (categoryIds.contains(task.categoryId)) {
          await updateTask(task.copyWith(categoryId: null));
        }
      }

      // 然后删除分类
      Transaction txn = _db!.transaction('categories', idbModeReadWrite);
      ObjectStore store = txn.objectStore('categories');

      for (final categoryId in categoryIds) {
        await store.delete(categoryId);
      }
      await txn.completed;
    } catch (e) {
      debugPrint('删除分类出错: $e');
      rethrow;
    }
  }

  @override
  Future<List<TaskCategory>> getCategories() async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('categories', idbModeReadOnly);
      ObjectStore store = txn.objectStore('categories');

      List<Map<String, dynamic>> categories = [];
      await store.openCursor(autoAdvance: true).listen((
        CursorWithValue cursor,
      ) {
        Map<String, dynamic> value = cursor.value as Map<String, dynamic>;
        value['id'] = cursor.key;
        categories.add(value);
      }).asFuture();

      // 按层级、排序顺序和名称排序
      categories.sort((a, b) {
        int levelA = a['level'] ?? 0;
        int levelB = b['level'] ?? 0;
        if (levelA != levelB) return levelA - levelB;

        int sortOrderA = a['sortOrder'] ?? 0;
        int sortOrderB = b['sortOrder'] ?? 0;
        if (sortOrderA != sortOrderB) return sortOrderA - sortOrderB;

        return (a['name'] as String).compareTo(b['name'] as String);
      });

      return categories.map((e) => TaskCategory.fromMap(e)).toList();
    } catch (e) {
      debugPrint('获取所有分类出错: $e');
      rethrow;
    }
  }

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('categories', idbModeReadOnly);
      ObjectStore store = txn.objectStore('categories');

      List<Map<String, dynamic>> categories = [];
      await store.openCursor(autoAdvance: true).listen((
        CursorWithValue cursor,
      ) {
        Map<String, dynamic> value = cursor.value as Map<String, dynamic>;
        if ((value['level'] ?? 0) == 0) {
          value['id'] = cursor.key;
          categories.add(value);
        }
      }).asFuture();

      // 按排序顺序和名称排序
      categories.sort((a, b) {
        int sortOrderA = a['sortOrder'] ?? 0;
        int sortOrderB = b['sortOrder'] ?? 0;
        if (sortOrderA != sortOrderB) return sortOrderA - sortOrderB;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      return categories.map((e) => TaskCategory.fromMap(e)).toList();
    } catch (e) {
      debugPrint('获取顶级分类出错: $e');
      rethrow;
    }
  }

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    await initialize();

    try {
      Transaction txn = _db!.transaction('categories', idbModeReadOnly);
      ObjectStore store = txn.objectStore('categories');

      List<Map<String, dynamic>> categories = [];
      await store.openCursor(autoAdvance: true).listen((
        CursorWithValue cursor,
      ) {
        Map<String, dynamic> value = cursor.value as Map<String, dynamic>;
        if (value['parentId'] == parentId) {
          value['id'] = cursor.key;
          categories.add(value);
        }
      }).asFuture();

      // 按排序顺序和名称排序
      categories.sort((a, b) {
        int sortOrderA = a['sortOrder'] ?? 0;
        int sortOrderB = b['sortOrder'] ?? 0;
        if (sortOrderA != sortOrderB) return sortOrderA - sortOrderB;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      return categories.map((e) => TaskCategory.fromMap(e)).toList();
    } catch (e) {
      debugPrint('获取子分类出错: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isCategoryDataInitialized() async {
    await initialize();
    final transaction = _db!.transaction('app_meta', idbModeReadOnly);
    final value = await transaction
        .objectStore('app_meta')
        .getObject('categories_initialized');
    await transaction.completed;
    if (value == true) return true;

    final categories = await getCategories();
    if (categories.isNotEmpty) {
      await markCategoryDataInitialized();
      return true;
    }
    return false;
  }

  @override
  Future<void> markCategoryDataInitialized() async {
    await initialize();
    final transaction = _db!.transaction('app_meta', idbModeReadWrite);
    await transaction
        .objectStore('app_meta')
        .put(true, 'categories_initialized');
    await transaction.completed;
  }

  @override
  Future<void> updateCategoryOrder(
    List<TaskCategory> reorderedCategories,
  ) async {
    debugPrint('[WebDatabaseService] 开始更新分类排序');
    await initialize();

    try {
      Transaction txn = _db!.transaction('categories', idbModeReadWrite);
      ObjectStore store = txn.objectStore('categories');

      // 批量更新排序
      for (int i = 0; i < reorderedCategories.length; i++) {
        final category = reorderedCategories[i];
        final categoryMap = category.toMap();
        categoryMap['sortOrder'] = i;
        await store.put(categoryMap, category.id);
      }

      await txn.completed;
      debugPrint('[WebDatabaseService] 分类排序更新成功');
    } catch (e) {
      debugPrint('[WebDatabaseService] 更新分类排序出错: $e');
      rethrow;
    }
  }
}

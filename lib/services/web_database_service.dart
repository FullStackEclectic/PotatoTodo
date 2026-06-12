import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import '../models/task.dart';
import '../models/category.dart';
import 'database_interface.dart';

class WebDatabaseService implements DatabaseInterface {
  static final WebDatabaseService _instance = WebDatabaseService._internal();
  
  final String _dbName = 'potato_todo_web';
  final int _version = 4;
  
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
          debugPrint('[WebDatabaseService] 正在创建或升级Web数据库，当前版本：${event.oldVersion}，新版本：${event.newVersion}');
          
          // 创建任务表 (如果不存在)
          if (!db.objectStoreNames.contains('tasks')) {
            ObjectStore taskStore = db.createObjectStore(
              'tasks',
              autoIncrement: true,
            );
            taskStore.createIndex('categoryId', 'categoryId', unique: false);
            debugPrint('[WebDatabaseService] 创建了任务表');
          }
          
          // 创建分类表 (如果不存在)
          if (!db.objectStoreNames.contains('categories')) {
            db.createObjectStore(
              'categories',
              autoIncrement: true,
            );
            debugPrint('[WebDatabaseService] 创建了分类表');
          }
          
          // 处理数据库升级情况
          if (event.oldVersion < 2) {
            debugPrint('[WebDatabaseService] 从版本${event.oldVersion}升级到版本2');
          }
          
          if (event.oldVersion < 3) {
            debugPrint('[WebDatabaseService] 从版本${event.oldVersion}升级到版本3，添加提醒优先级');
          }
          
          if (event.oldVersion < 4) {
            debugPrint('[WebDatabaseService] 从版本${event.oldVersion}升级到版本4，添加二级分类支持');
          }
        },
      );
      
      _isInitialized = true;
      debugPrint('[WebDatabaseService] Web数据库初始化成功');
    } catch (e) {
      debugPrint('[WebDatabaseService] 初始化Web数据库出错: $e');
      rethrow;
    }
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
      await store.openCursor(autoAdvance: true).listen((CursorWithValue cursor) {
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
      return [];
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
      await index.openCursor(key: categoryId, autoAdvance: true).listen((CursorWithValue cursor) {
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
      return [];
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
      return [];
    }
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
      // 首先将属于该分类的任务的categoryId设置为null
      List<Task> tasks = await getTasksByCategory(id);
      for (Task task in tasks) {
        Task updatedTask = task.copyWith(categoryId: null);
        await updateTask(updatedTask);
      }
      
      // 然后删除分类
      Transaction txn = _db!.transaction('categories', idbModeReadWrite);
      ObjectStore store = txn.objectStore('categories');
      
      await store.delete(id);
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
      await store.openCursor(autoAdvance: true).listen((CursorWithValue cursor) {
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
      return [];
    }
  }

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    await initialize();
    
    try {
      Transaction txn = _db!.transaction('categories', idbModeReadOnly);
      ObjectStore store = txn.objectStore('categories');
      
      List<Map<String, dynamic>> categories = [];
      await store.openCursor(autoAdvance: true).listen((CursorWithValue cursor) {
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
      return [];
    }
  }

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    await initialize();
    
    try {
      Transaction txn = _db!.transaction('categories', idbModeReadOnly);
      ObjectStore store = txn.objectStore('categories');
      
      List<Map<String, dynamic>> categories = [];
      await store.openCursor(autoAdvance: true).listen((CursorWithValue cursor) {
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
      return [];
    }
  }

  @override
  Future<void> updateCategoryOrder(List<TaskCategory> reorderedCategories) async {
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

  // 用于测试：清除所有分类数据
  @override
  Future<void> clearCategoriesTable() async {
    debugPrint('[WebDatabaseService] 清除分类表');
    await initialize();
    
    try {
      Transaction txn = _db!.transaction('categories', idbModeReadWrite);
      ObjectStore store = txn.objectStore('categories');
      
      await store.clear();
      await txn.completed;
      debugPrint('[WebDatabaseService] 分类表已清空');
    } catch (e) {
      debugPrint('[WebDatabaseService] 清除分类表出错: $e');
      rethrow;
    }
  }
} 
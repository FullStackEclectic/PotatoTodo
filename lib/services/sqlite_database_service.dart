import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/category.dart';
import 'database_interface.dart';

class SQLiteDatabaseService implements DatabaseInterface {
  static Database? _database;
  bool _isInitialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    debugPrint('[SQLiteDatabaseService] 初始化数据库');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'potato_todo.db');
    debugPrint('[SQLiteDatabaseService] 数据库路径: $dbPath');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        debugPrint('[SQLiteDatabaseService] 创建新数据库，版本: $version');
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            isImportant INTEGER NOT NULL DEFAULT 0,
            isUrgent INTEGER NOT NULL DEFAULT 0,
            categoryId INTEGER,
            dueDate TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT,
            reminderPriority INTEGER NOT NULL DEFAULT 2,
            repeatFrequency TEXT,
            repeatInterval INTEGER,
            isRepeating INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
          )
        ''');
        debugPrint('[SQLiteDatabaseService] 创建了tasks表');

        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER NOT NULL,
            iconCodePoint INTEGER NOT NULL
          )
        ''');
        debugPrint('[SQLiteDatabaseService] 创建了categories表');
      },
    );
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[SQLiteDatabaseService] 已初始化，跳过');
      return;
    }
    
    debugPrint('[SQLiteDatabaseService] 初始化SQLiteDatabaseService');
    await database;
    _isInitialized = true;
    debugPrint('[SQLiteDatabaseService] 初始化完成');
  }

  @override
  Future<List<Task>> getTasks() async {
    debugPrint('[SQLiteDatabaseService] 获取所有任务');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个任务');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<Task> insertTask(Task task) async {
    debugPrint('[SQLiteDatabaseService] 插入任务: ${task.title}');
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    debugPrint('[SQLiteDatabaseService] 任务插入成功，ID: $id');
    return task.copyWith(id: id);
  }

  @override
  Future<void> updateTask(Task task) async {
    debugPrint('[SQLiteDatabaseService] 更新任务: ${task.id} - ${task.title}');
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    debugPrint('[SQLiteDatabaseService] 任务更新成功');
  }

  @override
  Future<void> deleteTask(int id) async {
    debugPrint('[SQLiteDatabaseService] 删除任务: $id');
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('[SQLiteDatabaseService] 任务删除成功');
  }

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    debugPrint('[SQLiteDatabaseService] 获取分类ID为 $categoryId 的任务');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个分类任务');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    debugPrint('[SQLiteDatabaseService] 搜索任务: $query');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    debugPrint('[SQLiteDatabaseService] 搜索到 ${maps.length} 个任务');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<List<TaskCategory>> getCategories() async {
    debugPrint('[SQLiteDatabaseService] 获取所有分类');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个分类');
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    debugPrint('[SQLiteDatabaseService] 插入分类: ${category.name}');
    try {
      final db = await database;
      debugPrint('[SQLiteDatabaseService] 数据库连接状态: ${db.isOpen ? '已打开' : '已关闭'}');

      final categoryMap = category.toMap();
      debugPrint('[SQLiteDatabaseService] 分类Map数据: $categoryMap');
      
      // 打印表结构信息
      var tableInfo = await db.rawQuery("PRAGMA table_info(categories)");
      debugPrint('[SQLiteDatabaseService] categories表结构: $tableInfo');
      
      final id = await db.insert('categories', categoryMap);
      debugPrint('[SQLiteDatabaseService] 分类插入成功，ID: $id');
      return category.copyWith(id: id);
    } catch (e) {
      debugPrint('[SQLiteDatabaseService] 插入分类错误: $e');
      if (e is DatabaseException) {
        debugPrint('[SQLiteDatabaseService] 数据库错误代码: ${e.getResultCode()}');
        debugPrint('[SQLiteDatabaseService] 详细信息: ${e.toString()}');
      }
      if (e is Error) {
        debugPrint('[SQLiteDatabaseService] 错误堆栈: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(TaskCategory category) async {
    debugPrint('[SQLiteDatabaseService] 更新分类: ${category.id} - ${category.name}');
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    debugPrint('[SQLiteDatabaseService] 分类更新成功');
  }

  @override
  Future<void> deleteCategory(int id) async {
    debugPrint('[SQLiteDatabaseService] 删除分类: $id');
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('[SQLiteDatabaseService] 分类删除成功');
  }

  // 用于测试：清除所有分类数据
  Future<void> clearCategoriesTable() async {
    debugPrint('[SQLiteDatabaseService] 清除分类表');
    try {
      final db = await database;
      await db.delete('categories');
      debugPrint('[SQLiteDatabaseService] 分类表已清空');
    } catch (e) {
      debugPrint('[SQLiteDatabaseService] 清除分类表出错: $e');
      rethrow;
    }
  }
} 
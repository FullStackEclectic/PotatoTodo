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
      version: 6,
      onConfigure: (db) async {
        debugPrint('[SQLiteDatabaseService] 开启外键约束支持');
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
            completedAt TEXT,
            reminderPriority INTEGER NOT NULL DEFAULT 2,
            repeatFrequency TEXT,
            repeatInterval INTEGER,
            isRepeating INTEGER NOT NULL DEFAULT 0,
            parentTaskId INTEGER,
            position INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL,
            FOREIGN KEY (parentTaskId) REFERENCES tasks (id) ON DELETE CASCADE
          )
        ''');
        debugPrint('[SQLiteDatabaseService] 创建了tasks表');

        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER NOT NULL,
            iconCodePoint INTEGER NOT NULL,
            parentId INTEGER,
            level INTEGER NOT NULL DEFAULT 0,
            sortOrder INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (parentId) REFERENCES categories (id) ON DELETE CASCADE
          )
        ''');
        debugPrint('[SQLiteDatabaseService] 创建了categories表');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_meta(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint(
          '[SQLiteDatabaseService] 升级数据库，从版本 $oldVersion 到 $newVersion',
        );

        if (oldVersion < 2) {
          // 添加二级分类支持
          await db.execute(
            'ALTER TABLE categories ADD COLUMN parentId INTEGER',
          );
          await db.execute(
            'ALTER TABLE categories ADD COLUMN level INTEGER NOT NULL DEFAULT 0',
          );
          debugPrint('[SQLiteDatabaseService] 从版本1升级到版本2，添加了二级分类支持');
        }

        if (oldVersion < 3) {
          // 添加子任务支持
          await db.execute('ALTER TABLE tasks ADD COLUMN parentTaskId INTEGER');
          debugPrint('[SQLiteDatabaseService] 从版本2升级到版本3，添加了子任务支持');
        }

        if (oldVersion < 4) {
          // 添加分类排序支持
          await db.execute(
            'ALTER TABLE categories ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0',
          );
          debugPrint('[SQLiteDatabaseService] 从版本3升级到版本4，添加了分类排序支持');
        }

        if (oldVersion < 5) {
          await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN position INTEGER NOT NULL DEFAULT 0',
          );

          final legacyTasks = await db.query(
            'tasks',
            columns: ['id', 'createdAt', 'isCompleted', 'updatedAt'],
            orderBy: 'isCompleted ASC, createdAt DESC, id ASC',
          );
          for (var index = 0; index < legacyTasks.length; index++) {
            final task = legacyTasks[index];
            await db.update(
              'tasks',
              {
                'position': index,
                if (task['isCompleted'] == 1 && task['updatedAt'] != null)
                  'completedAt': task['updatedAt'],
              },
              where: 'id = ?',
              whereArgs: [task['id']],
            );
          }
          debugPrint('[SQLiteDatabaseService] 从版本4升级到版本5，添加任务排序和完成时间');
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_meta(
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          debugPrint('[SQLiteDatabaseService] 从版本5升级到版本6，添加初始化状态表');
        }
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
    final db = await database;

    // 检查数据库是否正确创建
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    debugPrint('[SQLiteDatabaseService] 数据库表: $tables');

    // 检查现有任务数量
    final taskCount = await db.rawQuery("SELECT COUNT(*) as count FROM tasks");
    debugPrint('[SQLiteDatabaseService] 现有任务数量: $taskCount');

    _isInitialized = true;
    debugPrint('[SQLiteDatabaseService] 初始化完成');
  }

  @override
  Future<List<Task>> getTasks() async {
    debugPrint('[SQLiteDatabaseService] 获取所有任务');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'position ASC, id ASC',
    );
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个任务');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<Task> insertTask(Task task) async {
    debugPrint('[SQLiteDatabaseService] 插入任务: ${task.title}');
    final db = await database;
    final taskMap = task.toMap();
    debugPrint('[SQLiteDatabaseService] 任务数据: $taskMap');
    final id = await db.insert('tasks', taskMap);
    debugPrint('[SQLiteDatabaseService] 任务插入成功，ID: $id');

    // 验证插入是否成功
    final insertedTask = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('[SQLiteDatabaseService] 验证插入的任务: $insertedTask');

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
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
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
  Future<bool> isTaskDataInitialized() async {
    final db = await database;
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['tasks_initialized'],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['value'] == 'true';

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tasks'),
    );
    if ((count ?? 0) > 0) {
      await markTaskDataInitialized();
      return true;
    }
    return false;
  }

  @override
  Future<void> markTaskDataInitialized() async {
    final db = await database;
    await db.insert('app_meta', {
      'key': 'tasks_initialized',
      'value': 'true',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<TaskCategory>> getCategories() async {
    debugPrint('[SQLiteDatabaseService] 获取所有分类');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'level ASC, sortOrder ASC, name ASC',
    );
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个分类');
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  // 获取顶级分类
  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    debugPrint('[SQLiteDatabaseService] 获取顶级分类');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'level = 0',
      orderBy: 'sortOrder ASC, name ASC',
    );
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个顶级分类');
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  // 获取子分类
  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    debugPrint('[SQLiteDatabaseService] 获取父分类ID为 $parentId 的子分类');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'sortOrder ASC, name ASC',
    );
    debugPrint('[SQLiteDatabaseService] 获取到 ${maps.length} 个子分类');
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    debugPrint('[SQLiteDatabaseService] 插入分类: ${category.name}');
    try {
      final db = await database;
      debugPrint(
        '[SQLiteDatabaseService] 数据库连接状态: ${db.isOpen ? '已打开' : '已关闭'}',
      );

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
    debugPrint(
      '[SQLiteDatabaseService] 更新分类: ${category.id} - ${category.name}',
    );
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
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    debugPrint('[SQLiteDatabaseService] 分类删除成功');
  }

  @override
  Future<void> updateCategoryOrder(
    List<TaskCategory> reorderedCategories,
  ) async {
    debugPrint('[SQLiteDatabaseService] 开始更新分类排序');
    final db = await database;

    // 使用事务批量更新排序
    await db.transaction((txn) async {
      for (int i = 0; i < reorderedCategories.length; i++) {
        final category = reorderedCategories[i];
        await txn.update(
          'categories',
          {'sortOrder': i},
          where: 'id = ?',
          whereArgs: [category.id],
        );
      }
    });

    debugPrint('[SQLiteDatabaseService] 分类排序更新成功');
  }

  @override
  Future<bool> isCategoryDataInitialized() async {
    final db = await database;
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['categories_initialized'],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['value'] == 'true';

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if ((count ?? 0) > 0) {
      await markCategoryDataInitialized();
      return true;
    }
    return false;
  }

  @override
  Future<void> markCategoryDataInitialized() async {
    final db = await database;
    await db.insert('app_meta', {
      'key': 'categories_initialized',
      'value': 'true',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';
import 'database_interface.dart';

class SQLiteDatabaseService implements DatabaseInterface {
  static final SQLiteDatabaseService _instance = SQLiteDatabaseService._internal();
  static Database? _database;

  factory SQLiteDatabaseService() {
    return _instance;
  }

  SQLiteDatabaseService._internal();

  @override
  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'potato_todo.db'),
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN repeatFrequency TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN repeatInterval INTEGER DEFAULT 1');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN reminderPriority INTEGER DEFAULT 2');
    }
    
    if (oldVersion < 4) {
      // Add missing columns that should have been in the original schema
      await db.execute('ALTER TABLE tasks ADD COLUMN updatedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN dueDate TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN isRepeating INTEGER NOT NULL DEFAULT 0');
      
      // Remove old reminderTime column if it exists (rename to dueDate was the intention)
      // Since SQLite doesn't support DROP COLUMN, we'll leave reminderTime for backward compatibility
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isImportant INTEGER NOT NULL DEFAULT 0,
        isUrgent INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        dueDate TEXT,
        categoryId INTEGER,
        position INTEGER,
        repeatFrequency TEXT,
        repeatInterval INTEGER DEFAULT 1,
        isRepeating INTEGER NOT NULL DEFAULT 0,
        reminderPriority INTEGER DEFAULT 2
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        iconCodePoint INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<Task> insertTask(Task task) async {
    Database db = await database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  @override
  Future<int> updateTask(Task task) async {
    Database db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Task>> getTasks() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks', orderBy: 'position ASC, createdAt DESC');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'position ASC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  @override
  Future<TaskCategory> insertCategory(TaskCategory category) async {
    Database db = await database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  @override
  Future<int> updateCategory(TaskCategory category) async {
    Database db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<int> deleteCategory(int id) async {
    Database db = await database;
    await db.update(
      'tasks',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<TaskCategory>> getCategories() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  @override
  Future<List<TaskCategory>> getTopLevelCategories() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'level = 0 OR level IS NULL',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  @override
  Future<List<TaskCategory>> getSubCategories(int parentId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => TaskCategory.fromMap(maps[i]));
  }

  @override
  Future<void> clearCategoriesTable() async {
    Database db = await database;
    await db.delete('categories');
  }
} 
import '../models/category.dart';
import '../services/database_interface.dart';
import 'package:flutter/material.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseInterface _db;
  List<TaskCategory> _categories = [];
  bool _initialized = false;

  CategoryProvider(this._db) {
    debugPrint('[CategoryProvider] CategoryProvider构造函数被调用');
  }

  // 获取所有分类
  List<TaskCategory> get categories => _categories;

  // 获取顶级分类
  List<TaskCategory> get topLevelCategories =>
      _categories.where((cat) => cat.level == 0).toList();

  // 获取指定父分类的子分类
  List<TaskCategory> getSubCategories(int parentId) =>
      _categories.where((cat) => cat.parentId == parentId).toList();

  Set<int> getCategoryTreeIds(int rootId) {
    final ids = <int>{rootId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final category in _categories) {
        if (category.id != null &&
            category.parentId != null &&
            ids.contains(category.parentId) &&
            ids.add(category.id!)) {
          changed = true;
        }
      }
    }
    return ids;
  }

  // 获取分类的完整路径名称
  String getCategoryFullName(TaskCategory category) {
    if (category.level == 0) return category.name;

    List<String> path = [category.name];
    TaskCategory? current = category;

    final visited = <int>{};
    while (current?.parentId != null) {
      if (current?.id != null && !visited.add(current!.id!)) {
        break;
      }
      current = getCategoryById(current!.parentId);
      if (current != null) {
        path.insert(0, current.name);
      }
    }

    return path.join(' > ');
  }

  // 初始化
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[CategoryProvider] 已初始化，跳过');
      return;
    }

    debugPrint('[CategoryProvider] 开始初始化');
    await loadCategories();

    final dataWasInitialized = await _db.isCategoryDataInitialized();
    if (_categories.isEmpty && !dataWasInitialized) {
      debugPrint('[CategoryProvider] 没有找到分类，创建默认分类');
      await createDefaultCategories();
      await _db.markCategoryDataInitialized();
    } else {
      debugPrint('[CategoryProvider] 已加载 ${_categories.length} 个分类');
    }

    _initialized = true;
    debugPrint('[CategoryProvider] 初始化完成');
  }

  // 从数据库加载所有分类
  Future<void> loadCategories() async {
    try {
      debugPrint('[CategoryProvider] 从数据库加载分类');
      _categories = await _db.getCategories();
      debugPrint('[CategoryProvider] 成功加载 ${_categories.length} 个分类');
      notifyListeners();
    } catch (e) {
      debugPrint('[CategoryProvider] 加载分类出错: $e');
      if (e is Error) {
        debugPrint('[CategoryProvider] 错误堆栈: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  // 添加分类
  Future<void> addCategory(TaskCategory category) async {
    try {
      debugPrint('[CategoryProvider] 开始添加分类: ${category.name}');
      debugPrint(
        '[CategoryProvider] 分类数据: color=${category.color.toARGB32()}, iconCodePoint=${category.iconCodePoint}',
      );

      if (category.name.trim().isEmpty) {
        throw Exception('分类名称不能为空');
      }

      _validateCategoryParent(category.id, category.parentId);
      final normalizedCategory = category.copyWith(
        level:
            category.parentId == null
                ? 0
                : getCategoryById(category.parentId)!.level + 1,
      );
      final newCategory = await _db.insertCategory(normalizedCategory);
      debugPrint('[CategoryProvider] 分类添加成功，ID: ${newCategory.id}');
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      debugPrint('[CategoryProvider] 添加分类出错: $e');
      if (e is Error) {
        debugPrint('[CategoryProvider] 错误堆栈: ${e.stackTrace}');
      }

      // 显示具体错误给用户
      String errorMessage = '添加分类失败';
      if (e.toString().contains('UNIQUE constraint failed')) {
        errorMessage = '分类名称已存在';
      } else if (e.toString().contains('NOT NULL constraint failed')) {
        errorMessage = '分类信息不完整';
      }

      debugPrint('[CategoryProvider] 错误消息: $errorMessage');
      rethrow;
    }
  }

  // 更新分类
  Future<void> updateCategory(TaskCategory category) async {
    try {
      debugPrint('[CategoryProvider] 更新分类: ${category.id} - ${category.name}');
      if (category.id == null) {
        throw ArgumentError('Cannot update a category without an id');
      }
      if (!_categories.any((candidate) => candidate.id == category.id)) {
        throw StateError('Category ${category.id} does not exist');
      }
      _validateCategoryParent(category.id, category.parentId);
      final normalizedCategory = category.copyWith(
        level:
            category.parentId == null
                ? 0
                : getCategoryById(category.parentId)!.level + 1,
      );
      await _db.updateCategory(normalizedCategory);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = normalizedCategory;
        debugPrint('[CategoryProvider] 分类更新成功');
      } else {
        debugPrint('[CategoryProvider] 未找到要更新的分类');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CategoryProvider] 更新分类出错: $e');
      rethrow;
    }
  }

  void _validateCategoryParent(int? categoryId, int? parentId) {
    if (parentId == null) return;
    if (categoryId != null && categoryId == parentId) {
      throw ArgumentError.value(
        parentId,
        'parentId',
        'A category cannot be its own parent',
      );
    }
    final parent = getCategoryById(parentId);
    if (parent == null) {
      throw ArgumentError.value(
        parentId,
        'parentId',
        'Parent category does not exist',
      );
    }
    if (categoryId != null &&
        getCategoryTreeIds(categoryId).contains(parentId)) {
      throw ArgumentError.value(
        parentId,
        'parentId',
        'A category cannot be moved below one of its descendants',
      );
    }
  }

  // 删除分类
  Future<void> deleteCategory(int id) async {
    try {
      debugPrint('[CategoryProvider] 开始删除分类: $id');

      // 获取要删除的分类
      final categoryToDelete = getCategoryById(id);
      if (categoryToDelete == null) {
        debugPrint('[CategoryProvider] 未找到要删除的分类: $id');
        return;
      }

      final categoryIds = getCategoryTreeIds(id);
      debugPrint('[CategoryProvider] 找到 ${categoryIds.length - 1} 个后代分类');

      // Delete every descendant as well, so implementations without database
      // cascade support keep the same behavior.
      for (final categoryId in categoryIds) {
        await _db.deleteCategory(categoryId);
      }

      // 从内存中移除分类及其子分类
      _categories.removeWhere(
        (cat) => cat.id != null && categoryIds.contains(cat.id),
      );

      notifyListeners();
      debugPrint('[CategoryProvider] 分类删除成功: $id');
    } catch (e) {
      debugPrint('[CategoryProvider] 删除分类出错: $e');
      rethrow;
    }
  }

  // 根据ID获取分类
  TaskCategory? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // 创建默认分类
  Future<void> createDefaultCategories() async {
    debugPrint('[CategoryProvider] 开始创建默认分类');
    final createdIds = <int>[];
    try {
      await addCategory(
        TaskCategory(
          name: "工作",
          color: Colors.blue,
          iconCodePoint: Icons.work.codePoint,
        ),
      );
      if (_categories.last.id != null) createdIds.add(_categories.last.id!);

      await addCategory(
        TaskCategory(
          name: "个人",
          color: Colors.green,
          iconCodePoint: Icons.person.codePoint,
        ),
      );
      if (_categories.last.id != null) createdIds.add(_categories.last.id!);

      await addCategory(
        TaskCategory(
          name: "学习",
          color: Colors.orange,
          iconCodePoint: Icons.school.codePoint,
        ),
      );
      if (_categories.last.id != null) createdIds.add(_categories.last.id!);

      await addCategory(
        TaskCategory(
          name: "购物",
          color: Colors.purple,
          iconCodePoint: Icons.shopping_cart.codePoint,
        ),
      );
      if (_categories.last.id != null) createdIds.add(_categories.last.id!);

      debugPrint('[CategoryProvider] 默认分类创建完成');
    } catch (e) {
      debugPrint('[CategoryProvider] 创建默认分类出错: $e');
      for (final id in createdIds) {
        await _db.deleteCategory(id);
      }
      _categories.removeWhere(
        (category) => category.id != null && createdIds.contains(category.id),
      );
      rethrow;
    }
  }

  // 清除所有分类（测试用）
  Future<void> clearAllCategories({bool recreateDefaults = true}) async {
    try {
      for (final category in [..._categories]) {
        if (category.id != null) {
          await _db.deleteCategory(category.id!);
        }
      }
      _categories.clear();
      await _db.markCategoryDataInitialized();
      notifyListeners();
      debugPrint('所有分类已清除');

      if (recreateDefaults) {
        // 重新创建默认分类
        await createDefaultCategories();
      }
    } catch (e) {
      debugPrint('清除分类失败: $e');
      rethrow;
    }
  }

  // 更新分类排序
  Future<void> updateCategoryOrder(
    List<TaskCategory> reorderedCategories,
  ) async {
    try {
      debugPrint('[CategoryProvider] 开始更新分类排序');

      // 更新每个分类的排序顺序
      for (int i = 0; i < reorderedCategories.length; i++) {
        final category = reorderedCategories[i];
        final updatedCategory = category.copyWith(sortOrder: i);
        await _db.updateCategory(updatedCategory);

        // 更新内存中的分类
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = updatedCategory;
        }
      }

      notifyListeners();
      debugPrint('[CategoryProvider] 分类排序更新成功');
    } catch (e) {
      debugPrint('[CategoryProvider] 更新分类排序出错: $e');
      rethrow;
    }
  }

  // 获取指定层级的分类（用于排序）
  List<TaskCategory> getCategoriesByLevel(int level) {
    return _categories.where((cat) => cat.level == level).toList();
  }

  // 获取指定父分类的子分类（用于排序）
  List<TaskCategory> getSubCategoriesForSorting(int parentId) {
    return _categories.where((cat) => cat.parentId == parentId).toList();
  }

  Future<void> importCategories(
    List<Map<String, dynamic>> categoriesJson,
  ) async {
    final pending = categoriesJson.map(TaskCategory.fromJson).toList();
    final categoryIds = <int>{};
    for (final category in pending) {
      final categoryId = category.id;
      if (categoryId == null || !categoryIds.add(categoryId)) {
        throw const FormatException('备份中的分类ID无效或重复');
      }
      if (category.parentId != null &&
          !pending.any((candidate) => candidate.id == category.parentId)) {
        throw FormatException('分类 ${category.id} 引用了不存在的父分类');
      }
      if (category.parentId == category.id) {
        throw FormatException('分类 ${category.id} 存在循环父引用');
      }
    }

    final insertedIds = <int>{};
    while (pending.isNotEmpty) {
      final readyCategories =
          pending
              .where(
                (category) =>
                    category.parentId == null ||
                    insertedIds.contains(category.parentId),
              )
              .toList();
      if (readyCategories.isEmpty) {
        throw const FormatException('备份中的分类层级存在循环引用');
      }

      for (final category in readyCategories) {
        final parent =
            category.parentId == null
                ? null
                : _categories.firstWhere(
                  (candidate) => candidate.id == category.parentId,
                );
        final normalizedCategory = category.copyWith(
          level: parent == null ? 0 : parent.level + 1,
        );
        final persistedCategory = await _db.insertCategory(normalizedCategory);
        _categories.add(persistedCategory);
        insertedIds.add(category.id!);
        pending.remove(category);
      }
    }
    await _db.markCategoryDataInitialized();
    notifyListeners();
  }
}

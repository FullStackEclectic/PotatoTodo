import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../services/database_interface.dart';
import 'package:flutter/material.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseInterface _db;
  List<TaskCategory> _categories = [];
  bool _initialized = false;
  
  CategoryProvider(this._db) {
    debugPrint('[CategoryProvider] CategoryProvider构造函数被调用');
    initialize();
  }

  // 获取所有分类
  List<TaskCategory> get categories => _categories;

  // 初始化
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[CategoryProvider] 已初始化，跳过');
      return;
    }
    
    debugPrint('[CategoryProvider] 开始初始化');
    await loadCategories();
    
    // 如果没有分类，创建默认分类
    if (_categories.isEmpty) {
      debugPrint('[CategoryProvider] 没有找到分类，创建默认分类');
      await createDefaultCategories();
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
      _categories = [];
      notifyListeners();
    }
  }

  // 添加分类
  Future<void> addCategory(TaskCategory category) async {
    try {
      debugPrint('[CategoryProvider] 开始添加分类: ${category.name}');
      debugPrint('[CategoryProvider] 分类数据: color=${category.color.value}, iconCodePoint=${category.iconCodePoint}');
      
      // 验证字段是否合法
      if (category.name.isEmpty) {
        throw Exception('分类名称不能为空');
      }
      
      final newCategory = await _db.insertCategory(category);
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
      await _db.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
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

  // 删除分类
  Future<void> deleteCategory(int id) async {
    try {
      await _db.deleteCategory(id);
      _categories.removeWhere((cat) => cat.id == id);
      notifyListeners();
      debugPrint('Category with id $id deleted');
    } catch (e) {
      debugPrint('Error deleting category: $e');
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
    try {
      await addCategory(
        TaskCategory(
          name: "工作",
          color: Colors.blue,
          iconCodePoint: Icons.work.codePoint,
        ),
      );
      
      await addCategory(
        TaskCategory(
          name: "个人",
          color: Colors.green,
          iconCodePoint: Icons.person.codePoint,
        ),
      );
      
      await addCategory(
        TaskCategory(
          name: "学习",
          color: Colors.orange,
          iconCodePoint: Icons.school.codePoint,
        ),
      );
      
      await addCategory(
        TaskCategory(
          name: "购物",
          color: Colors.purple,
          iconCodePoint: Icons.shopping_cart.codePoint,
        ),
      );
      
      debugPrint('[CategoryProvider] 默认分类创建完成');
    } catch (e) {
      debugPrint('[CategoryProvider] 创建默认分类出错: $e');
      if (e is Error) {
        debugPrint('[CategoryProvider] 错误堆栈: ${e.stackTrace}');
      }
    }
  }

  // 清除所有分类（测试用）
  Future<void> clearAllCategories() async {
    try {
      for (final category in [..._categories]) {
        if (category.id != null) {
          await _db.deleteCategory(category.id!);
        }
      }
      _categories.clear();
      notifyListeners();
      debugPrint('所有分类已清除');
      
      // 重新创建默认分类
      await createDefaultCategories();
    } catch (e) {
      debugPrint('清除分类失败: $e');
      rethrow;
    }
  }
} 
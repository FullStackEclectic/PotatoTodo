import '../models/task.dart';
import '../models/category.dart';

abstract class DatabaseInterface {
  // 初始化数据库
  Future<void> initialize();

  // 任务相关操作
  Future<List<Task>> getTasks();
  Future<Task> insertTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int id);
  Future<List<Task>> getTasksByCategory(int categoryId);
  Future<List<Task>> searchTasks(String query);

  // 分类相关操作
  Future<List<TaskCategory>> getCategories();
  Future<List<TaskCategory>> getTopLevelCategories();
  Future<List<TaskCategory>> getSubCategories(int parentId);
  Future<TaskCategory> insertCategory(TaskCategory category);
  Future<void> updateCategory(TaskCategory category);
  Future<void> deleteCategory(int id);
  Future<void> updateCategoryOrder(List<TaskCategory> reorderedCategories);
  
  // 测试用工具方法
  Future<void> clearCategoriesTable();
} 
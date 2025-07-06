import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form.dart';

class CategoryListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool initiallyShowForm;

  const CategoryListScreen({
    Key? key,
    this.showAppBar = true,
    this.initiallyShowForm = false,
  }) : super(key: key);

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _showForm = widget.initiallyShowForm;
  }

  // 显示添加/编辑分类底部表单
  void _showCategoryForm(BuildContext context, {TaskCategory? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category == null ? '添加分类' : '编辑分类',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CategoryForm(
                category: category,
                onSave: (updatedCategory) async {
                  // 添加打印语句
                  debugPrint('[CategoryListScreen] onSave called. Category: ${updatedCategory.name}, ID: ${updatedCategory.id}');

                  final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

                  try { // 添加 try-catch 块
                    if (category == null) {
                      // 添加新分类
                      debugPrint('[CategoryListScreen] Adding new category...');
                      await categoryProvider.addCategory(updatedCategory);
                      debugPrint('[CategoryListScreen] Category added successfully.');
                    } else {
                      // 更新现有分类
                      debugPrint('[CategoryListScreen] Updating category...');
                      await categoryProvider.updateCategory(updatedCategory);
                       debugPrint('[CategoryListScreen] Category updated successfully.');
                    }
                  } catch (e) {
                     debugPrint('[CategoryListScreen] Error saving category: $e');
                     // 可以在这里显示错误提示给用户
                     if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('保存分类失败: $e')),
                         );
                     }
                  }

                  // 关闭底部表单
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 显示删除确认对话框
  Future<void> _showDeleteConfirmation(BuildContext context, TaskCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？该分类下的任务将变为无分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (category.id != null) {
        await categoryProvider.deleteCategory(category.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Text(_showForm ? '添加分类' : '管理分类'),
        actions: [
          if (!_showForm)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
            ),
        ],
      ) : null,
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          final categories = categoryProvider.categories;
          
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有分类',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showCategoryForm(context),
                    child: const Text('添加分类'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: category.color,
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showCategoryForm(context, category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteConfirmation(context, category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context),
        tooltip: '添加分类',
        child: const Icon(Icons.add),
      ),
    );
  }
} 
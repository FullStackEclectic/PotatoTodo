import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
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
  Set<int> _expandedCategories = {}; // 记录展开的分类ID
  bool _isReordering = false; // 是否处于排序模式
  List<TaskCategory> _reorderedCategories = []; // 重新排序后的分类列表

  @override
  void initState() {
    super.initState();
    // 如果需要初始显示表单，直接显示
    if (widget.initiallyShowForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCategoryForm(context);
      });
    }
  }

  // 切换分类的展开/折叠状态
  void _toggleExpansion(int categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
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
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final subCategories = categoryProvider.getSubCategories(category.id!);
    
    String message = '确定要删除分类"${category.name}"吗？';
    if (subCategories.isNotEmpty) {
      message += '\n该分类下有 ${subCategories.length} 个子分类，删除后子分类也将被删除。';
    }
    message += '\n该分类下的任务将变为无分类。';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
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
      if (category.id != null) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        await categoryProvider.deleteCategory(category.id!);
        taskProvider.removeCategoryFromTasks(category.id!);
      }
    }
  }

  // 构建分类项
  Widget _buildCategoryItem(TaskCategory category, CategoryProvider categoryProvider, {int indentLevel = 0}) {
    final subCategories = category.id != null ? categoryProvider.getSubCategories(category.id!) : [];
    final hasSubCategories = subCategories.isNotEmpty;
    final isExpanded = category.id != null && _expandedCategories.contains(category.id);
    
    // 在排序模式下，只显示顶级分类
    if (_isReordering && category.level > 0) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Card(
          margin: EdgeInsets.only(
            left: 8 + (indentLevel * 24), // 根据层级增加缩进
            right: 8,
            top: 4,
            bottom: 4,
          ),
          child: ListTile(
            leading: _isReordering 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 8),
                    Icon(
                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: category.color,
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSubCategories && category.id != null)
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        onPressed: () => _toggleExpansion(category.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (hasSubCategories) const SizedBox(width: 8),
                    Icon(
                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: category.color,
                    ),
                  ],
                ),
            title: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: category.level > 0 ? Text(
              '子分类',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ) : null,
            trailing: _isReordering ? null : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSubCategories)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${subCategories.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: category.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
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
        ),
        // 显示子分类（排序模式下不显示）
        if (hasSubCategories && isExpanded && !_isReordering)
          ...subCategories.map((subCategory) => 
            _buildCategoryItem(subCategory, categoryProvider, indentLevel: indentLevel + 1)
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Text(_isReordering ? '排序分类' : '管理分类'),
        actions: [
          if (!_isReordering) ...[
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                final topLevelCategories = categoryProvider.topLevelCategories;
                debugPrint('[CategoryListScreen] 进入排序模式，顶级分类数量: ${topLevelCategories.length}');
                setState(() {
                  _isReordering = true;
                  _reorderedCategories = List.from(topLevelCategories);
                });
                debugPrint('[CategoryListScreen] 排序列表初始化完成，数量: ${_reorderedCategories.length}');
              },
              tooltip: '排序分类',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCategoryForm(context),
              tooltip: '添加分类',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                try {
                  await categoryProvider.updateCategoryOrder(_reorderedCategories);
                  setState(() {
                    _isReordering = false;
                    _reorderedCategories.clear();
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('分类排序已保存')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('保存排序失败: $e')),
                    );
                  }
                }
              },
              tooltip: '完成排序',
            ),
          ],
        ],
      ) : null,
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          final topLevelCategories = categoryProvider.topLevelCategories;
          
          if (topLevelCategories.isEmpty) {
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
          
          // 确保在排序模式下有数据
          if (_isReordering && _reorderedCategories.isEmpty) {
            _reorderedCategories = List.from(topLevelCategories);
          }
          
          // 如果排序模式下没有分类，显示提示信息
          if (_isReordering && _reorderedCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sort,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有可排序的分类',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isReordering = false;
                      });
                    },
                    child: const Text('返回'),
                  ),
                ],
              ),
            );
          }
          
          return _isReordering 
            ? ReorderableListView.builder(
                itemCount: _reorderedCategories.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _reorderedCategories.removeAt(oldIndex);
                    _reorderedCategories.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final category = _reorderedCategories[index];
                  return Container(
                    key: ValueKey(category.id),
                    child: _buildCategoryItem(category, categoryProvider),
                  );
                },
              )
            : ListView.builder(
                itemCount: topLevelCategories.length,
                itemBuilder: (context, index) {
                  final category = topLevelCategories[index];
                  return _buildCategoryItem(category, categoryProvider);
                },
              );
        },
      ),

    );
  }
} 
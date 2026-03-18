import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';

class CategoryPanel extends StatelessWidget {
  final bool isCollapsed;

  const CategoryPanel({Key? key, this.isCollapsed = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        final taskProvider = Provider.of<TaskProvider>(context);
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCollapsed)
                    Text(
                      '分类',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  if (!isCollapsed)
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: '新建分类',
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        Navigator.pushNamed(context, '/category_list', arguments: true);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: _buildCategoryList(context, categoryProvider, taskProvider, theme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(BuildContext context, CategoryProvider categoryProvider, TaskProvider taskProvider, ThemeData theme) {
    final categories = categoryProvider.categories;
    if (categories.isEmpty) {
      return isCollapsed 
        ? const SizedBox.shrink() 
        : Center(child: Text('暂无分类', style: theme.textTheme.bodySmall));
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 8),
      children: categoryProvider.topLevelCategories.map((category) {
        return _buildCategoryTreeItem(context, category, categoryProvider, taskProvider, theme);
      }).toList(),
    );
  }

  Widget _buildCategoryTreeItem(
    BuildContext context, 
    TaskCategory category, 
    CategoryProvider categoryProvider, 
    TaskProvider taskProvider, 
    ThemeData theme,
    {int indentLevel = 0}
  ) {
    final subCategories = categoryProvider.getSubCategories(category.id!);
    final isSelected = taskProvider.selectedCategoryId == category.id;
    
    Widget item;
    if (isCollapsed) {
      item = Tooltip(
        message: category.name,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                taskProvider.setSelectedCategory(category.id);
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: isSelected ? theme.colorScheme.primary : category.color,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      item = Material(
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            taskProvider.setSelectedCategory(category.id);
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if(isSelected)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2)
                    ),
                  ),
                if(isSelected) const SizedBox(width: 6),
                Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: category.color, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (taskProvider.getTasksByCategory(category.id!).isNotEmpty)
                  Text(
                    taskProvider.getTasksByCategory(category.id!).length.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (isCollapsed) return Center(child: item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: (indentLevel * 16.0)),
          child: item,
        ),
        if (subCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subCategories.map((subCategory) {
                return _buildCategoryTreeItem(context, subCategory, categoryProvider, taskProvider, theme, indentLevel: indentLevel + 1);
              }).toList(),
            ),
          ),
      ],
    );
  }
}
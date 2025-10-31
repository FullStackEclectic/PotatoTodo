import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';

class TaskHeaderWidget extends StatelessWidget {
  final VoidCallback? onFilterChanged;
  final VoidCallback? onDateFilter;
  final VoidCallback? onStatusFilter;
  final VoidCallback? onSearchToggle;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const TaskHeaderWidget({
    Key? key,
    this.onFilterChanged,
    this.onDateFilter,
    this.onStatusFilter,
    this.onSearchToggle,
    this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 顶部操作栏 - 包含统计信息
          _buildTopActionBar(theme),
          
          const SizedBox(height: 12),
          
          // 筛选器区域 - 紧凑设计
          _buildCompactFilters(theme),
        ],
      ),
    );
  }

  Widget _buildTopActionBar(ThemeData theme) {
    return Builder(
      builder: (context) => Row(
        children: [
          // 左侧菜单按钮
          IconButton(
            onPressed: () {
              // 使用GlobalKey打开抽屉
              if (scaffoldKey?.currentState != null) {
                scaffoldKey!.currentState!.openDrawer();
              }
            },
            icon: Icon(
              Icons.menu,
              size: 24,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            tooltip: '打开菜单',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 中间的紧凑统计信息
          Expanded(
            child: _buildCompactStats(theme),
          ),
          
          const SizedBox(width: 12),
          
          // 右侧搜索按钮
          IconButton(
            onPressed: () {
              // 触发搜索功能
              onSearchToggle?.call();
            },
            icon: Icon(
              Icons.search,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            tooltip: '搜索任务',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsCard(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        final totalTasks = tasks.length;
        final completedTasks = tasks.where((task) => task.isCompleted).length;
        final pendingTasks = totalTasks - completedTasks;
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 主要统计
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '任务统计',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalTasks 个任务',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 分隔线
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              
              // 详细统计
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        '已完成',
                        completedTasks.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        '待完成',
                        pendingTasks.toString(),
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        theme,
                        '完成率',
                        '${completionRate.toStringAsFixed(0)}%',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilters(ThemeData theme) {
    return Column(
      children: [
        // 合并的筛选行：全部 + 分类 + 状态筛选按钮
        _buildMergedFilters(theme),
      ],
    );
  }

  Widget _buildMergedFilters(ThemeData theme) {
    return Consumer2<TaskProvider, CategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        final categories = categoryProvider.topLevelCategories;
        
        return Row(
          children: [
            // 左侧：分类标签（可滚动）
            Expanded(
              child: categories.isEmpty 
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = taskProvider.selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildModernCategoryChip(theme, category, isSelected, taskProvider),
                        );
                      }).toList(),
                    ),
                  ),
            ),
            
            const SizedBox(width: 8),
            
            // 右侧：状态筛选按钮
            _buildStatusFilterButton(theme, taskProvider),
          ],
        );
      },
    );
  }

  Widget _buildStatusFilterButton(ThemeData theme, TaskProvider taskProvider) {
    // 确定当前状态筛选的文本和图标
    String statusText;
    IconData statusIcon;
    
    if (taskProvider.completedTasksOnly) {
      statusText = '已完成';
      statusIcon = Icons.check_circle;
    } else if (!taskProvider.showCompletedTasks) {
      statusText = '未完成';
      statusIcon = Icons.radio_button_unchecked;
    } else {
      statusText = '全部';
      statusIcon = Icons.filter_list;
    }
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'all':
            taskProvider.setShowCompletedTasks(true);
            taskProvider.setSelectedCategory(null);
            taskProvider.setSelectedQuadrant(null);
            break;
          case 'completed':
            taskProvider.setShowCompletedTasksOnly(true);
            taskProvider.setSelectedCategory(null);
            taskProvider.setSelectedQuadrant(null);
            break;
          case 'pending':
            taskProvider.setShowCompletedTasks(false);
            taskProvider.setSelectedCategory(null);
            taskProvider.setSelectedQuadrant(null);
            break;
        }
        onFilterChanged?.call();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'all',
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              const Text('全部'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'completed',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              const Text('已完成'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pending',
          child: Row(
            children: [
              Icon(Icons.radio_button_unchecked, size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              const Text('未完成'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterChip(ThemeData theme, String label, IconData? icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected 
                  ? Colors.white 
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                  ? Colors.white 
                  : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCategoryChip(ThemeData theme, TaskCategory category, bool isSelected, TaskProvider taskProvider) {
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          taskProvider.setSelectedCategory(null);
        } else {
          taskProvider.setSelectedCategory(category.id);
        }
        onFilterChanged?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected 
            ? category.color 
            : category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(isSelected ? 1 : 0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: category.color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
              size: 12,
              color: isSelected ? Colors.white : category.color,
            ),
            const SizedBox(width: 4),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStats(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        final totalTasks = tasks.length;
        final completedTasks = tasks.where((task) => task.isCompleted).length;
        final pendingTasks = totalTasks - completedTasks;
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 总任务数
              _buildCompactStatItem(
                theme,
                totalTasks.toString(),
                '总计',
                theme.colorScheme.primary,
              ),
              
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              
              // 已完成
              _buildCompactStatItem(
                theme,
                completedTasks.toString(),
                '完成',
                Colors.green,
              ),
              
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              
              // 待完成
              _buildCompactStatItem(
                theme,
                pendingTasks.toString(),
                '待办',
                Colors.orange,
              ),
              
              if (totalTasks > 0) ...[
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                
                // 完成率
                _buildCompactStatItem(
                  theme,
                  '${completionRate.toStringAsFixed(0)}%',
                  '完成率',
                  Colors.blue,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatItem(ThemeData theme, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  void _clearFilters(TaskProvider taskProvider) {
    taskProvider.setSelectedCategory(null);
    taskProvider.setSelectedQuadrant(null);
    onFilterChanged?.call();
  }
} 
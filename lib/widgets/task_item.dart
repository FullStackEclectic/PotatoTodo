import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../services/haptic_service.dart';
import '../services/priority_recommendation_service.dart';
import '../constants/quadrant_constants.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(bool)? onCompletedChanged;
  final VoidCallback? onDeleteRequested;
  final bool showSubTasks;

  const TaskItem({
    Key? key,
    required this.task,
    this.onTap,
    this.onLongPress,
    this.onCompletedChanged,
    this.onDeleteRequested,
    this.showSubTasks = true,
  }) : super(key: key);

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final TaskCategory? category = categoryProvider.getCategoryById(widget.task.categoryId);
    
    final priorityColor = PriorityRecommendationService.getPriorityColor(widget.task);
    final priorityIcon = PriorityRecommendationService.getPriorityIcon(widget.task);
    
    // 获取子任务
    final subTasks = widget.showSubTasks && widget.task.isMainTask 
        ? taskProvider.getSubTasks(widget.task.id!) 
        : <Task>[];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          // 主任务
          Slidable(
            key: Key('task_${widget.task.id}'),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    await HapticService.heavyImpact();
                    widget.onDeleteRequested?.call();
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: '删除',
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                HapticService.lightImpact();
                widget.onTap?.call();
              },
              onLongPress: () {
                HapticService.mediumImpact();
                widget.onLongPress?.call();
              },
              child: Card(
                elevation: widget.task.isCompleted ? 0 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 完成状态复选框
                      _buildCompletionCheckbox(theme),
                      const SizedBox(width: 12),
                      
                      // 任务内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 任务标题和优先级
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.task.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      decoration: widget.task.isCompleted 
                                        ? TextDecoration.lineThrough 
                                        : null,
                                      color: widget.task.isCompleted 
                                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                                        : theme.colorScheme.onSurface,
                                      fontWeight: widget.task.isCompleted 
                                        ? FontWeight.normal 
                                        : FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!widget.task.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      priorityIcon,
                                      size: 12,
                                      color: priorityColor,
                                    ),
                                  ),
                              ],
                            ),
                            
                            // 任务描述
                            if (widget.task.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.task.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  decoration: widget.task.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            
                            // 子任务进度和元信息
                            if (!widget.task.isCompleted) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // 子任务进度
                                  if (subTasks.isNotEmpty) ...[
                                    _buildSubTaskProgress(theme, subTasks),
                                    const SizedBox(width: 8),
                                  ],
                                  // 任务元信息
                                  Expanded(
                                    child: _buildTaskMetadata(theme, category),
                                  ),
                                  // 展开/收起按钮
                                  if (subTasks.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 子任务列表
          if (subTasks.isNotEmpty && _isExpanded) ...[
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(left: 32),
              child: Column(
                children: subTasks.map((subTask) => _buildSubTaskItem(theme, subTask, taskProvider)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubTaskItem(ThemeData theme, Task subTask, TaskProvider taskProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // 子任务完成状态
          GestureDetector(
            onTap: () async {
              await taskProvider.toggleSubTaskCompletion(widget.task.id!, subTask);
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: subTask.isCompleted 
                  ? Colors.green 
                  : Colors.transparent,
                border: Border.all(
                  color: subTask.isCompleted 
                    ? Colors.green 
                    : theme.colorScheme.outline,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: subTask.isCompleted
                ? Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  )
                : null,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 子任务标题
          Expanded(
            child: Text(
              subTask.title,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: subTask.isCompleted 
                  ? TextDecoration.lineThrough 
                  : null,
                color: subTask.isCompleted
                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                  : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTaskProgress(ThemeData theme, List<Task> subTasks) {
    final completedCount = subTasks.where((task) => task.isCompleted).length;
    final totalCount = subTasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist,
            size: 10,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 2),
          Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCheckbox(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        widget.onCompletedChanged?.call(!widget.task.isCompleted);
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.task.isCompleted 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline,
            width: 2,
          ),
          color: widget.task.isCompleted 
            ? theme.colorScheme.primary 
            : Colors.transparent,
        ),
        child: widget.task.isCompleted
          ? Icon(
              Icons.check,
              size: 12,
              color: theme.colorScheme.onPrimary,
            )
          : null,
      ),
    );
  }

  Widget _buildTaskMetadata(ThemeData theme, TaskCategory? category) {
    return Row(
      children: [
        // 分类标签
        if (category != null) ...[
          _buildCategoryChip(category),
          const SizedBox(width: 6),
        ],
        
        // 截止日期
        if (widget.task.dueDate != null) ...[
          _buildDueDateChip(theme),
          const SizedBox(width: 6),
        ],
        
        // 四象限指示器
        _buildQuadrantChip(theme),
      ],
    );
  }

  Widget _buildCategoryChip(TaskCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: category.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
            size: 10,
            color: category.color,
          ),
          const SizedBox(width: 2),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip(ThemeData theme) {
    final now = DateTime.now();
    final dueDate = widget.task.dueDate!;
    final isOverdue = dueDate.isBefore(now) && !widget.task.isCompleted;
    final isToday = dueDate.year == now.year && 
                   dueDate.month == now.month && 
                   dueDate.day == now.day;
    
    Color chipColor;
    IconData chipIcon;
    
    if (isOverdue) {
      chipColor = Colors.red;
      chipIcon = Icons.schedule;
    } else if (isToday) {
      chipColor = Colors.orange;
      chipIcon = Icons.today;
    } else {
      chipColor = Colors.blue;
      chipIcon = Icons.event;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 10,
            color: chipColor,
          ),
          const SizedBox(width: 2),
          Text(
            isToday ? '今天' : DateFormat('MM/dd').format(dueDate),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantChip(ThemeData theme) {
    final quadrantType = widget.task.quadrant;
    final quadrantColor = QuadrantConstants.getQuadrantColor(quadrantType);
    final quadrantIcon = QuadrantConstants.getQuadrantIcon(quadrantType);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: quadrantColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quadrantColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            quadrantIcon,
            size: 10,
            color: quadrantColor,
          ),
          const SizedBox(width: 2),
          Text(
            _getQuadrantShortName(quadrantType),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: quadrantColor,
            ),
          ),
        ],
      ),
    );
  }



  String _getQuadrantShortName(QuadrantType type) {
    switch (type) {
      case QuadrantType.importantUrgent:
        return '重要紧急';
      case QuadrantType.importantNotUrgent:
        return '重要不紧急';
      case QuadrantType.notImportantUrgent:
        return '紧急不重要';
      case QuadrantType.notImportantNotUrgent:
        return '不重要不紧急';
    }
  }
} 
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
    
    // 获取子任务
    final subTasks = widget.showSubTasks && widget.task.isMainTask 
        ? taskProvider.getSubTasks(widget.task.id!) 
        : <Task>[];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Increased breathing room
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Very subtle diffuse shadow
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
         borderRadius: BorderRadius.circular(20),
         child: Slidable(
            key: Key('task_${widget.task.id}'),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    await HapticService.heavyImpact();
                    widget.onDeleteRequested?.call();
                  },
                  backgroundColor: Colors.red.withOpacity(0.9), // Softer red
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticService.lightImpact();
                  widget.onTap?.call();
                },
                onLongPress: () {
                  HapticService.mediumImpact();
                  widget.onLongPress?.call();
                },
                child: IntrinsicHeight( // For accent bar to stretch
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Priority Accent Bar
                      if (!widget.task.isCompleted)
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20), 
                              bottomLeft: Radius.circular(20)
                            ),
                          ),
                        ),
                      
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 20, 20), // Generous padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  // Checkbox
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2), // Align with text cap height
                                    child: _buildCompletionCheckbox(theme),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Hero(
                                          tag: 'task_title_${widget.task.id}',
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Text(
                                              widget.task.title,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                                                color: widget.task.isCompleted 
                                                  ? theme.colorScheme.onSurface.withOpacity(0.4)
                                                  : theme.colorScheme.onSurface,
                                                fontWeight: widget.task.isCompleted ? FontWeight.normal : FontWeight.w600,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        
                                        // Description
                                        if (widget.task.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.task.description,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              height: 1.4,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        
                                        // Metadata Row
                                        if (!widget.task.isCompleted) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                               // Subtasks
                                              if (subTasks.isNotEmpty) ...[
                                                _buildSubTaskMetrics(theme, subTasks),
                                                const SizedBox(width: 12),
                                              ],
                                              Expanded(child: _buildTaskMetadata(theme, category)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Expanded Subtasks
                               if (subTasks.isNotEmpty && !widget.task.isCompleted) ...[
                                 // Expand button area
                                 GestureDetector(
                                   behavior: HitTestBehavior.opaque,
                                   onTap: () => setState(() => _isExpanded = !_isExpanded),
                                   child: Padding(
                                     padding: const EdgeInsets.only(top: 12, left: 44), // Logically aligned
                                     child: Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Icon(
                                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: theme.colorScheme.primary.withOpacity(0.7),
                                         ),
                                         const SizedBox(width: 4),
                                         Text(
                                           _isExpanded ? '收起子任务' : '查看子任务',
                                           style: theme.textTheme.labelMedium?.copyWith(
                                             color: theme.colorScheme.primary.withOpacity(0.7),
                                             fontWeight: FontWeight.w500,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
         ),
      ),
    );
  }

  // Simplified Subtask Metrics (Text based)
  Widget _buildSubTaskMetrics(ThemeData theme, List<Task> subTasks) {
    final completedCount = subTasks.where((task) => task.isCompleted).length;
    final totalCount = subTasks.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$completedCount/$totalCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24, 
        height: 24, 
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.task.isCompleted 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3), // Softer outline
            width: 2,
          ),
          color: widget.task.isCompleted 
            ? theme.colorScheme.primary 
            : Colors.transparent,
        ),
        child: widget.task.isCompleted
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
      ),
    );
  }
  
  Widget _buildTaskMetadata(ThemeData theme, TaskCategory? category) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (category != null) _buildMinimalTag(
          icon: IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
          label: category.name,
          color: category.color,
        ),
        
        if (widget.task.dueDate != null) _buildDateTag(theme),
        
        // Only show quadrant if it's important or urgent
        if (widget.task.isImportant || widget.task.isUrgent)
           _buildMinimalTag(
             icon: QuadrantConstants.getQuadrantIcon(widget.task.quadrant),
             label: _getQuadrantShortName(widget.task.quadrant),
             color: QuadrantConstants.getQuadrantColor(widget.task.quadrant),
           ),
           
         if (widget.task.isRepeating)
           const Icon(Icons.repeat_rounded, size: 14, color: Colors.grey),
      ],
    );
  }
  
  Widget _buildMinimalTag({required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTag(ThemeData theme) {
    final now = DateTime.now();
    final dueDate = widget.task.dueDate!;
    final isOverdue = dueDate.isBefore(now) && !widget.task.isCompleted;
    final isToday = dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day;
    
    Color color = isOverdue ? Colors.red : (isToday ? Colors.orange : theme.colorScheme.secondary);
    String text = isToday ? '今天' : DateFormat('MM/dd').format(dueDate);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isOverdue ? Icons.error_outline_rounded : Icons.calendar_today_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
           text,
           style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }

  String _getQuadrantShortName(QuadrantType type) {
    switch (type) {
      case QuadrantType.importantUrgent: return '重要紧急';
      case QuadrantType.importantNotUrgent: return '重要不紧急';
      case QuadrantType.notImportantUrgent: return '紧急不重要';
      case QuadrantType.notImportantNotUrgent: return '日常';
    }
  }
}
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
import '../providers/theme_provider.dart';
import '../constants/quadrant_constants.dart';
import '../animations/animations.dart'; // 导入动画组件

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(bool)? onCompletedChanged;
  final VoidCallback? onDeleteRequested;

  const TaskItem({
    Key? key,
    required this.task,
    this.onTap,
    this.onLongPress,
    this.onCompletedChanged,
    this.onDeleteRequested,
  }) : super(key: key);

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> with SingleTickerProviderStateMixin {
  // 添加动画控制器
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final hapticService = HapticService();
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final TaskCategory? category = categoryProvider.getCategoryById(widget.task.categoryId);
    
    // 任务日期格式化
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    
    final priorityColor = PriorityRecommendationService.getPriorityColor(widget.task);
    final priorityIcon = PriorityRecommendationService.getPriorityIcon(widget.task);
    
    // Determine background color based on completion and theme
    final bool isDark = theme.brightness == Brightness.dark;
    final Color completedColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final Color defaultColor = theme.cardColor;

    return Dismissible(
      key: Key('task_${widget.task.id}'),
      background: _buildDismissibleBackground(context, Alignment.centerLeft),
      secondaryBackground: _buildDismissibleBackground(context, Alignment.centerRight),
      onDismissed: (direction) async {
        await HapticService.heavyImpact();
        widget.onDeleteRequested?.call();
      },
      child: GestureDetector(
        onTapDown: (_) {
          _animationController.forward(); // 按下时缩小
          HapticService.lightImpact();
        },
        onTapUp: (_) {
          _animationController.reverse(); // 松开时恢复
          widget.onTap?.call();
        },
        onTapCancel: () {
          _animationController.reverse(); // 取消点击时恢复
        },
        // 使用动画构建器来缩放整个卡片
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Animation duration
            decoration: BoxDecoration(
              color: widget.task.isCompleted ? completedColor.withOpacity(0.7) : defaultColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: _buildLeadingCheckbox(context),
              title: AnimatedCrossFade(
                firstChild: Text(
                  widget.task.title,
                  style: TextStyle(
                    color: widget.task.isCompleted
                        ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                secondChild: Text(
                  widget.task.title,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                crossFadeState: widget.task.isCompleted
                    ? CrossFadeState.showSecond // Show strikethrough
                    : CrossFadeState.showFirst, // Show normal text
                duration: const Duration(milliseconds: 300),
              ),
              subtitle: _buildSubtitle(context),
              trailing: _buildTrailing(context),
            ),
          ),
        ),
      ),
    );
  }
  
  // 新增：带动画的复选框
  Widget _buildLeadingCheckbox(BuildContext context) {
    return InkWell(
      onTap: () => _handleCompletionChange(!widget.task.isCompleted),
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.task.isCompleted 
              ? Theme.of(context).colorScheme.primary 
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.task.isCompleted 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: widget.task.isCompleted 
            ? Center(
                child: Icon(
                  Icons.check, 
                  size: 16, 
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ) 
            : null,
      ),
    );
  }

  // Method to handle completion toggle, now just calls provider
  void _handleCompletionChange(bool value) {
    if (widget.task.id == null) return;
    HapticService.lightImpact(); // Add haptic feedback
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // 标记为已完成时添加轻微抖动动画效果
    if (value && !widget.task.isCompleted) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          ShakeAnimation(
            offset: 3.0,
            duration: const Duration(milliseconds: 300),
            child: Container(), // 只需要触发动画即可
          );
        }
      });
    }
    
    taskProvider.toggleTaskCompletion(widget.task); // Provider updates the task
    // No need for setState here as Provider will notify and rebuild
  }

  // Helper for subtitle
  Widget? _buildSubtitle(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final TaskCategory? category = categoryProvider.getCategoryById(widget.task.categoryId);
    List<String> parts = [];
    
    if (widget.task.dueDate != null) {
      // 如果有截止日期，则添加格式化的日期
      parts.add(DateFormat('MM/dd').format(widget.task.dueDate!));
    }
    
    // 如果有分类，则添加分类名称
    if (category != null) {
      parts.add(category.name);
    }

    // 如果任务有描述，则添加描述预览（截断）
    if (widget.task.description.isNotEmpty) {
      final String truncatedDesc = widget.task.description.length > 20
          ? '${widget.task.description.substring(0, 20)}...'
          : widget.task.description;
      parts.add(truncatedDesc);
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' · '),
      style: TextStyle(
        color: widget.task.isCompleted
            ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)
            : Theme.of(context).textTheme.bodySmall?.color,
         fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Helper for trailing icons
  Widget? _buildTrailing(BuildContext context) {
    final quadrantType = QuadrantUtils.getQuadrantType(widget.task.isImportant, widget.task.isUrgent);
    final quadrantColor = QuadrantConstants.getQuadrantColor(quadrantType);
    
    // 使用动画构建器让指示器有小的脉动效果
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.task.isRepeating)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.repeat,
              size: 14,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
          ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: quadrantColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: quadrantColor.withOpacity(0.4),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    IconData icon;
    Color color;
    String tooltip;
    
    switch (priority) {
      case 1:
        icon = Icons.arrow_downward;
        color = Colors.green;
        tooltip = '低优先级';
        break;
      case 3:
        icon = Icons.arrow_upward;
        color = Colors.red;
        tooltip = '高优先级';
        break;
      case 2:
      default:
        icon = Icons.remove;
        color = Colors.orange;
        tooltip = '中优先级';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }

  Widget _buildDismissibleBackground(BuildContext context, Alignment alignment) {
    final bool isRight = alignment == Alignment.centerRight;
    
    return Container(
      decoration: BoxDecoration(
        color: isRight ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        isRight ? Icons.delete : Icons.archive,
        color: Colors.white,
      ),
    );
  }
}

// Helper utility class for Quadrant logic (could be moved)
class QuadrantUtils {
  static QuadrantType getQuadrantType(bool isImportant, bool isUrgent) {
    if (isImportant && isUrgent) return QuadrantType.importantUrgent;
    if (isImportant && !isUrgent) return QuadrantType.importantNotUrgent;
    if (!isImportant && isUrgent) return QuadrantType.notImportantUrgent;
    return QuadrantType.notImportantNotUrgent;
  }
} 
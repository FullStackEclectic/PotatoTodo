import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class SubTaskWidget extends StatefulWidget {
  final Task parentTask;
  final VoidCallback? onSubTaskChanged;

  const SubTaskWidget({
    super.key,
    required this.parentTask,
    this.onSubTaskChanged,
  });

  @override
  State<SubTaskWidget> createState() => _SubTaskWidgetState();
}

class _SubTaskWidgetState extends State<SubTaskWidget> {
  final TextEditingController _subTaskController = TextEditingController();
  bool _isAddingSubTask = false;

  @override
  void dispose() {
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final subTasks = taskProvider.getSubTasks(widget.parentTask.id!);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 子任务标题和添加按钮
            Row(
              children: [
                Icon(
                  Icons.subdirectory_arrow_right,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '子任务 (${subTasks.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (!_isAddingSubTask)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isAddingSubTask = true;
                      });
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: '添加子任务',
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // 子任务进度条
            if (subTasks.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '完成进度',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: widget.parentTask.subTaskCompletionRate,
                        backgroundColor: theme.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(widget.parentTask.subTaskCompletionRate * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 添加子任务输入框
            if (_isAddingSubTask) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _subTaskController,
                      decoration: InputDecoration(
                        hintText: '输入子任务内容...',
                        border: InputBorder.none,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      autofocus: true,
                      onSubmitted: (value) => _addSubTask(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isAddingSubTask = false;
                              _subTaskController.clear();
                            });
                          },
                          child: Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addSubTask,
                          child: Text('添加'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 子任务列表
            ...subTasks.map(
              (subTask) => _buildSubTaskItem(theme, subTask, taskProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubTaskItem(
    ThemeData theme,
    Task subTask,
    TaskProvider taskProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            subTask.isCompleted
                ? theme.colorScheme.surface.withValues(alpha: 0.5)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              subTask.isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // 完成状态复选框
          GestureDetector(
            onTap: () async {
              await taskProvider.toggleSubTaskCompletion(
                widget.parentTask.id!,
                subTask,
              );
              widget.onSubTaskChanged?.call();
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: subTask.isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color:
                      subTask.isCompleted
                          ? Colors.green
                          : theme.colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child:
                  subTask.isCompleted
                      ? Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
            ),
          ),

          const SizedBox(width: 12),

          // 子任务内容
          Expanded(
            child: Text(
              subTask.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration:
                    subTask.isCompleted ? TextDecoration.lineThrough : null,
                color:
                    subTask.isCompleted
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface,
              ),
            ),
          ),

          // 删除按钮
          IconButton(
            onPressed: () => _showDeleteConfirmDialog(subTask, taskProvider),
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            tooltip: '删除子任务',
          ),
        ],
      ),
    );
  }

  void _addSubTask() async {
    if (_subTaskController.text.trim().isEmpty) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final subTask = Task(
      title: _subTaskController.text.trim(),
      isImportant: widget.parentTask.isImportant,
      isUrgent: widget.parentTask.isUrgent,
      categoryId: widget.parentTask.categoryId,
      dueDate: widget.parentTask.dueDate,
    );

    await taskProvider.addSubTask(widget.parentTask.id!, subTask);

    setState(() {
      _isAddingSubTask = false;
      _subTaskController.clear();
    });

    widget.onSubTaskChanged?.call();
  }

  void _showDeleteConfirmDialog(Task subTask, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('删除子任务'),
            content: Text('确定要删除子任务"${subTask.title}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await taskProvider.deleteSubTask(subTask.id!);
                  widget.onSubTaskChanged?.call();
                },
                child: Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../constants/quadrant_constants.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/subtask_widget.dart';
import '../services/haptic_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;
  final QuadrantType? initialQuadrantType;

  const TaskDetailScreen({
    Key? key,
    this.task,
    this.initialQuadrantType,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isImportant = false;
  bool _isUrgent = false;
  int? _selectedCategoryId;
  DateTime? _dueDate;
  int _reminderPriority = 2;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _isImportant = widget.task?.isImportant ?? false;
    _isUrgent = widget.task?.isUrgent ?? false;
    _selectedCategoryId = widget.task?.categoryId;
    _dueDate = widget.task?.dueDate;
    _reminderPriority = widget.task?.reminderPriority ?? 2;

    // 根据初始象限类型设置重要性和紧急性
    if (widget.initialQuadrantType != null) {
      switch (widget.initialQuadrantType) {
        case QuadrantType.importantUrgent:
          _isImportant = true;
          _isUrgent = true;
          break;
        case QuadrantType.importantNotUrgent:
          _isImportant = true;
          _isUrgent = false;
          break;
        case QuadrantType.notImportantUrgent:
          _isImportant = false;
          _isUrgent = true;
          break;
        case QuadrantType.notImportantNotUrgent:
          _isImportant = false;
          _isUrgent = false;
          break;
        case null:
          break;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.task != null;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isEditing ? '编辑任务' : '新建任务'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _showDeleteDialog,
              icon: Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除任务',
            ),
          // 保存按钮移到AppBar
          TextButton(
            onPressed: _isLoading ? null : _saveTask,
            child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                )
              : Text(
                  '保存',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 任务标题 - 紧凑版
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '任务标题',
                  hintText: '输入任务标题...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入任务标题';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 重要性和紧急性 - 紧凑版
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text('重要', style: theme.textTheme.bodyMedium),
                      value: _isImportant,
                      onChanged: (value) => setState(() => _isImportant = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: Text('紧急', style: theme.textTheme.bodyMedium),
                      value: _isUrgent,
                      onChanged: (value) => setState(() => _isUrgent = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
              
              // 象限显示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: QuadrantConstants.getQuadrantColor(_getQuadrantType()).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: QuadrantConstants.getQuadrantColor(_getQuadrantType()).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category,
                      size: 14,
                      color: QuadrantConstants.getQuadrantColor(_getQuadrantType()),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      QuadrantConstants.getQuadrantName(_getQuadrantType()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: QuadrantConstants.getQuadrantColor(_getQuadrantType()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 描述 - 紧凑版
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '描述',
                  hintText: '添加任务描述...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              // 分类和日期 - 紧凑版
              Row(
                children: [
                  // 分类
                  Expanded(
                    child: Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        final categories = categoryProvider.categories;
                        return DropdownButtonFormField<int?>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: '分类',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('无分类')),
                            ...categories.map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(
                                    IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                    size: 16,
                                    color: category.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedCategoryId = value),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 提醒优先级
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _reminderPriority,
                      decoration: InputDecoration(
                        labelText: '提醒',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('低')),
                        DropdownMenuItem(value: 2, child: Text('中')),
                        DropdownMenuItem(value: 3, child: Text('高')),
                      ],
                      onChanged: (value) => setState(() => _reminderPriority = value ?? 2),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 截止日期 - 紧凑版
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '截止日期',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _dueDate == null 
                      ? '点击设置截止日期' 
                      : DateFormat('yyyy-MM-dd').format(_dueDate!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _dueDate == null 
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              
              // 子任务部分 - 只在编辑现有任务时显示
              if (isEditing && widget.task!.id != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                SubTaskWidget(
                  parentTask: widget.task!,
                  onSubTaskChanged: () {
                    setState(() {});
                  },
                ),
              ],
              
              // 底部留白
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }



  QuadrantType _getQuadrantType() {
    if (_isImportant && _isUrgent) return QuadrantType.importantUrgent;
    if (_isImportant && !_isUrgent) return QuadrantType.importantNotUrgent;
    if (!_isImportant && _isUrgent) return QuadrantType.notImportantUrgent;
    return QuadrantType.notImportantNotUrgent;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      await HapticService.lightImpact();
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isImportant: _isImportant,
        isUrgent: _isUrgent,
        categoryId: _selectedCategoryId,
        dueDate: _dueDate,
        reminderPriority: _reminderPriority,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      if (widget.task == null) {
        await taskProvider.addTask(task);
      } else {
        await taskProvider.updateTask(task);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.task == null ? '任务创建成功' : '任务更新成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务"${widget.task!.title}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              await taskProvider.deleteTask(widget.task!.id!);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('任务已删除'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 
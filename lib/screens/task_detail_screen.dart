import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../constants/quadrant_constants.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/subtask_widget.dart';
import '../services/haptic_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;
  final QuadrantType? initialQuadrantType;
  final bool isMasterDetailView;

  const TaskDetailScreen({
    Key? key,
    this.task,
    this.initialQuadrantType,
    this.isMasterDetailView = false,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isPreviewingMarkdown = false; // Toggle for markdown preview
  bool _isImportant = false;
  bool _isUrgent = false;
  int? _selectedCategoryId;
  DateTime? _dueDate;
  int _reminderPriority = 2;
  String? _repeatFrequency;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void didUpdateWidget(covariant TaskDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task?.id != oldWidget.task?.id) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _isImportant = widget.task?.isImportant ?? false;
    _isUrgent = widget.task?.isUrgent ?? false;
    _selectedCategoryId = widget.task?.categoryId;
    _dueDate = widget.task?.dueDate;
    _reminderPriority = widget.task?.reminderPriority ?? 2;
    _repeatFrequency = widget.task?.repeatFrequency;

    if (widget.task == null && widget.initialQuadrantType != null) {
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
      appBar: widget.isMasterDetailView
          ? null // No AppBar in master-detail view
          : AppBar(
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
                TextButton(
                  onPressed: _isLoading ? null : _saveTask,
                  child: _isLoading
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)))
                    : Text('保存', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
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
              // Close button for master-detail view
              if (widget.isMasterDetailView)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Provider.of<TaskProvider>(context, listen: false).setSelectedTask(null);
                    },
                  ),
                ),
              if (widget.isMasterDetailView && isEditing)
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(isEditing ? '编辑任务' : '新建任务', style: theme.textTheme.headlineSmall)
                ),

              Hero(
                tag: 'task_title_${widget.task?.id}',
                child: Material(
                  color: Colors.transparent,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '任务标题',
                      hintText: '输入任务标题...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return '请输入任务标题';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: QuadrantConstants.getQuadrantColor(_getQuadrantType()).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: QuadrantConstants.getQuadrantColor(_getQuadrantType()).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category, size: 14, color: QuadrantConstants.getQuadrantColor(_getQuadrantType())),
                    const SizedBox(width: 6),
                    Text(
                      QuadrantConstants.getQuadrantName(_getQuadrantType()),
                      style: theme.textTheme.bodySmall?.copyWith(color: QuadrantConstants.getQuadrantColor(_getQuadrantType()), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('描述', style: theme.textTheme.bodyMedium), 
                   TextButton.icon(
                     onPressed: () => setState(() => _isPreviewingMarkdown = !_isPreviewingMarkdown),
                     icon: Icon(_isPreviewingMarkdown ? Icons.edit : Icons.visibility, size: 16),
                     label: Text(_isPreviewingMarkdown ? '编辑' : '预览MD'),
                   ),
                ],
              ),
              const SizedBox(height: 4),
              _isPreviewingMarkdown 
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minHeight: 100),
                    child: MarkdownBody(
                      data: _descriptionController.text.isEmpty ? '_无内容_' : _descriptionController.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme),
                    ),
                  )
                : TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: '添加任务描述 (支持 Markdown)...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: 4,
                  ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        final categories = categoryProvider.categories;
                        return DropdownButtonFormField<int?>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: '分类',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('无分类')),
                            ...categories.map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), size: 16, color: category.color),
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
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _reminderPriority,
                      decoration: InputDecoration(
                        labelText: '提醒',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              Row(
                children: [
                   Expanded(
                     child: DropdownButtonFormField<String?>(
                       value: _repeatFrequency,
                       decoration: InputDecoration(
                         labelText: '重复',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                         prefixIcon: Icon(Icons.repeat, size: 20, color: theme.colorScheme.primary),
                       ),
                       items: const [
                         DropdownMenuItem(value: null, child: Text('不重复')),
                         DropdownMenuItem(value: 'daily', child: Text('每天')),
                         DropdownMenuItem(value: 'weekly', child: Text('每周')),
                         DropdownMenuItem(value: 'monthly', child: Text('每月')),
                       ],
                       onChanged: (value) => setState(() => _repeatFrequency = value),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '截止日期',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _dueDate == null ? '点击设置截止日期' : DateFormat('yyyy-MM-dd').format(_dueDate!),
                    style: theme.textTheme.bodyMedium?.copyWith(color: _dueDate == null ? theme.colorScheme.onSurface.withOpacity(0.6) : theme.colorScheme.onSurface),
                  ),
                ),
              ),
              if (isEditing && widget.task!.id != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                SubTaskWidget(parentTask: widget.task!, onSubTaskChanged: () => setState(() {})),
              ],
              const SizedBox(height: 20),
              if (widget.isMasterDetailView)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _saveTask,
                    child: _isLoading
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)))
                      : const Text('保存'),
                  ),
                ),
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
        repeatFrequency: _repeatFrequency,
        isRepeating: _repeatFrequency != null,
      );
      if (widget.task == null) {
        await taskProvider.addTask(task);
      } else {
        await taskProvider.updateTask(task.copyWith(subTasks: widget.task!.subTasks));
      }
      if (mounted) {
        if (!widget.isMasterDetailView) {
           Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.task == null ? '任务创建成功' : '任务更新成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务"${widget.task!.title}"吗？此操作无法撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              Navigator.pop(dialogContext); // 关闭对话框

              await taskProvider.deleteTask(widget.task!.id!);
              if (mounted) {
                if (!widget.isMasterDetailView) {
                  navigator.pop(); // 返回上一页
                }
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('任务已删除'), backgroundColor: Colors.red),
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
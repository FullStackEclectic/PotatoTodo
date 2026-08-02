import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../services/haptic_service.dart';
import '../services/priority_recommendation_service.dart';
import '../constants/quadrant_constants.dart';
import 'subtask_widget.dart';

class TaskForm extends StatefulWidget {
  final Task? task;
  final QuadrantType? initialQuadrantType;

  const TaskForm({super.key, this.task, this.initialQuadrantType});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isImportant = false;
  bool _isUrgent = false;
  int? _selectedCategoryId;
  DateTime? _dueDate;
  int _reminderPriority = 2;
  String? _repeatFrequency;
  int? _repeatInterval;
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();

    // 初始化表单控制器
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _isImportant = widget.task?.isImportant ?? false;
    _isUrgent = widget.task?.isUrgent ?? false;
    _selectedCategoryId = widget.task?.categoryId;
    _dueDate = widget.task?.dueDate;
    _reminderPriority = widget.task?.reminderPriority ?? 2;
    _repeatFrequency = widget.task?.repeatFrequency;
    _repeatInterval = widget.task?.repeatInterval;
    _isRepeating = widget.task?.isRepeating ?? false;

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
      await HapticService.lightImpact();
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = (widget.task ?? Task(title: _titleController.text)).copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        isImportant: _isImportant,
        isUrgent: _isUrgent,
        categoryId: _selectedCategoryId,
        dueDate: _dueDate,
        reminderPriority: _reminderPriority,
        repeatFrequency: _isRepeating ? _repeatFrequency : null,
        repeatInterval: _isRepeating ? _repeatInterval : null,
        isRepeating: _isRepeating,
      );

      if (widget.task == null) {
        await taskProvider.addTask(task);
      } else {
        await taskProvider.updateTask(task);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrioritySection(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入任务标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('重要'),
                    value: _isImportant,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _isImportant = value;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('紧急'),
                    value: _isUrgent,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _isUrgent = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('无分类')),
                ...categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('截止日期'),
              subtitle: Text(
                _dueDate == null
                    ? '未设置'
                    : '${_dueDate!.year}-${_dueDate!.month}-${_dueDate!.day}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('提醒优先级'),
              subtitle: Text('优先级 $_reminderPriority'),
              trailing: DropdownButton<int>(
                value: _reminderPriority,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('低')),
                  DropdownMenuItem(value: 2, child: Text('中')),
                  DropdownMenuItem(value: 3, child: Text('高')),
                ],
                onChanged: (value) {
                  setState(() {
                    _reminderPriority = value ?? 2;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('重复任务'),
              value: _isRepeating,
              onChanged: (bool value) {
                setState(() {
                  _isRepeating = value;
                });
              },
            ),
            if (_isRepeating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('重复间隔（天）：'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _repeatInterval,
                      items:
                          List.generate(7, (index) => index + 1).map((
                            int value,
                          ) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            _repeatInterval = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            // 子任务部分 - 只在编辑现有任务时显示
            if (widget.task != null && widget.task!.id != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              SubTaskWidget(
                parentTask: widget.task!,
                onSubTaskChanged: () {
                  // 子任务变化时的回调
                  setState(() {});
                },
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.task == null ? '创建任务' : '更新任务'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    if (widget.task == null) return const SizedBox.shrink();

    final priorityScore = PriorityRecommendationService.calculatePriorityScore(
      widget.task!,
    );
    final prioritySuggestion =
        PriorityRecommendationService.getPrioritySuggestion(widget.task!);
    final priorityColor = PriorityRecommendationService.getPriorityColor(
      widget.task!,
    );
    final priorityIcon = PriorityRecommendationService.getPriorityIcon(
      widget.task!,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '优先级建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(priorityIcon, color: priorityColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prioritySuggestion,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '得分: $priorityScore',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

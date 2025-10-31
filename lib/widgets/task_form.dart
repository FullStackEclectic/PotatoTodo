import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../services/haptic_service.dart';
import '../services/priority_recommendation_service.dart';
import '../constants/quadrant_constants.dart';
import 'subtask_widget.dart';

class TaskForm extends StatefulWidget {
  final Task? task;
  final QuadrantType? initialQuadrantType;

  const TaskForm({
    Key? key,
    this.task,
    this.initialQuadrantType,
  }) : super(key: key);

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
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
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
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text,
        description: _descriptionController.text,
        isImportant: _isImportant,
        isUrgent: _isUrgent,
        categoryId: _selectedCategoryId,
        dueDate: _dueDate,
        reminderPriority: _reminderPriority,
        repeatFrequency: _repeatFrequency,
        repeatInterval: _repeatInterval,
        isRepeating: _isRepeating,
      );

      if (widget.task == null) {
        taskProvider.addTask(task);
      } else {
        taskProvider.updateTask(task);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
  
  // 获取重复频率的显示文本
  String _getRepeatFrequencyText() {
    if (_repeatFrequency == null) {
      return '不重复';
    }
    
    switch (_repeatFrequency) {
      case 'daily':
        return _repeatInterval == 1 ? '每天' : '每 $_repeatInterval 天';
      case 'weekly':
        return _repeatInterval == 1 ? '每周' : '每 $_repeatInterval 周';
      case 'monthly':
        return _repeatInterval == 1 ? '每月' : '每 $_repeatInterval 个月';
      default:
        return '不重复';
    }
  }
  
  // 显示重复提醒设置对话框
  Future<void> _showRepeatSettingsDialog() async {
    String? tempFrequency = _repeatFrequency;
    int tempInterval = _repeatInterval ?? 1;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('设置重复提醒'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 重复频率选择
                const Text('重复频率', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('不重复')),
                    ButtonSegment(value: 'daily', label: Text('每天')),
                    ButtonSegment(value: 'weekly', label: Text('每周')),
                    ButtonSegment(value: 'monthly', label: Text('每月')),
                  ],
                  selected: {tempFrequency},
                  onSelectionChanged: (Set<String?> selection) {
                    setState(() {
                      tempFrequency = selection.first;
                    });
                  },
                ),
                
                // 如果选择了重复频率，显示间隔设置
                if (tempFrequency != null) ...[
                  const SizedBox(height: 16),
                  const Text('重复间隔', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: tempInterval <= 1 
                          ? null 
                          : () {
                              setState(() {
                                tempInterval = tempInterval - 1;
                              });
                            },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tempInterval.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            tempInterval = tempInterval + 1;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tempFrequency == 'daily' 
                      ? '每 $tempInterval 天重复一次' 
                      : tempFrequency == 'weekly' 
                          ? '每 $tempInterval 周重复一次' 
                          : '每 $tempInterval 个月重复一次',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  this.setState(() {
                    _repeatFrequency = tempFrequency;
                    _repeatInterval = tempInterval;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // 获取优先级显示文本
  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return '低优先级';
      case 3:
        return '高优先级';
      case 2:
      default:
        return '中优先级';
    }
  }
  
  // 获取优先级图标
  IconData _getPriorityIcon(int priority) {
    switch (priority) {
      case 1:
        return Icons.arrow_downward;
      case 3:
        return Icons.arrow_upward;
      case 2:
      default:
        return Icons.remove;
    }
  }
  
  // 获取优先级颜色
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 3:
        return Colors.red;
      case 2:
      default:
        return Colors.orange;
    }
  }
  
  // 显示优先级设置对话框
  Future<void> _showPrioritySettingsDialog() async {
    int tempPriority = _reminderPriority;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置提醒优先级'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('低优先级'),
                  subtitle: const Text('普通提醒，较低打扰'),
                  leading: Icon(Icons.arrow_downward, color: Colors.green),
                  selected: tempPriority == 1,
                  onTap: () {
                    setState(() {
                      tempPriority = 1;
                    });
                  },
                ),
                ListTile(
                  title: const Text('中优先级（默认）'),
                  subtitle: const Text('标准提醒'),
                  leading: Icon(Icons.remove, color: Colors.orange),
                  selected: tempPriority == 2,
                  onTap: () {
                    setState(() {
                      tempPriority = 2;
                    });
                  },
                ),
                ListTile(
                  title: const Text('高优先级'),
                  subtitle: const Text('重要提醒，不易被忽略'),
                  leading: Icon(Icons.arrow_upward, color: Colors.red),
                  selected: tempPriority == 3,
                  onTap: () {
                    setState(() {
                      tempPriority = 3;
                    });
                  },
                ),
              ],
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              this.setState(() {
                _reminderPriority = tempPriority;
              });
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;
    
    // 日期格式化
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    
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
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('无分类'),
                ),
                ...categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
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
              subtitle: Text(_dueDate == null ? '未设置' : '${_dueDate!.year}-${_dueDate!.month}-${_dueDate!.day}'),
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
              subtitle: Text('优先级 ${_reminderPriority}'),
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
                      items: List.generate(7, (index) => index + 1)
                          .map((int value) {
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
    
    final priorityScore = PriorityRecommendationService.calculatePriorityScore(widget.task!);
    final prioritySuggestion = PriorityRecommendationService.getPrioritySuggestion(widget.task!);
    final priorityColor = PriorityRecommendationService.getPriorityColor(widget.task!);
    final priorityIcon = PriorityRecommendationService.getPriorityIcon(widget.task!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '优先级建议',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  priorityIcon,
                  color: priorityColor,
                  size: 24,
                ),
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
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
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
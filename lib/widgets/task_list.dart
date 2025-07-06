import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_item.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task)? onTaskTap;

  const TaskList({
    Key? key,
    required this.tasks,
    this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('[TaskList] 构建任务列表，任务数量: ${tasks.length}');
    
    if (tasks.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无任务',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          debugPrint('[TaskList] 构建任务项: ${task.title}');
          return TaskItem(
            task: task,
            onTap: () {
              debugPrint('[TaskList] 点击任务: ${task.title}');
              if (onTaskTap != null) {
                onTaskTap!(task);
              } else {
                // 默认导航到任务详情页
                Navigator.pushNamed(
                  context,
                  '/task_detail',
                  arguments: task,
                );
              }
            },
          );
        },
      ),
    );
  }
} 
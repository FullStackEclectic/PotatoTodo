import 'package:flutter/material.dart';
import '../models/task.dart';
import '../constants/quadrant_constants.dart';
import '../widgets/task_form.dart';
import 'main_layout.dart';
import '../services/priority_recommendation_service.dart';
import '../animations/animations.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task? task;
  final QuadrantType? initialQuadrantType;

  const TaskDetailScreen({
    Key? key,
    this.task,
    this.initialQuadrantType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = task == null ? '新建任务' : '编辑任务';
    
    return Scaffold(
      appBar: AppBar(
        title: HeroWrapper(
          tag: 'task_title_${task?.id ?? "new"}',
          child: Text(title),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: TaskForm(
        task: task,
        initialQuadrantType: initialQuadrantType,
      ),
    );
  }
} 
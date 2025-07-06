import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../services/haptic_service.dart';
import 'dart:math' as math;
import 'pomodoro_settings_screen.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Task? _selectedTask;

  // Helper to format time (mm:ss)
  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Helper to get session name
  String _getSessionName(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.work:
        return '工作';
      case SessionType.shortBreak:
        return '短休息';
      case SessionType.longBreak:
        return '长休息';
    }
  }

  void _selectTask() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    // 获取未完成的任务列表
    final uncompletedTasks = taskProvider.tasks.where((task) => !task.isCompleted).toList();
    
    if (uncompletedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有未完成的任务')),
      );
      return;
    }
    
    await HapticService.selectionClick();
    
    // 显示任务选择对话框
    final Task? selectedTask = await showDialog<Task>(
      context: context,
      builder: (context) => TaskSelectionDialog(tasks: uncompletedTasks),
    );
    
    if (selectedTask != null) {
      setState(() {
        _selectedTask = selectedTask;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoro, child) {
        try {
          final state = pomodoro.currentState;
          final session = pomodoro.currentSession;
          final remainingTime = pomodoro.remainingTime;
          final totalDuration = pomodoro.totalDuration;
          final progress = totalDuration > 0 ? (totalDuration - remainingTime) / totalDuration : 0.0;

          // 计算当前会话的颜色
          Color sessionColor;
          switch (session) {
            case SessionType.work:
              sessionColor = theme.colorScheme.primary;
              break;
            case SessionType.shortBreak:
              sessionColor = theme.colorScheme.secondary;
              break;
            case SessionType.longBreak:
              sessionColor = Colors.teal;
              break;
          }

          return Column(
            children: [
              // 顶部操作栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 设置按钮
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: '番茄钟设置',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PomodoroSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    
                    // 会话类型指示器
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sessionColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getSessionName(session),
                        style: TextStyle(
                          color: sessionColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // 任务选择按钮
                    IconButton(
                      icon: const Icon(Icons.task_alt),
                      tooltip: '选择任务',
                      onPressed: session == SessionType.work ? _selectTask : null,
                    ),
                  ],
                ),
              ),
              
              // 当前选择的任务
              if (_selectedTask != null && session == SessionType.work)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '当前任务',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              _selectedTask!.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedTask = null;
                          });
                        },
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Timer Circle
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(sessionColor),
                            ),
                            Center(
                              child: Text(
                                _formatTime(remainingTime),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reset Button (visible when paused or stopped)
                          if (state != PomodoroState.running)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              iconSize: 40,
                              tooltip: '重置',
                              onPressed: () async {
                                await HapticService.mediumImpact();
                                pomodoro.resetTimer();
                              },
                            ),
                          const SizedBox(width: 30),

                          // Start/Pause Button
                          FloatingActionButton.large(
                            onPressed: () async {
                              await HapticService.selectionClick();
                              pomodoro.startPauseTimer();
                            },
                            child: Icon(
                              state == PomodoroState.running ? Icons.pause : Icons.play_arrow,
                              size: 50,
                            ),
                            backgroundColor: sessionColor,
                          ),
                          const SizedBox(width: 30),

                          // Skip Button (visible when paused or stopped)
                           if (state != PomodoroState.running)
                             IconButton(
                               icon: const Icon(Icons.skip_next),
                               iconSize: 40,
                               tooltip: '跳过',
                               onPressed: () async {
                                 await HapticService.mediumImpact();
                                 pomodoro.skipSession();
                               },
                             ),
                           // Placeholder for alignment if skip is not visible
                           if (state == PomodoroState.running)
                             const SizedBox(width: 70), // Match IconButton size + padding approx.
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Pomodoro Count
                      Text(
                        '已完成: ${pomodoro.currentPomodoroCount}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } catch (e) {
          // 如果有任何渲染错误，显示一个简单的错误信息
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('无法加载专注页面: $e', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<PomodoroProvider>(context, listen: false).resetTimer();
                  },
                  child: const Text('尝试重置'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// 任务选择对话框
class TaskSelectionDialog extends StatelessWidget {
  final List<Task> tasks;

  const TaskSelectionDialog({
    Key? key,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '选择一个任务',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: task.description.isNotEmpty
                        ? Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    leading: Icon(
                      task.isImportant && task.isUrgent
                          ? Icons.priority_high
                          : task.isImportant
                              ? Icons.star
                              : task.isUrgent
                                  ? Icons.speed
                                  : Icons.check_box_outline_blank,
                      color: task.isImportant && task.isUrgent
                          ? Colors.red
                          : task.isImportant
                              ? Colors.orange
                              : task.isUrgent
                                  ? Colors.blue
                                  : null,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(task);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
} 
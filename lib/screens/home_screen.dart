import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/date_range_filter.dart';
import '../animations/animations.dart';
import 'task_detail_screen.dart';
import 'category_list_screen.dart';
import 'quadrant_view_screen.dart';
import 'quadrant_stats_screen.dart';
import 'time_stats_screen.dart';
import 'category_stats_screen.dart';
import '../utils/responsive_util.dart';
import 'main_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Task> _previousTasks = [];
  late AnimationController _addButtonController; // 添加按钮的动画控制器

  @override
  void initState() {
    super.initState();
    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // 在组件挂载后执行动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _addButtonController.forward();
      }
    });
  }

  @override
  void dispose() {
    _addButtonController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.setSelectedCategory(null);
    taskProvider.setSelectedQuadrant(null);
    taskProvider.setSearchQuery(null);
    _previousTasks = List.from(taskProvider.tasks);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FadeInWidget(
        delay: const Duration(milliseconds: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideInUpWidget(
              delay: const Duration(milliseconds: 400),
              child: Icon(
                Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            SlideInUpWidget(
              delay: const Duration(milliseconds: 500),
              child: Text(
                '暂无任务',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SlideInUpWidget(
              delay: const Duration(milliseconds: 600),
              child: Text(
                '点击右下角的 + 按钮添加新任务',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final currentTasks = taskProvider.tasks;
        
        if (currentTasks.isEmpty) {
          return _buildEmptyState(context);
        }

        // 使用AnimationLimiter来创建交错动画
        return AnimationLimiter(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(8.0),
            itemCount: currentTasks.length,
            itemBuilder: (context, index) {
              final task = currentTasks[index];
              
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: TaskItem(
                      task: task,
                      onTap: () async {
                        // 使用自定义动画路由
                        await Navigator.push(
                          context,
                          SlidePageRoute(
                            page: TaskDetailScreen(task: task),
                            direction: SlideDirection.right,
                          ),
                        );
                      },
                      onDeleteRequested: () {
                        if (task.id == null) return;
                        // 添加删除动画
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已删除: ${task.title}'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: '撤销',
                              onPressed: () {
                                // 恢复任务
                                taskProvider.addTask(task);
                              },
                            ),
                          ),
                        );
                        taskProvider.deleteTask(task.id!);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 
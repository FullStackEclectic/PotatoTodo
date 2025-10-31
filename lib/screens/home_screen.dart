import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/task_header_widget.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const HomeScreen({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchTextController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          // 搜索栏
          if (_isSearchExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchTextController,
                decoration: InputDecoration(
                  hintText: '搜索任务...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchTextController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchTextController.clear();
                            taskProvider.setSearchQuery(null);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  taskProvider.setSearchQuery(value.isEmpty ? null : value);
                },
              ),
            ),
          
          // 优雅的头部组件
          TaskHeaderWidget(
            scaffoldKey: widget.scaffoldKey,
            onFilterChanged: () {
              // 分类筛选变化时，只需要刷新界面，不需要切换搜索框
              setState(() {});
            },
            onSearchToggle: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchTextController.clear();
                  taskProvider.setSearchQuery(null);
                }
              });
            },
            onDateFilter: () {
              // TODO: 实现日期筛选
            },
            onStatusFilter: () {
              // TODO: 实现状态筛选
            },
          ),
          
          // 任务列表
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskItem(
                        task: task,
                        onTap: () => _openTaskDetail(task),
                        onCompletedChanged: (completed) {
                          taskProvider.toggleTaskCompletion(task);
                        },
                        onDeleteRequested: () {
                          if (task.id != null) {
                            taskProvider.deleteTask(task.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '暂无任务',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的+按钮添加新任务',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
  }
} 
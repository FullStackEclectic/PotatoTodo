import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/task_header_widget.dart';
import 'task_detail_screen.dart';
import '../utils/platform_util.dart';
import '../utils/slide_in_page_route.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool isMasterDetail;

  const HomeScreen({super.key, this.scaffoldKey, this.isMasterDetail = false});

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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimationLimiter(
        child: CustomScrollView(
          slivers: [
            // 1. Sliver App Bar
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              floating: true,
              pinned: false,
              snap: true,
              centerTitle: false,
              title: Text(
                '土豆 Todo',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                onPressed: () {
                  if (widget.scaffoldKey?.currentState != null) {
                    widget.scaffoldKey!.currentState!.openDrawer();
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearchExpanded ? Icons.close : Icons.search,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) {
                        _searchTextController.clear();
                        taskProvider.setSearchQuery(null);
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom:
                  _isSearchExpanded
                      ? PreferredSize(
                        preferredSize: const Size.fromHeight(60),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextField(
                            controller: _searchTextController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '搜索任务 (支持"重要", "今天")...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                            ),
                            onChanged:
                                (value) => taskProvider.setSearchQuery(
                                  value.isEmpty ? null : value,
                                ),
                          ),
                        ),
                      )
                      : null,
            ),

            // 2. Stats Card (Scrollable)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const TaskStatsCard(),
              ),
            ),

            // 3. Sticky Filters
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverFilterHeaderDelegate(
                child: Container(
                  color:
                      theme
                          .scaffoldBackgroundColor, // Opaque background for sticky effect
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TaskFilterBar(onFilterChanged: () => setState(() {})),
                ),
                height: 56, // Estimate height
              ),
            ),

            // 4. Task List
            tasks.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState(theme))
                : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final task = tasks[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset:
                            20.0, // Reduced offset for subtler animation
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ), // Add horizontal breathing room for the list
                            child: TaskItem(
                              task: task,
                              onTap: () => _openTaskDetail(context, task),
                              onCompletedChanged: (completed) {
                                taskProvider.toggleTaskCompletion(task);
                              },
                              onDeleteRequested: () {
                                if (task.id != null) {
                                  taskProvider.deleteTask(task.id!);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: tasks.length),
                ),

            const SliverPadding(
              padding: EdgeInsets.only(bottom: 100),
            ), // More bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded, // Cleaner icon
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '没有任务',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '太棒了！或者... 点击 "+" 来点新挑战？',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskDetail(BuildContext context, Task task) {
    if (widget.isMasterDetail) {
      // In master-detail view, just select the task (provider update will refresh detail view)
      Provider.of<TaskProvider>(context, listen: false).setSelectedTask(task);
    } else if (PlatformUtil.isDesktop) {
      Navigator.push(
        context,
        SlideInPageRoute(page: TaskDetailScreen(task: task)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      );
    }
  }
}

class _SliverFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverFilterHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverFilterHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

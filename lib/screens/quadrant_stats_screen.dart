import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/quadrant_constants.dart';
import '../providers/task_provider.dart';
import '../widgets/quadrant_stat_card.dart';
import '../widgets/quadrant_distribution_chart.dart';
import '../widgets/quadrant_completion_chart.dart';
import 'quadrant_view_screen.dart';
import '../models/quadrant_stats.dart';
import '../models/quadrant_type.dart';
import '../animations/animations.dart';  // 导入动画组件

class QuadrantStatsScreen extends StatefulWidget {
  final bool showAppBar;

  const QuadrantStatsScreen({
    Key? key,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  _QuadrantStatsScreenState createState() => _QuadrantStatsScreenState();
}

class _QuadrantStatsScreenState extends State<QuadrantStatsScreen> {
  late final List<QuadrantType> quadrants = [
    QuadrantType.importantUrgent,
    QuadrantType.importantNotUrgent,
    QuadrantType.notImportantUrgent,
    QuadrantType.notImportantNotUrgent,
  ];

  late final QuadrantStats stats = QuadrantStats(
    totalTasks: Provider.of<TaskProvider>(context, listen: false).tasks.length,
    importantUrgent: Provider.of<TaskProvider>(context, listen: false)
        .countTasksByQuadrant(QuadrantType.importantUrgent),
    importantNotUrgent: Provider.of<TaskProvider>(context, listen: false)
        .countTasksByQuadrant(QuadrantType.importantNotUrgent),
    notImportantUrgent: Provider.of<TaskProvider>(context, listen: false)
        .countTasksByQuadrant(QuadrantType.notImportantUrgent),
    notImportantNotUrgent: Provider.of<TaskProvider>(context, listen: false)
        .countTasksByQuadrant(QuadrantType.notImportantNotUrgent),
  );

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    final tasks = taskProvider.allTasks;

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      appBar: widget.showAppBar 
        ? AppBar(
            title: const Text('四象限分析'),
            elevation: 0,
            centerTitle: true,
          ) 
        : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总体统计卡片 - 现代化设计，添加滑入动画
            SlideInUpWidget(
              delay: const Duration(milliseconds: 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '任务概览',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '完成率: $completionRate%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItemModern(
                          context,
                          '总任务数',
                          totalTasks.toString(),
                          Icons.task_alt,
                          theme.colorScheme.onPrimary,
                        ),
                        _buildStatItemModern(
                          context,
                          '已完成',
                          completedTasks.toString(),
                          Icons.check_circle_outline,
                          theme.colorScheme.onPrimary,
                        ),
                        _buildStatItemModern(
                          context,
                          '待完成',
                          (totalTasks - completedTasks).toString(),
                          Icons.pending_actions,
                          theme.colorScheme.onPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalTasks > 0 ? completedTasks / totalTasks : 0,
                        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 标题：任务分布
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  '任务分布',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ),

            // 任务分布图表 - 带卡片效果和动画
            SlideInUpWidget(
              delay: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: QuadrantDistributionChart(stats: stats, size: 200),
              ),
            ),

            const SizedBox(height: 24),
            
            // 标题：四象限详情
            FadeInWidget(
              delay: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  '四象限详情',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ),

            // 四象限统计卡片 - 改进布局
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(quadrants.length, (index) {
                final quadrant = quadrants[index];
                final tasks = taskProvider.getTasksByQuadrant(quadrant);
                
                // 使用StaggeredAnimationBuilder实现卡片的交错动画
                return StaggeredAnimationBuilder(
                  position: index,
                  itemCount: quadrants.length,
                  builder: (context, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: _buildQuadrantCard(
                          context,
                          quadrant,
                          tasks.length,
                          totalTasks,
                          () {
                            Navigator.push(
                              context,
                              SlidePageRoute(
                                page: QuadrantViewScreen(initialQuadrant: quadrant),
                                direction: SlideDirection.right,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // 标题：完成率对比
            FadeInWidget(
              delay: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  '完成率对比',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ),

            // 完成率对比图表 - 带卡片效果和动画
            SlideInUpWidget(
              delay: const Duration(milliseconds: 700),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: const QuadrantCompletionChart(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 标题：任务管理建议
            FadeInWidget(
              delay: const Duration(milliseconds: 800),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  '时间管理矩阵建议',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ),

            // 任务管理建议卡片 - 现代化设计
            SlideInUpWidget(
              delay: const Duration(milliseconds: 900),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSuggestionItemModern(
                      context,
                      '重要且紧急',
                      '这些任务需要立即处理，建议优先完成。',
                      Icons.priority_high,
                      Colors.red,
                    ),
                    const Divider(height: 24),
                    _buildSuggestionItemModern(
                      context,
                      '重要不紧急',
                      '这些任务很重要但不紧急，建议合理规划时间处理。',
                      Icons.event,
                      Colors.blue,
                    ),
                    const Divider(height: 24),
                    _buildSuggestionItemModern(
                      context,
                      '紧急不重要',
                      '这些任务虽然紧急但不重要，可以考虑委托他人处理。',
                      Icons.person_outline,
                      Colors.orange,
                    ),
                    const Divider(height: 24),
                    _buildSuggestionItemModern(
                      context,
                      '不紧急不重要',
                      '这些任务可以放在最后处理，甚至可以考虑删除。',
                      Icons.low_priority,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemModern(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        // 添加脉冲动画效果
        PulseAnimation(
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrantCard(
    BuildContext context,
    QuadrantType quadrant,
    int count,
    int totalCount,
    VoidCallback onTap,
  ) {
    final quadrantColor = QuadrantConstants.getQuadrantColor(quadrant);
    final quadrantName = QuadrantConstants.getQuadrantName(quadrant);
    final quadrantIcon = QuadrantConstants.getQuadrantIcon(quadrant);
    final percentage = totalCount > 0 ? (count / totalCount * 100).toStringAsFixed(1) : '0.0';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: quadrantColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: quadrantColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: quadrantColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                quadrantIcon,
                size: 28,
                color: quadrantColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              quadrantName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '$count 个任务',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: quadrantColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: quadrantColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItemModern(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 
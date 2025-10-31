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
            // 总体统计卡片
            Container(
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
                      Icon(
                        Icons.analytics,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOverviewItem(
                          theme,
                          '总任务',
                          totalTasks.toString(),
                          Icons.task,
                        ),
                      ),
                      Expanded(
                        child: _buildOverviewItem(
                          theme,
                          '已完成',
                          completedTasks.toString(),
                          Icons.check_circle,
                        ),
                      ),
                      Expanded(
                        child: _buildOverviewItem(
                          theme,
                          '完成率',
                          '$completionRate%',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 四象限统计卡片
            Text(
              '四象限分布',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: quadrants.length,
              itemBuilder: (context, index) {
                final quadrant = quadrants[index];
                final count = taskProvider.countTasksByQuadrant(quadrant);
                final totalCount = taskProvider.allTasks.length;
                return QuadrantStatCard(
                  quadrantType: quadrant,
                  count: count,
                  totalCount: totalCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuadrantViewScreen(
                          initialQuadrant: quadrant,
                          showAsGrid: false,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // 图表区域
            Text(
              '详细分析',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 任务分布饼图
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '任务分布',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: QuadrantDistributionChart(stats: stats),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 完成率柱状图
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '完成率对比',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: QuadrantCompletionChart(),
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

  Widget _buildOverviewItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
} 
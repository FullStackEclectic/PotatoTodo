import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/page_header_widget.dart';
import '../widgets/stats_widgets.dart';
import '../themes/app_theme.dart';
import '../utils/animations.dart';
import '../constants/quadrant_constants.dart';
import '../models/task.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedPeriodIndex = 0; // 0: Week, 1: Month

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final tasks = taskProvider.allTasks;
          final completedTasks = tasks.where((t) => t.isCompleted).toList();

          final completedCount = completedTasks.length;
          final totalCount = tasks.length;
          final completionRate =
              totalCount == 0
                  ? 0
                  : ((completedCount / totalCount) * 100).toInt();

          // Real Data Calculation
          final weeklyData = _calculateWeeklyActivity(completedTasks);
          final quadrantData = _calculateQuadrantDistribution(
            tasks,
          ); // All tasks or completed? Let's show All to see load distribution.

          // Find most productive day
          final bestDayIndex = weeklyData.indexWhere(
            (e) =>
                e ==
                weeklyData.reduce((curr, next) => curr > next ? curr : next),
          );
          final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
          final bestDay =
              weeklyData.reduce((a, b) => a + b) > 0
                  ? days[bestDayIndex]
                  : '无数据';

          return Column(
            children: [
              PageHeaderWidget(
                title: '统计数据',
                subtitle: '追踪你的工作效率',
                leading: Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.primary,
                ),
                actions: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        _buildPeriodBtn(0, '本周', theme),
                        /*_buildPeriodBtn(1, '本月', theme),*/
                        // Disable month for now as chart is hardcoded for 7 days
                      ],
                    ),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Animations.animatedColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Summary Cards Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatsWidgets.buildInsightCard(
                                context,
                                title: '完成率',
                                value: '$completionRate%',
                                subtitle: '总体进度',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatsWidgets.buildInsightCard(
                                context,
                                title: '最佳工作日',
                                value:
                                    bestDay, // Removed .substring(0, 3) to prevent RangeError crash on Chinese weekday strings
                                subtitle:
                                    bestDay == 'N/A' || bestDay == '无数据'
                                        ? '无数据'
                                        : '效率最高',
                                icon: Icons.bolt_rounded,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Activity Chart
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '每周活动',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '每日完成任务数',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              StatsWidgets.buildActivityTrendChart(
                                context,
                                weeklyData,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Quadrant Distribution (New!)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '象限分布',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '任务在四象限中的分布情况',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatsWidgets.buildQuadrantPieChart(
                                      context,
                                      quadrantData,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        QuadrantType.values.map((q) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        QuadrantConstants.getQuadrantColor(
                                                          q,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  QuadrantConstants.getQuadrantName(
                                                    q,
                                                  ), // Shorten if too long?
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Calculate completed tasks for the last 7 days (Mon-Sun based on current week or rolling? Let's do Mon-Sun relative to now)
  // Actually, standard is usually "This Week" (Mon-Today) or "Last 7 Days".
  // Let's do "Current Week" (Mon -> Sun).
  List<int> _calculateWeeklyActivity(List<Task> completedTasks) {
    final now = DateTime.now();
    // Find Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    List<int> data = List.filled(7, 0);

    for (var task in completedTasks) {
      final dateRef = task.completedAt;
      if (dateRef == null) continue;
      if (dateRef.isAfter(startOfWeek) ||
          dateRef.isAtSameMomentAs(startOfWeek)) {
        final dayIndex = dateRef.weekday - 1; // Mon=1 -> 0
        if (dayIndex >= 0 && dayIndex < 7) {
          data[dayIndex]++;
        }
      }
    }
    return data;
  }

  Map<QuadrantType, int> _calculateQuadrantDistribution(List<Task> tasks) {
    Map<QuadrantType, int> data = {
      QuadrantType.importantUrgent: 0,
      QuadrantType.importantNotUrgent: 0,
      QuadrantType.notImportantUrgent: 0,
      QuadrantType.notImportantNotUrgent: 0,
    };

    for (var task in tasks) {
      if (!task.isCompleted) {
        // Focus on pending load? Or all? User usually wants to know "What do I have to do?" -> Pending.
        data[task.quadrant] = (data[task.quadrant] ?? 0) + 1;
      }
    }
    return data;
  }

  Widget _buildPeriodBtn(int index, String label, ThemeData theme) {
    final isSelected = _selectedPeriodIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriodIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color:
                isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

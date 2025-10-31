import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/page_header_widget.dart';
import '../widgets/quadrant_stat_card.dart';
import '../widgets/quadrant_distribution_chart.dart';
import '../constants/quadrant_constants.dart';
import '../models/task.dart';
import '../models/category.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

enum StatsPeriod { week, month, quarter, year }

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsPeriod _selectedPeriod = StatsPeriod.month;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // 现代头部组件
          PageHeaderWidget(
            title: '数据统计',
            subtitle: _getPeriodSubtitle(),
            leading: Icon(
              Icons.analytics,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            actions: [
              // 时间段选择
              PopupMenuButton<StatsPeriod>(
                icon: Icon(
                  Icons.date_range,
                  size: 20,
                ),
                tooltip: '选择时间段',
                onSelected: (StatsPeriod period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: StatsPeriod.week,
                    child: Row(
                      children: [
                        Icon(Icons.view_week, size: 16),
                        const SizedBox(width: 8),
                        Text('本周'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: StatsPeriod.month,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_month, size: 16),
                        const SizedBox(width: 8),
                        Text('本月'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: StatsPeriod.quarter,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('本季度'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: StatsPeriod.year,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('本年'),
                      ],
                    ),
                  ),
                ],
              ),
              // 导出报告按钮
              IconButton(
                onPressed: () => _showExportDialog(context),
                icon: const Icon(Icons.file_download),
                tooltip: '导出报告',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          
          // 统计内容
          Expanded(
            child: _buildStatisticsContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总体统计卡片 - 更紧凑的设计
          _buildCompactOverallStats(theme),
          
          const SizedBox(height: 16),
          
          // 时间范围选择器
          _buildTimeRangeSelector(theme),
          
          const SizedBox(height: 16),
          
          // 四象限和分类统计 - 并排显示
          _buildStatsRow(theme),
          
          const SizedBox(height: 16),
          
          // 效率分析
          _buildEfficiencyAnalysis(theme),
          
          const SizedBox(height: 16),
          
          // 详细分析区域
          _buildDetailedAnalysis(theme),
          
          const SizedBox(height: 16),
          
          // 趋势分析
          _buildTrendAnalysis(theme),
          
          const SizedBox(height: 16),
          
          // 建议和洞察
          _buildInsightsAndSuggestions(theme),
        ],
      ),
    );
  }

  Widget _buildCompactOverallStats(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.allTasks;
        final totalTasks = tasks.length;
        final completedTasks = tasks.where((task) => task.isCompleted).length;
        final pendingTasks = totalTasks - completedTasks;
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 主要指标
              Row(
                children: [
                  // 总任务数 - 大数字显示
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalTasks.toString(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '总任务',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 完成率圆环
                  Expanded(
                    flex: 1,
                    child: _buildCircularProgress(theme, completionRate),
                  ),
                  
                  // 详细数据
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildCompactStatItem(theme, '已完成', completedTasks, Colors.green),
                        const SizedBox(height: 8),
                        _buildCompactStatItem(theme, '待完成', pendingTasks, Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildCircularProgress(ThemeData theme, double percentage) {
    return Center(
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 6,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(ThemeData theme, String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          value.toString(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        // 四象限统计
        Expanded(
          child: _buildQuadrantStatsCompact(theme),
        ),
        const SizedBox(width: 12),
        // 分类统计
        Expanded(
          child: _buildCategoryStatsCompact(theme),
        ),
      ],
    );
  }

  Widget _buildQuadrantStatsCompact(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.grid_view,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '四象限',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...QuadrantType.values.map((quadrant) {
                final count = taskProvider.getCountByQuadrant(quadrant);
                final color = QuadrantConstants.getQuadrantColor(quadrant);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          QuadrantConstants.getQuadrantName(quadrant),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        count.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryStatsCompact(ThemeData theme) {
    return Consumer2<TaskProvider, CategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        // 按层级分组
        final topLevelCategories = categoryProvider.topLevelCategories.take(3).toList(); // 只显示前3个顶级分类
        final subCategories = <TaskCategory>[];
        
        // 获取顶级分类的子分类
        for (final topCategory in topLevelCategories) {
          final subs = categoryProvider.getSubCategories(topCategory.id!).take(2).toList(); // 每个顶级分类最多显示2个子分类
          subCategories.addAll(subs);
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '分类',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topLevelCategories.isEmpty)
                Text(
                  '暂无分类',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                )
              else ...[
                // 顶级分类
                ...topLevelCategories.map((category) {
                  final categoryTasks = taskProvider.getTasksByCategory(category.id!);
                  final count = categoryTasks.length;
                  return _buildCompactCategoryItem(category, count, theme, indentLevel: 0);
                }).toList(),
                
                // 子分类
                if (subCategories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...subCategories.map((category) {
                    final categoryTasks = taskProvider.getTasksByCategory(category.id!);
                    final count = categoryTasks.length;
                    return _buildCompactCategoryItem(category, count, theme, indentLevel: 1);
                  }).toList(),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactCategoryItem(TaskCategory category, int count, ThemeData theme, {int indentLevel = 0}) {
    final isSubCategory = indentLevel > 0;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: indentLevel * 12, // 根据层级增加缩进
      ),
      child: Row(
        children: [
          // 层级指示器
          if (isSubCategory)
            Container(
              width: 1.5,
              height: 12,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(0.75),
              ),
            ),
          
          Icon(
            IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
            size: isSubCategory ? 10 : 12,
            color: category.color.withOpacity(isSubCategory ? 0.7 : 1.0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isSubCategory ? 10 : 11,
                color: theme.colorScheme.onSurface.withOpacity(isSubCategory ? 0.7 : 1.0),
                fontWeight: isSubCategory ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
          if (isSubCategory)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '子',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  color: category.color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: category.color.withOpacity(isSubCategory ? 0.7 : 1.0),
              fontSize: isSubCategory ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis(ThemeData theme) {
    return Consumer2<TaskProvider, CategoryProvider>(
      builder: (context, taskProvider, categoryProvider, child) {
        final categories = categoryProvider.categories;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '详细分析',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 分类完成率列表 - 按层级显示
              if (categories.isNotEmpty)
                ..._buildHierarchicalCategoryList(categories, taskProvider, theme)
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无分类数据',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 构建层级化的分类列表
  List<Widget> _buildHierarchicalCategoryList(
    List<TaskCategory> categories, 
    TaskProvider taskProvider, 
    ThemeData theme
  ) {
    List<Widget> widgets = [];
    
    // 按层级分组
    final topLevelCategories = categories.where((cat) => cat.level == 0).toList();
    
    for (final topCategory in topLevelCategories) {
      // 添加顶级分类
      widgets.add(_buildCategoryItem(topCategory, taskProvider, theme, indentLevel: 0));
      
      // 添加子分类
      final subCategories = categories.where((cat) => cat.parentId == topCategory.id).toList();
      for (final subCategory in subCategories) {
        widgets.add(_buildCategoryItem(subCategory, taskProvider, theme, indentLevel: 1));
      }
    }
    
    return widgets;
  }

  // 构建单个分类项
  Widget _buildCategoryItem(
    TaskCategory category, 
    TaskProvider taskProvider, 
    ThemeData theme, 
    {int indentLevel = 0}
  ) {
    final categoryTasks = taskProvider.getTasksByCategory(category.id!);
    final completedTasks = categoryTasks.where((task) => task.isCompleted).length;
    final totalTasks = categoryTasks.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;
    
    // 根据层级调整样式
    final isSubCategory = indentLevel > 0;
    final fontSize = isSubCategory ? 13.0 : 14.0;
    final iconSize = isSubCategory ? 14.0 : 16.0;
    final opacity = isSubCategory ? 0.8 : 1.0;
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: indentLevel * 16, // 根据层级增加缩进
      ),
      padding: EdgeInsets.all(isSubCategory ? 10 : 12),
      decoration: BoxDecoration(
        color: category.color.withOpacity(isSubCategory ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: category.color.withOpacity(isSubCategory ? 0.15 : 0.2),
          width: isSubCategory ? 0.3 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // 层级指示器
          if (isSubCategory)
            Container(
              width: 2,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          
          Icon(
            IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: category.color.withOpacity(opacity),
            size: iconSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSubCategory ? FontWeight.w500 : FontWeight.w600,
                          fontSize: fontSize,
                          color: theme.colorScheme.onSurface.withOpacity(opacity),
                        ),
                      ),
                    ),
                    if (isSubCategory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '子分类',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: category.color.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: isSubCategory ? 3 : 4,
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completionRate / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(opacity),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${completionRate.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: category.color.withOpacity(opacity),
                        fontSize: isSubCategory ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$completedTasks/$totalTasks',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(isSubCategory ? 0.6 : 0.7),
              fontSize: isSubCategory ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodSubtitle() {
    switch (_selectedPeriod) {
      case StatsPeriod.week:
        return '本周任务分析';
      case StatsPeriod.month:
        return '本月任务分析';
      case StatsPeriod.quarter:
        return '本季度任务分析';
      case StatsPeriod.year:
        return '本年任务分析';
    }
  }

  List<Task> _getTasksForPeriod(List<Task> allTasks) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case StatsPeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case StatsPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case StatsPeriod.quarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterStart, 1);
        endDate = DateTime(now.year, quarterStart + 3, 0);
        break;
      case StatsPeriod.year:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
    }

    return allTasks.where((task) {
      if (task.createdAt.isAfter(endDate) || task.createdAt.isBefore(startDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildProductivityInsights(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final periodTasks = _getTasksForPeriod(taskProvider.allTasks);
        final completedTasks = periodTasks.where((task) => task.isCompleted).length;
        final totalTasks = periodTasks.length;
        
        // 计算生产力指标
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;
        final avgTasksPerDay = _getAverageTasksPerDay(periodTasks);
        final mostProductiveDay = _getMostProductiveDay(periodTasks);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '生产力洞察',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      theme,
                      '完成率',
                      '${completionRate.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      _getCompletionRateColor(completionRate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      theme,
                      '日均任务',
                      avgTasksPerDay.toStringAsFixed(1),
                      Icons.today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      theme,
                      '最佳日期',
                      mostProductiveDay,
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  double _getAverageTasksPerDay(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    
    final days = switch (_selectedPeriod) {
      StatsPeriod.week => 7,
      StatsPeriod.month => DateTime.now().day,
      StatsPeriod.quarter => DateTime.now().difference(DateTime(DateTime.now().year, ((DateTime.now().month - 1) ~/ 3) * 3 + 1, 1)).inDays + 1,
      StatsPeriod.year => DateTime.now().dayOfYear,
    };
    
    return tasks.length / days;
  }

  String _getMostProductiveDay(List<Task> tasks) {
    if (tasks.isEmpty) return '无';
    
    final Map<int, int> dayCount = {};
    for (final task in tasks.where((t) => t.isCompleted)) {
      final weekday = task.createdAt.weekday;
      dayCount[weekday] = (dayCount[weekday] ?? 0) + 1;
    }
    
    if (dayCount.isEmpty) return '无';
    
    final mostProductiveWeekday = dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[mostProductiveWeekday];
  }

  Widget _buildTrendAnalysis(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final periodTasks = _getTasksForPeriod(taskProvider.allTasks);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '趋势分析',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 简化的趋势图表
              Container(
                height: 120,
                child: _buildSimpleTrendChart(theme, periodTasks),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '时间范围',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 时间段快捷选择
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StatsPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getPeriodName(period),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected 
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyAnalysis(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final periodTasks = _getTasksForPeriod(taskProvider.allTasks);
        final completedTasks = periodTasks.where((task) => task.isCompleted).length;
        final totalTasks = periodTasks.length;
        
        // 计算效率指标
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;
        final avgTasksPerDay = _getAverageTasksPerDay(periodTasks);
        final mostProductiveDay = _getMostProductiveDay(periodTasks);
        final focusScore = _calculateFocusScore(periodTasks);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '效率分析',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 效率指标网格
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildEfficiencyMetric(
                    theme,
                    '完成率',
                    '${completionRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    _getCompletionRateColor(completionRate),
                    '目标: 80%+',
                  ),
                  _buildEfficiencyMetric(
                    theme,
                    '日均任务',
                    avgTasksPerDay.toStringAsFixed(1),
                    Icons.today,
                    Colors.blue,
                    '保持稳定',
                  ),
                  _buildEfficiencyMetric(
                    theme,
                    '专注度',
                    '${focusScore.toStringAsFixed(0)}分',
                    Icons.center_focus_strong,
                    _getFocusScoreColor(focusScore),
                    '重要任务占比',
                  ),
                  _buildEfficiencyMetric(
                    theme,
                    '最佳日期',
                    mostProductiveDay,
                    Icons.star,
                    Colors.amber,
                    '高效时段',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEfficiencyMetric(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsAndSuggestions(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final insights = _generateInsights(taskProvider);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '智能洞察',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (insights.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 32,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '继续使用应用，我们将为您提供个性化建议',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...insights.map((insight) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: insight.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        insight.icon,
                        color: insight.color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: insight.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              insight.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleTrendChart(ThemeData theme, List<Task> tasks) {
    // 按日期分组任务
    final Map<String, int> dailyCompletions = {};
    final now = DateTime.now();
    
    // 获取最近7天的数据
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      final completedCount = tasks.where((task) => 
        task.isCompleted && 
        task.createdAt.year == date.year &&
        task.createdAt.month == date.month &&
        task.createdAt.day == date.day
      ).length;
      dailyCompletions[dateKey] = completedCount;
    }
    
    final maxValue = dailyCompletions.values.isEmpty ? 1 : dailyCompletions.values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailyCompletions.entries.map((entry) {
        final height = maxValue > 0 ? (entry.value / maxValue * 80) : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              entry.value.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: height + 10, // 最小高度
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.key,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 辅助方法
  String _getPeriodName(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return '本周';
      case StatsPeriod.month:
        return '本月';
      case StatsPeriod.quarter:
        return '本季度';
      case StatsPeriod.year:
        return '本年';
    }
  }

  double _calculateFocusScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    
    final importantTasks = tasks.where((task) => task.isImportant).length;
    return (importantTasks / tasks.length * 100);
  }

  Color _getFocusScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  List<InsightItem> _generateInsights(TaskProvider taskProvider) {
    final insights = <InsightItem>[];
    final periodTasks = _getTasksForPeriod(taskProvider.allTasks);
    final completedTasks = periodTasks.where((task) => task.isCompleted).length;
    final totalTasks = periodTasks.length;
    
    if (totalTasks == 0) return insights;
    
    final completionRate = (completedTasks / totalTasks * 100);
    final importantTasks = periodTasks.where((task) => task.isImportant).length;
    final urgentTasks = periodTasks.where((task) => task.isUrgent).length;
    final focusScore = _calculateFocusScore(periodTasks);
    
    // 完成率洞察
    if (completionRate >= 80) {
      insights.add(InsightItem(
        title: '出色的执行力！',
        description: '您的任务完成率达到${completionRate.toStringAsFixed(0)}%，保持这个节奏！',
        icon: Icons.trending_up,
        color: Colors.green,
      ));
    } else if (completionRate < 50) {
      insights.add(InsightItem(
        title: '需要提升执行力',
        description: '完成率较低，建议减少任务数量或延长时间安排',
        icon: Icons.warning,
        color: Colors.orange,
      ));
    }
    
    // 专注度洞察
    if (focusScore >= 70) {
      insights.add(InsightItem(
        title: '专注度很高',
        description: '您很好地专注于重要任务，这是成功的关键',
        icon: Icons.center_focus_strong,
        color: Colors.blue,
      ));
    } else if (focusScore < 30) {
      insights.add(InsightItem(
        title: '建议提高专注度',
        description: '尝试将更多精力投入到重要任务上',
        icon: Icons.center_focus_weak,
        color: Colors.red,
      ));
    }
    
    // 紧急任务洞察
    if (urgentTasks > totalTasks * 0.6) {
      insights.add(InsightItem(
        title: '紧急任务过多',
        description: '建议提前规划，减少临时紧急任务',
        icon: Icons.schedule,
        color: Colors.red,
      ));
    }
    
    // 工作负载洞察
    final avgTasksPerDay = _getAverageTasksPerDay(periodTasks);
    if (avgTasksPerDay > 10) {
      insights.add(InsightItem(
        title: '工作负载较重',
        description: '日均${avgTasksPerDay.toStringAsFixed(1)}个任务，注意劳逸结合',
        icon: Icons.work,
        color: Colors.orange,
      ));
    }
    
    return insights;
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出报告'),
        content: const Text('选择导出格式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToCSV();
            },
            child: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF() {
    // TODO: 实现PDF导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF导出功能开发中...')),
    );
  }

  void _exportToCSV() {
    // TODO: 实现CSV导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV导出功能开发中...')),
    );
  }
}

// 洞察项目数据类
class InsightItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  InsightItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

extension DateTimeExtension on DateTime {
  int get dayOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return difference(firstDayOfYear).inDays + 1;
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../services/statistics_service.dart';

class CategoryStatsScreen extends StatelessWidget {
  const CategoryStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final statisticsService = StatisticsService(
      taskProvider: taskProvider,
      categoryProvider: categoryProvider,
    );
    
    final categoryStats = statisticsService.getCategoryStats();
    final categoryTrends = statisticsService.getCategoryTrends();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类任务统计'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分类任务概览',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryStatsList(categoryStats),
            const SizedBox(height: 24),
            const Text(
              '分类任务趋势',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryTrendsChart(categoryTrends),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryStatsList(Map<TaskCategory, CategoryStats> stats) {
    // 按层级分组统计
    final topLevelStats = <TaskCategory, CategoryStats>{};
    final subLevelStats = <TaskCategory, CategoryStats>{};
    
    for (final entry in stats.entries) {
      final category = entry.key;
      final stat = entry.value;
      
      if (category.level == 0) {
        topLevelStats[category] = stat;
      } else {
        subLevelStats[category] = stat;
      }
    }
    
    return Column(
      children: [
        // 顶级分类统计
        ...topLevelStats.entries.map((entry) {
          final category = entry.key;
          final stat = entry.value;
          
          return _buildCategoryStatCard(category, stat, indentLevel: 0);
        }),
        
        // 二级分类统计
        ...subLevelStats.entries.map((entry) {
          final category = entry.key;
          final stat = entry.value;
          
          return _buildCategoryStatCard(category, stat, indentLevel: 1);
        }),
      ],
    );
  }
  
  Widget _buildCategoryStatCard(TaskCategory category, CategoryStats stat, {int indentLevel = 0}) {
    final isSubCategory = indentLevel > 0;
    
    return Card(
      margin: EdgeInsets.only(
        left: indentLevel * 16, // 根据层级增加缩进
        right: 8,
        top: 4,
        bottom: 4,
      ),
      child: Padding(
        padding: EdgeInsets.all(isSubCategory ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 层级指示器
                if (isSubCategory)
                  Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                
                Icon(
                  IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: category.color.withOpacity(isSubCategory ? 0.8 : 1.0),
                  size: isSubCategory ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: isSubCategory ? 16 : 18,
                          fontWeight: isSubCategory ? FontWeight.w500 : FontWeight.bold,
                          color: category.color.withOpacity(isSubCategory ? 0.8 : 1.0),
                        ),
                      ),
                      if (isSubCategory) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '子分类',
                            style: TextStyle(
                              fontSize: 10,
                              color: category.color.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('总任务', stat.totalTasks.toString(), isSubCategory),
                _buildStatItem('已完成', stat.completedTasks.toString(), isSubCategory),
                _buildStatItem('完成率', '${stat.completionRate.toStringAsFixed(1)}%', isSubCategory),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('重要任务', stat.importantTasks.toString(), isSubCategory),
                _buildStatItem('紧急任务', stat.urgentTasks.toString(), isSubCategory),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stat.completionRate / 100,
              backgroundColor: category.color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                category.color.withOpacity(isSubCategory ? 0.8 : 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, bool isSubCategory) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSubCategory ? 11 : 12,
            color: Colors.grey.withOpacity(isSubCategory ? 0.7 : 1.0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSubCategory ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(isSubCategory ? 0.8 : 1.0),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryTrendsChart(Map<TaskCategory, List<DailyStats>> trends) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: trends.entries.map((entry) {
            final category = entry.key;
            final stats = entry.value;
            
            return LineChartBarData(
              spots: stats.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.totalTasks.toDouble());
              }).toList(),
              isCurved: true,
              color: category.color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: category.color.withOpacity(0.2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
} 
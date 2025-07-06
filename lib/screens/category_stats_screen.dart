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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final category = stats.keys.elementAt(index);
        final stat = stats[category]!;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: category.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('总任务', stat.totalTasks.toString()),
                    _buildStatItem('已完成', stat.completedTasks.toString()),
                    _buildStatItem('完成率', '${stat.completionRate.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('重要任务', stat.importantTasks.toString()),
                    _buildStatItem('紧急任务', stat.urgentTasks.toString()),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: stat.completionRate / 100,
                  backgroundColor: category.color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
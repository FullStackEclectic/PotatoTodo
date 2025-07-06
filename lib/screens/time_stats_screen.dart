import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../services/statistics_service.dart';

class TimeStatsScreen extends StatefulWidget {
  const TimeStatsScreen({Key? key}) : super(key: key);

  @override
  State<TimeStatsScreen> createState() => _TimeStatsScreenState();
}

class _TimeStatsScreenState extends State<TimeStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间统计分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '每日统计'),
            Tab(text: '每周统计'),
            Tab(text: '每月统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyStatsView(),
          _buildWeeklyStatsView(),
          _buildMonthlyStatsView(),
        ],
      ),
    );
  }
  
  // 构建每日统计视图
  Widget _buildDailyStatsView() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    // 获取特定日期的统计数据
    final stats = StatisticsService.getDailyStats(tasks, _selectedDate);
    
    // 获取最近30天完成情况
    final last30DaysData = StatisticsService.getLast30DaysCompletion(tasks);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期选择
          _buildDateSelector(),
          
          const SizedBox(height: 24),
          
          // 当日统计卡片
          _buildStatsCard(
            title: '${DateFormat('yyyy年MM月dd日').format(_selectedDate)} 统计',
            stats: stats,
          ),
          
          const SizedBox(height: 24),
          
          // 最近30天任务趋势图
          _buildTrendChart(
            title: '最近30天任务趋势',
            dailyData: last30DaysData,
          ),
          
          const SizedBox(height: 24),
          
          // 时段分布图（待实现）
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // 构建每周统计视图
  Widget _buildWeeklyStatsView() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    // 找到周的起始日期
    final DateTime date = _selectedDate;
    final int day = date.weekday;
    final firstDayOfWeek = day == 1 
        ? DateTime(date.year, date.month, date.day)
        : DateTime(date.year, date.month, date.day - (day - 1));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
    
    // 获取特定周的统计数据
    final stats = StatisticsService.getWeeklyStats(tasks, _selectedDate);
    
    // 获取当周每日数据
    final weekDailyData = List.generate(7, (index) {
      final day = firstDayOfWeek.add(Duration(days: index));
      return StatisticsService.getDailyStats(tasks, day);
    });
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 周选择器
          _buildWeekSelector(firstDayOfWeek, lastDayOfWeek),
          
          const SizedBox(height: 24),
          
          // 周统计卡片
          _buildStatsCard(
            title: '${DateFormat('MM月dd日').format(firstDayOfWeek)} 至 ${DateFormat('MM月dd日').format(lastDayOfWeek)} 统计',
            stats: stats,
          ),
          
          const SizedBox(height: 24),
          
          // 本周每日统计
          _buildWeekDailyStats(weekDailyData, firstDayOfWeek),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // 构建每月统计视图
  Widget _buildMonthlyStatsView() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    // 获取特定月的统计数据
    final stats = StatisticsService.getMonthlyStats(tasks, _selectedDate);
    
    // 获取最近12个月统计数据
    final last12MonthsData = StatisticsService.getLast12MonthsCompletion(tasks);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 月份选择器
          _buildMonthSelector(),
          
          const SizedBox(height: 24),
          
          // 月统计卡片
          _buildStatsCard(
            title: '${DateFormat('yyyy年MM月').format(_selectedDate)} 统计',
            stats: stats,
          ),
          
          const SizedBox(height: 24),
          
          // 最近12个月趋势图
          _buildMonthlyTrendChart(
            title: '最近12个月趋势',
            monthlyData: last12MonthsData,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // 构建日期选择器
  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
          },
        ),
        TextButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Text(
            DateFormat('yyyy年MM月dd日').format(_selectedDate),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: _selectedDate.isBefore(DateTime.now()) 
            ? () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  if (_selectedDate.isAfter(DateTime.now())) {
                    _selectedDate = DateTime.now();
                  }
                });
              }
            : null,
        ),
      ],
    );
  }
  
  // 构建周选择器
  Widget _buildWeekSelector(DateTime firstDay, DateTime lastDay) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 7));
            });
          },
        ),
        TextButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Text(
            '${DateFormat('MM/dd').format(firstDay)} - ${DateFormat('MM/dd').format(lastDay)}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: lastDay.isBefore(DateTime.now()) 
            ? () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                  // 确保不超过当前日期
                  final date = _selectedDate;
                  final day = date.weekday;
                  final thisWeekFirstDay = day == 1 
                      ? DateTime(date.year, date.month, date.day)
                      : DateTime(date.year, date.month, date.day - (day - 1));
                  final thisWeekLastDay = thisWeekFirstDay.add(const Duration(days: 6));
                  
                  if (thisWeekLastDay.isAfter(DateTime.now())) {
                    _selectedDate = DateTime.now();
                  }
                });
              }
            : null,
        ),
      ],
    );
  }
  
  // 构建月份选择器
  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
            });
          },
        ),
        TextButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDatePickerMode: DatePickerMode.year,
            );
            if (picked != null) {
              setState(() {
                _selectedDate = DateTime(picked.year, picked.month, 1);
              });
            }
          },
          child: Text(
            DateFormat('yyyy年MM月').format(_selectedDate),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: DateTime(_selectedDate.year, _selectedDate.month + 1, 0).isBefore(DateTime.now()) 
            ? () {
                setState(() {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                  // 确保不超过当前月份
                  final now = DateTime.now();
                  if (_selectedDate.year > now.year || 
                      (_selectedDate.year == now.year && _selectedDate.month > now.month)) {
                    _selectedDate = DateTime(now.year, now.month, 1);
                  }
                });
              }
            : null,
        ),
      ],
    );
  }
  
  // 构建统计卡片
  Widget _buildStatsCard({required String title, required TimeRangeStats stats}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: '任务总数',
                    value: stats.totalTasks.toString(),
                    icon: Icons.assignment,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: '已完成',
                    value: stats.completedTasks.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: '重要任务',
                    value: stats.importantTasks.toString(),
                    icon: Icons.star,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: '紧急任务',
                    value: stats.urgentTasks.toString(),
                    icon: Icons.whatshot,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.completionRate / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              '完成率: ${stats.completionRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建统计项
  Widget _buildStatItem({required String label, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // 构建趋势图
  Widget _buildTrendChart({required String title, required List<DailyCompletionData> dailyData}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildDailyBarChart(dailyData),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend(color: Colors.blue, label: '总任务数'),
                const SizedBox(width: 24),
                _buildChartLegend(color: Colors.green, label: '已完成'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建月度趋势图
  Widget _buildMonthlyTrendChart({required String title, required List<MonthlyCompletionData> monthlyData}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildMonthlyLineChart(monthlyData),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend(color: Colors.blue, label: '总任务数'),
                const SizedBox(width: 24),
                _buildChartLegend(color: Colors.green, label: '已完成'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建图表图例
  Widget _buildChartLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
  
  // 构建每日任务柱状图
  Widget _buildDailyBarChart(List<DailyCompletionData> data) {
    // 防止列表为空或所有值为0导致图表显示异常
    final maxY = data.map((e) => e.totalTasks).reduce((max, value) => max > value ? max : value);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY * 1.2 : 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0');
                if (value % 5 == 0) return Text(value.toInt().toString());
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // 显示日期，但为了避免重叠，只显示部分
                if (value.toInt() % 5 == 0 && value.toInt() < data.length) {
                  final date = data[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(DateFormat('d日').format(date)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index].totalTasks.toDouble(),
                color: Colors.blue.withOpacity(0.7),
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    data[index].completedTasks.toDouble(),
                    Colors.green.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建月度任务折线图
  Widget _buildMonthlyLineChart(List<MonthlyCompletionData> data) {
    // 防止列表为空或所有值为0导致图表显示异常
    final maxY = data.map((e) => e.totalTasks).reduce((max, value) => max > value ? max : value);
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('0');
                if (value % 5 == 0) return Text(value.toInt().toString());
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(data[value.toInt()].monthName),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: data.length - 1.0,
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.2 : 10,
        lineBarsData: [
          // 总任务数线
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index].totalTasks.toDouble()),
            ),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
          ),
          // 已完成任务线
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index].completedTasks.toDouble()),
            ),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
  
  // 构建周视图中的每日统计
  Widget _buildWeekDailyStats(List<TimeRangeStats> weekData, DateTime firstDayOfWeek) {
    const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本周每日情况',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final dayStats = weekData[index];
                  final date = firstDayOfWeek.add(Duration(days: index));
                  final isToday = DateTime.now().day == date.day && 
                                 DateTime.now().month == date.month && 
                                 DateTime.now().year == date.year;
                  
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: isToday ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
                      borderRadius: BorderRadius.circular(8),
                      color: isToday ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayNames[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MM/dd').format(date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 任务完成进度环
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: dayStats.completionRate / 100,
                                backgroundColor: Colors.grey[300],
                                strokeWidth: 8,
                              ),
                              Text(
                                '${dayStats.completionRate.toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '总数: ${dayStats.totalTasks}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '完成: ${dayStats.completedTasks}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
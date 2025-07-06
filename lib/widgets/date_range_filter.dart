import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class DateRangeFilter extends StatefulWidget {
  const DateRangeFilter({Key? key}) : super(key: key);

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final startDate = taskProvider.startDate;
    final endDate = taskProvider.endDate;
    
    // 是否有激活的日期筛选
    final bool hasDateFilter = startDate != null || endDate != null;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 8),
                const Text(
                  '按日期筛选',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasDateFilter)
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('清除'),
                    onPressed: () {
                      taskProvider.clearDateRange();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '开始日期',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        startDate != null ? _dateFormat.format(startDate) : '选择开始日期',
                        style: TextStyle(
                          color: startDate != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '结束日期',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        endDate != null ? _dateFormat.format(endDate) : '选择结束日期',
                        style: TextStyle(
                          color: endDate != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickFilterChip(context, '今天', _getToday(), _getToday()),
                _quickFilterChip(context, '昨天', _getYesterday(), _getYesterday()),
                _quickFilterChip(context, '本周', _getStartOfWeek(), _getToday()),
                _quickFilterChip(context, '本月', _getStartOfMonth(), _getToday()),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 选择开始日期
  Future<void> _selectStartDate(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: taskProvider.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      taskProvider.setDateRange(picked, taskProvider.endDate);
    }
  }
  
  // 选择结束日期
  Future<void> _selectEndDate(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: taskProvider.endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      taskProvider.setDateRange(taskProvider.startDate, picked);
    }
  }
  
  // 快速筛选芯片
  Widget _quickFilterChip(BuildContext context, String label, DateTime? start, DateTime? end) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    return ActionChip(
      label: Text(label),
      onPressed: () {
        taskProvider.setDateRange(start, end);
      },
    );
  }
  
  // 获取今天日期
  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  // 获取昨天日期
  DateTime _getYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return DateTime(yesterday.year, yesterday.month, yesterday.day);
  }
  
  // 获取本周开始日期（周一）
  DateTime _getStartOfWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    // 计算本周一的日期
    return DateTime(now.year, now.month, now.day - (weekday - 1));
  }
  
  // 获取本月开始日期
  DateTime _getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/page_header_widget.dart';
import '../models/task.dart';
import '../screens/task_detail_screen.dart';
import '../constants/quadrant_constants.dart';

enum CalendarViewMode { month, week, overview, year }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // 现代头部组件
          PageHeaderWidget(
            title: '日历',
            subtitle: '查看任务时间安排',
            leading: Icon(
              Icons.calendar_today,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            actions: [
              // 视图切换按钮
              PopupMenuButton<CalendarViewMode>(
                icon: Icon(
                  _getViewModeIcon(),
                  size: 20,
                ),
                tooltip: '切换视图',
                onSelected: (CalendarViewMode mode) {
                  setState(() {
                    _viewMode = mode;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: CalendarViewMode.month,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_month, size: 16),
                        const SizedBox(width: 8),
                        Text('月视图'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CalendarViewMode.week,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_week, size: 16),
                        const SizedBox(width: 8),
                        Text('周视图'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CalendarViewMode.overview,
                    child: Row(
                      children: [
                        Icon(Icons.dashboard, size: 16),
                        const SizedBox(width: 8),
                        Text('日程概览'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: CalendarViewMode.year,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('年视图'),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                    _focusedDate = DateTime.now();
                  });
                },
                icon: const Icon(Icons.today),
                tooltip: '回到今天',
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
          
          // 日历内容
          Expanded(
            child: _buildCalendarContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent(ThemeData theme) {
    switch (_viewMode) {
      case CalendarViewMode.month:
        return _buildMonthView(theme);
      case CalendarViewMode.week:
        return _buildWeekView(theme);
      case CalendarViewMode.overview:
        return _buildOverviewView(theme);
      case CalendarViewMode.year:
        return _buildYearView(theme);
    }
  }

  Widget _buildMonthView(ThemeData theme) {
    return Column(
      children: [
        // 月份导航
        _buildMonthNavigation(theme),
        
        // 星期标题
        _buildWeekHeaders(theme),
        
        // 日历网格
        Expanded(
          flex: 2,
          child: _buildCalendarGrid(theme),
        ),
        
        // 选中日期的任务列表
        Expanded(
          flex: 3,
          child: _buildSelectedDateTasks(theme),
        ),
      ],
    );
  }

  Widget _buildWeekView(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
        final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

        return Column(
          children: [
            // 周导航
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        _focusedDate = _selectedDate;
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  
                  Text(
                    '${weekDays.first.month}月${weekDays.first.day}日 - ${weekDays.last.month}月${weekDays.last.day}日',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 7));
                        _focusedDate = _selectedDate;
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            // 星期标题
            _buildWeekHeaders(theme),

            // 周视图内容 - 简化布局
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: weekDays.map((date) {
                    final isSelected = _isSameDay(date, _selectedDate);
                    final isToday = _isSameDay(date, DateTime.now());
                    final tasksForDate = taskProvider.getTasksByDate(date);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                              ? Border.all(color: theme.colorScheme.primary, width: 2)
                              : isToday
                                ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1)
                                : null,
                          ),
                          child: Column(
                            children: [
                              // 日期
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${date.day}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isSelected 
                                      ? theme.colorScheme.primary
                                      : isToday 
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              
                              // 任务列表
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  itemCount: tasksForDate.length,
                                  itemBuilder: (context, index) {
                                    final task = tasksForDate[index];
                                    final quadrantColor = QuadrantConstants.getQuadrantColor(task.quadrant);
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: task.isCompleted 
                                          ? Colors.grey.withOpacity(0.3)
                                          : quadrantColor.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        task.title,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontSize: 10,
                                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewView(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Column(
          children: [
            // 月份导航
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  
                  Text(
                    '日程概览 ${_focusedDate.year}年${_focusedDate.month}月',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            // 星期标题
            _buildWeekHeaders(theme),
            
            // 日程概览网格 - 类似图片中的布局
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildOverviewCalendarGrid(theme, taskProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCalendarGrid(ThemeData theme, TaskProvider taskProvider) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每个单元格的高度，确保铺满屏幕
        final availableHeight = constraints.maxHeight;
        final cellHeight = availableHeight / 6; // 6行
        
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // 禁用滚动，确保铺满
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: constraints.maxWidth / 7 / cellHeight,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayIndex = index - firstDayWeekday;
            
            if (dayIndex < 0 || dayIndex >= daysInMonth) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.3),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              );
            }
            
            final date = DateTime(_focusedDate.year, _focusedDate.month, dayIndex + 1);
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());
            final tasksForDate = taskProvider.getTasksByDate(date);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                  border: Border.all(
                    color: isToday
                      ? theme.colorScheme.primary
                      : isSelected
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.colorScheme.outline.withOpacity(0.1),
                    width: isToday ? 2 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // 日期头部
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isToday 
                          ? theme.colorScheme.primary
                          : isSelected
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                      child: Text(
                        '${dayIndex + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isToday 
                            ? Colors.white
                            : isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // 任务卡片区域
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          children: [
                            // 显示最多4个任务
                            ...tasksForDate.take(4).map((task) {
                              final quadrantColor = QuadrantConstants.getQuadrantColor(task.quadrant);
                              
                              return Container(
                                width: double.infinity,
                                height: 18,
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: task.isCompleted 
                                    ? Colors.grey.withOpacity(0.6)
                                    : quadrantColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }).toList(),
                            
                            // 如果还有更多任务，显示指示器
                            if (tasksForDate.length > 4)
                              Container(
                                width: double.infinity,
                                height: 16,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${tasksForDate.length - 4}',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 其他辅助方法
  Widget _buildMonthNavigation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          
          Text(
            '${_focusedDate.year}年${_focusedDate.month}月',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeaders(ThemeData theme) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
        final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
        final firstDayWeekday = firstDayOfMonth.weekday % 7;
        final daysInMonth = lastDayOfMonth.day;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayIndex = index - firstDayWeekday;
              
              if (dayIndex < 0 || dayIndex >= daysInMonth) {
                return const SizedBox.shrink();
              }
              
              final date = DateTime(_focusedDate.year, _focusedDate.month, dayIndex + 1);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final tasksForDate = taskProvider.getTasksByDate(date);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? theme.colorScheme.primary 
                      : isToday 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 1)
                      : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${dayIndex + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                            ? Colors.white 
                            : isToday 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (tasksForDate.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (tasksForDate.length <= 3)
                                ...tasksForDate.map((task) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: task.isCompleted 
                                      ? Colors.green 
                                      : QuadrantConstants.getQuadrantColor(task.quadrant),
                                    shape: BoxShape.circle,
                                  ),
                                ))
                              else ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${tasksForDate.length}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isSelected ? Colors.white : theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateTasks(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasksForDate = taskProvider.getTasksByDate(_selectedDate);
        final isToday = _isSameDay(_selectedDate, DateTime.now());
        
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.month}月${_selectedDate.day}日',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '今天',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${tasksForDate.length} 个任务',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: tasksForDate.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '这一天没有安排任务',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasksForDate.length,
                      itemBuilder: (context, index) {
                        final task = tasksForDate[index];
                        return _buildTaskItem(theme, task, taskProvider);
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(ThemeData theme, Task task, TaskProvider taskProvider) {
    final quadrantColor = QuadrantConstants.getQuadrantColor(task.quadrant);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: task.isCompleted 
          ? theme.colorScheme.surface 
          : quadrantColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted 
            ? Colors.green.withOpacity(0.3)
            : quadrantColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () {
            taskProvider.toggleTaskCompletion(task);
          },
          child: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : quadrantColor,
            size: 24,
          ),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted 
              ? theme.colorScheme.onSurface.withOpacity(0.6)
              : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: task.description.isNotEmpty
          ? Text(
              task.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: quadrantColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                QuadrantConstants.getQuadrantName(task.quadrant),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: quadrantColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildYearView(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Column(
          children: [
            // 年份导航
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year - 1, _focusedDate.month);
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  
                  Text(
                    '${_focusedDate.year}年',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year + 1, _focusedDate.month);
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            // 12个月的网格
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthDate = DateTime(_focusedDate.year, month, 1);
                    final isCurrentMonth = DateTime.now().year == _focusedDate.year && 
                                         DateTime.now().month == month;
                    final isSelectedMonth = _selectedDate.year == _focusedDate.year && 
                                          _selectedDate.month == month;
                    
                    // 获取该月的任务统计
                    final monthTasks = taskProvider.allTasks.where((task) {
                      final taskDate = task.dueDate;
                      return taskDate != null && 
                             taskDate.year == _focusedDate.year && 
                             taskDate.month == month;
                    }).toList();
                    
                    final completedTasks = monthTasks.where((task) => task.isCompleted).length;
                    final totalTasks = monthTasks.length;
                    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = DateTime(_focusedDate.year, month, 1);
                          _focusedDate = _selectedDate;
                          _viewMode = CalendarViewMode.month;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelectedMonth 
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentMonth 
                              ? theme.colorScheme.primary
                              : isSelectedMonth
                                ? theme.colorScheme.primary.withOpacity(0.5)
                                : theme.colorScheme.outline.withOpacity(0.2),
                            width: isCurrentMonth ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // 月份标题
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${month}月',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentMonth || isSelectedMonth
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isCurrentMonth)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // 月份小日历
                            Expanded(
                              child: _buildMiniMonthCalendar(theme, monthDate, monthTasks),
                            ),
                            
                            // 任务统计
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  if (totalTasks > 0) ...[
                                    // 完成率进度条
                                    Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.outline.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: completionRate,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _getCompletionRateColor(completionRate * 100),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$completedTasks/$totalTasks 任务',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '无任务',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniMonthCalendar(ThemeData theme, DateTime monthDate, List<Task> monthTasks) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayIndex = index - firstDayWeekday;
        
        if (dayIndex < 0 || dayIndex >= daysInMonth) {
          return const SizedBox.shrink();
        }
        
        final date = DateTime(monthDate.year, monthDate.month, dayIndex + 1);
        final isToday = _isSameDay(date, DateTime.now());
        final tasksForDate = monthTasks.where((task) {
          final taskDate = task.dueDate;
          return taskDate != null && _isSameDay(taskDate, date);
        }).toList();
        
        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: isToday 
              ? theme.colorScheme.primary.withOpacity(0.3)
              : tasksForDate.isNotEmpty
                ? theme.colorScheme.primary.withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${dayIndex + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday 
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                if (tasksForDate.isNotEmpty)
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: isToday 
                        ? Colors.white
                        : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        return Icons.calendar_view_month;
      case CalendarViewMode.week:
        return Icons.calendar_view_week;
      case CalendarViewMode.overview:
        return Icons.dashboard;
      case CalendarViewMode.year:
        return Icons.calendar_today;
    }
  }
}
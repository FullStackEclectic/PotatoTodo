import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../providers/task_provider.dart';
import '../widgets/page_header_widget.dart';
import '../widgets/calendar_heatmap_widget.dart'; // Import the new widget
import '../models/task.dart';
import '../themes/app_theme.dart';
import '../utils/animations.dart';
import '../constants/quadrant_constants.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart'; // Removed alias
import 'package:permission_handler/permission_handler.dart';

enum CalendarViewMode { month, week, overview }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  
  // final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin(); // TODO: Fix dependency
  List<Event> _systemEvents = []; 
  bool _hasCalendarPermission = false;

  @override
  void initState() {
    super.initState();
    // _requestCalendarPermission(); 
  }

  Future<void> _requestCalendarPermission() async {
    // Temporarily disabled due to build errors with device_calendar_plus
    /*
    try {
      var permissions = await _deviceCalendarPlugin.requestPermissions();
      if (permissions.isSuccess && permissions.data!) {
        setState(() => _hasCalendarPermission = true);
        _fetchSystemEvents();
      } else {
        var status = await Permission.calendarFullAccess.status;
        if (!status.isGranted) {
           status = await Permission.calendarFullAccess.request();
           if (status.isGranted) {
              setState(() => _hasCalendarPermission = true);
              _fetchSystemEvents();
           }
        }
      }
    } catch (e) {
      debugPrint('Error requesting calendar permissions: $e');
    }
    */
  }

  Future<void> _fetchSystemEvents() async {
    // Temporarily disabled
    /*
    if (!_hasCalendarPermission) return;
    try {
      final now = DateTime.now();
      final startDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
      final endDate = DateTime(_focusedDate.year, _focusedDate.month + 2, 0);
      
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        List<Event> allEvents = [];
        for (var cal in calendarsResult.data!) {
           final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
             cal.id, 
             RetrieveEventsParams(startDate: startDate, endDate: endDate)
           );
           if (eventsResult.isSuccess && eventsResult.data != null) {
             allEvents.addAll(eventsResult.data!);
           }
        }
        if (mounted) {
          setState(() {
            _systemEvents = allEvents;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching system events: $e');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
         _buildHeader(theme),
          
          Expanded(
            child: Animations.smoothTransition(
              child: _buildBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return PageHeaderWidget(
      title: '日历',
      subtitle: _viewMode == CalendarViewMode.overview 
          ? '年度概览' 
          : '${_focusedDate.year}年${_focusedDate.month}月',
      leading: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
      actions: [
        // View Switcher
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildViewSwitchBtn(CalendarViewMode.month, '月', theme),
              _buildViewSwitchBtn(CalendarViewMode.week, '周', theme),
              _buildViewSwitchBtn(CalendarViewMode.overview, '年', theme),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.today_rounded),
          tooltip: '今天',
          onPressed: () {
            setState(() {
              _selectedDate = DateTime.now();
              _focusedDate = DateTime.now();
            });
          },
        ),
      ],
    );
  }

  Widget _buildViewSwitchBtn(CalendarViewMode mode, String label, ThemeData theme) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_viewMode) {
      case CalendarViewMode.month:
        return _buildMonthView(theme);
      case CalendarViewMode.week:
        return _buildWeekView(theme);
      case CalendarViewMode.overview:
        return _buildOverviewView(theme);
    }
  }

  Widget _buildMonthView(ThemeData theme) {
    return Column(
      children: [
        // Calendar Grid
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildWeekDaysHeader(theme),
              const Divider(height: 1),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate required height for 6 rows + padding
                  // GridView padding is 8 top + 8 bottom = 16 vertical
                  // CrossAxis count is 7
                  const double gridVerticalPadding = 16.0;
                  const double gridHorizontalPadding = 16.0; // 8 left + 8 right
                  
                  // content width available for headers
                  final double availableWidth = constraints.maxWidth - gridHorizontalPadding;
                  final double cellWidth = availableWidth / 7;
                  
                  // childAspectRatio is 1.0 so cellHeight = cellWidth
                  final double requiredHeight = (cellWidth * 6) + gridVerticalPadding;

                  return SizedBox(
                    height: requiredHeight, 
                    child: PageView.builder(
                      controller: PageController(initialPage: _calculatePageIndex(_focusedDate)),
                      onPageChanged: (index) {
                         setState(() {
                           _focusedDate = DateTime(_focusedDate.year, index % 12 + 1);
                           // We need a more robust way to handle year changes in page view, 
                           // but for simplicity in this refactor, we stick to basic month nav or simple manual nav.
                           // Actually, let's just use manual arrows for safety and control.
                         });
                      },
                      physics: const NeverScrollableScrollPhysics(), // Disable swipe for now to avoid complex date math issues
                      itemBuilder: (context, index) {
                        return _buildCalendarGrid(theme);
                      },
                    ),
                  );
                },
              ),
               // Navigation Buttons (Manual)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                       setState(() => _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1));
                       _fetchSystemEvents(); // Refresh events for new month range
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () { 
                       setState(() => _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1));
                       _fetchSystemEvents();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Task List for Selected Date
        Expanded(child: _buildSelectedDateTaskList(theme)),
      ],
    );
  }

  int _calculatePageIndex(DateTime date) {
    return date.month - 1 + (date.year - 2020) * 12; // Arbitrary base year
  }

  Widget _buildWeekDaysHeader(ThemeData theme) {
    const days = ['日', '一', '二', '三', '四', '五', '六'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((e) => Text(
          e, 
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold, 
            color: theme.colorScheme.onSurface.withOpacity(0.4)
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
        final firstDayWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday % 7;
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: 42, // Always show 6 rows
          itemBuilder: (context, index) {
            final dayOffset = index - firstDayWeekday;
            if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox.shrink();
            
            final date = DateTime(_focusedDate.year, _focusedDate.month, dayOffset + 1);
            final tasks = taskProvider.getTasksByDate(date);
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());
            
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : isToday ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                         color: isSelected 
                            ? Colors.white 
                            : isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                         fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (tasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Show small dots/bars for tasks
                            // Tasks dot
                            Container(
                              width: 4, height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : _getTaskStatusColor(tasks),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // System events dot
                            if (_getSystemEvents(_systemEvents, date).isNotEmpty) ...[
                               const SizedBox(width: 2),
                               Container(
                                 width: 4, height: 4,
                                 decoration: BoxDecoration(
                                   color: isSelected ? Colors.white : Colors.purpleAccent,
                                   shape: BoxShape.circle,
                                 ),
                               ),
                            ]
                          ],
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

  Color _getTaskStatusColor(List<Task> tasks) {
    if (tasks.every((t) => t.isCompleted)) return Colors.green;
    if (tasks.any((t) => t.quadrant == QuadrantType.importantUrgent)) return AppTheme.q1ImportantUrgent;
    return Colors.grey;
  }

  Widget _buildWeekView(ThemeData theme) {
     return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Logic to show a horizontal scrollable week strip
        return Column(
          children: [
             // For simplicity in this demo, just reuse the month grid logic but formatted differently?
             // Or better, a horizontal list of days.
             SizedBox(
               height: 100,
               child: ListView.builder(
                 scrollDirection: Axis.horizontal,
                 itemCount: 30, // Show 30 days around selected date?
                 // This is tricky without a proper library. 
                 // Let's implement a simple 7-day strip centered on selected date.
                 itemBuilder: (context, index) {
                   final date = _selectedDate.subtract(const Duration(days: 3)).add(Duration(days: index));
                   final isSelected = _isSameDay(date, _selectedDate);
                   
                   return GestureDetector(
                     onTap: () => setState(() => _selectedDate = date),
                     child: Container(
                       width: 60,
                       margin: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             _getWeekdayName(date.weekday),
                             style: theme.textTheme.bodySmall?.copyWith(
                               color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5)
                             ),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             '${date.day}',
                             style: theme.textTheme.titleMedium?.copyWith(
                               fontWeight: FontWeight.bold,
                               color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                             ),
                           ),
                         ],
                       ),
                     ),
                   );
                 },
               ),
             ),
             Expanded(child: _buildSelectedDateTaskList(theme)),
          ],
        );
      }
     );
  }

  String _getWeekdayName(int weekday) {
    return ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][weekday - 1];
  }

  Widget _buildOverviewView(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Group all tasks by date
        final Map<DateTime, List<Task>> datasets = {};
        for (var task in taskProvider.allTasks) {
          // Assuming task has a date field. If it's a timestamp, truncate to day.
          // The Task model might not have a direct 'date' field if it's just a todo list.
          // Let's check how taskProvider.getTasksByDate(date) works.
          // It likely filters by date.
          // Warning: Iterating all tasks and extracting dates might be slow if tasks don't store date.
          // But typically they do.
          if (task.dueDate != null) {
            final date = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
            if (datasets[date] == null) datasets[date] = [];
            datasets[date]!.add(task);
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('年度效率热力图', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              CalendarHeatmapWidget(
                startDate: DateTime.now().subtract(const Duration(days: 365)),
                endDate: DateTime.now(),
                datasets: datasets,
                onDaySelected: (date) {
                   setState(() {
                     _selectedDate = date;
                     _viewMode = CalendarViewMode.month; // Jump to month view on selection
                     _focusedDate = date;
                   });
                },
              ),
              const Spacer(),
              Center(
                child: Icon(Icons.insights_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }


  Widget _buildSelectedDateTaskList(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.getTasksByDate(_selectedDate);
        final systemEvents = _getSystemEvents(_systemEvents, _selectedDate);
        
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedDate.month}月${_selectedDate.day}日 任务列表',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${tasks.length} 个任务',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5)
                          ),
                        ),
                      ],
                    ),
                    FloatingActionButton.small(
                      onPressed: () {
                         // Add task logic
                         // Navigator.pushNamed(context, '/add_task', arguments: _selectedDate);
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // List
              Expanded(
                child: tasks.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text('这一天没有任务', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                        ],
                      ),
                    )
                  : Animations.animatedList(
                      itemCount: tasks.length + systemEvents.length,
                      itemBuilder: (context, index) {
                        // Creating a combined list view?
                        // Let's show system events first if any
                        if (index < systemEvents.length) {
                           final event = systemEvents[index];
                           return Container(
                             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                             decoration: BoxDecoration(
                               color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.purple.withOpacity(0.3)),
                             ),
                             child: ListTile(
                               leading: const Icon(Icons.event, color: Colors.purple),
                               title: Text(event.title ?? '无标题'),
                               subtitle: Text(
                                 // event.allDay == true 
                                   // ? '全天' 
                                   // : 
                                   '${event.startDate?.hour}:${event.startDate?.minute.toString().padLeft(2,'0')} - ${event.endDate?.hour}:${event.endDate?.minute.toString().padLeft(2,'0')}'
                               ),
                             ),
                           );
                        }
                        
                        final taskIndex = index - systemEvents.length;
                        final task = tasks[taskIndex];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: QuadrantConstants.getQuadrantColor(task.quadrant),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: Checkbox(
                              value: task.isCompleted,
                              onChanged: (val) {
                                taskProvider.toggleTaskCompletion(task);
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  List<Event> _getSystemEvents(List<Event> events, DateTime date) {
    return events.where((e) {
      if (e.startDate == null) return false;
      // Simple same day check considering Timezones? 
      // device_calendar events usually have TZ info.
      // e.startDate is DateTime.
      return e.startDate!.year == date.year && e.startDate!.month == date.month && e.startDate!.day == date.day;
    }).toList();
  }
}
import 'package:flutter/material.dart';
import '../models/task.dart';

class CalendarHeatmapWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, List<Task>> datasets;
  final Function(DateTime)? onDaySelected;

  const CalendarHeatmapWidget({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.datasets,
    this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate all days between start and end
    final days = _generateDays();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cell size based on width and roughly 53 weeks (columns)
        final double cellSize = (constraints.maxWidth - 52 * 2) / 53; 

        return SizedBox(
          height: cellSize * 7 + 30, // 7 days + padding
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (days.length / 7).ceil(),
            itemBuilder: (context, weekIndex) {
              return Column(
                children: [
                  // Month Label if it's the start of a month in this week
                  _buildMonthLabel(context, weekIndex, days, cellSize),
                  
                  // Days in this week
                  ...List.generate(7, (dayIndex) {
                    final index = weekIndex * 7 + dayIndex;
                    if (index >= days.length) return SizedBox(height: cellSize);
                    
                    final day = days[index];
                    final tasks = datasets[DateTime(day.year, day.month, day.day)] ?? [];
                    final intensity = _calculateIntensity(tasks);

                    return GestureDetector(
                      onTap: () => onDaySelected?.call(day),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: _getColorForIntensity(intensity, theme),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Tooltip(
                          message: '${day.year}-${day.month}-${day.day}\n${tasks.length} tasks',
                          child: const SizedBox(),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<DateTime> _generateDays() {
    final List<DateTime> days = [];
    // Align start date to previous Sunday (or Monday depending on preference)
    // Here we assume Sunday start
    DateTime current = startDate.subtract(Duration(days: startDate.weekday % 7));
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  Widget _buildMonthLabel(BuildContext context, int weekIndex, List<DateTime> days, double width) {
    final index = weekIndex * 7;
    if (index >= days.length) return SizedBox(width: width, height: 20);
    
    final day = days[index];
    // Show month label roughly every 4 weeks or when month changes
    if (day.day <= 7) {
      return Container(
        width: width,
        height: 20,
        alignment: Alignment.center,
        child: Text(
          _getMonthName(day.month),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      );
    }
    return SizedBox(width: width, height: 20);
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  double _calculateIntensity(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    // Simple logic: more tasks = darker color. Cap at 1.0 (e.g., 10 tasks)
    return (tasks.length / 5).clamp(0.0, 1.0);
  }

  Color _getColorForIntensity(double intensity, ThemeData theme) {
    if (intensity == 0) return theme.colorScheme.outline.withOpacity(0.1);
    
    // Interpolate between light and dark primary color
    return Color.lerp(
      theme.colorScheme.primary.withOpacity(0.3),
      theme.colorScheme.primary,
      intensity,
    )!;
  }
}

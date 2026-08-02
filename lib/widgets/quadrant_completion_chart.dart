import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../constants/quadrant_constants.dart';

class QuadrantCompletionChart extends StatelessWidget {
  const QuadrantCompletionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final quadrants = [
      QuadrantType.importantUrgent,
      QuadrantType.importantNotUrgent,
      QuadrantType.notImportantUrgent,
      QuadrantType.notImportantNotUrgent,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '四象限完成率对比',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...quadrants.map((quadrant) {
              final tasks = taskProvider.getTasksByQuadrant(quadrant);
              final completionRate = taskProvider.getCompletionRateByQuadrant(
                quadrant,
              );
              final completedCount = taskProvider.getCompletedCountByQuadrant(
                quadrant,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          QuadrantConstants.getQuadrantName(quadrant),
                          style: TextStyle(
                            color: QuadrantConstants.getQuadrantColor(quadrant),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${completionRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: completionRate / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        QuadrantConstants.getQuadrantColor(quadrant),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已完成: $completedCount / ${tasks.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

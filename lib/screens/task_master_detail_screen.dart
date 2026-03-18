import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart';
import 'task_detail_screen.dart';

class TaskMasterDetailScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  const TaskMasterDetailScreen({Key? key, required this.parentScaffoldKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final selectedTask = taskProvider.selectedTask;

        return Row(
          children: [
            // Master View (Task List)
            Expanded(
              flex: 1,
              child: HomeScreen(
                scaffoldKey: parentScaffoldKey,
                // Prevent HomeScreen from trying to navigate on its own in master-detail view
                isMasterDetail: true,
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Detail View
            Expanded(
              flex: 2,
              child: selectedTask != null
                  ? TaskDetailScreen(
                      task: selectedTask,
                      isMasterDetailView: true,
                      // Pass a key to ensure the widget rebuilds when the task changes
                      key: ValueKey(selectedTask.id),
                    )
                  : const Center(
                      child: Text('选择一个任务以查看详情'),
                    ),
            ),
          ],
        );
      },
    );
  }
}

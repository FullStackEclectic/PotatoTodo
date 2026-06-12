import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../constants/quadrant_constants.dart';
import 'task_detail_screen.dart';

class QuadrantViewScreen extends StatefulWidget {
  final QuadrantType initialQuadrant;
  final bool showAsGrid;

  const QuadrantViewScreen({
    Key? key,
    this.initialQuadrant = QuadrantType.importantUrgent,
    this.showAsGrid = true,
  }) : super(key: key);

  @override
  State<QuadrantViewScreen> createState() => _QuadrantViewScreenState();
}

class _QuadrantViewScreenState extends State<QuadrantViewScreen> {
  late QuadrantType _selectedQuadrant;

  @override
  void initState() {
    super.initState();
    _selectedQuadrant = widget.initialQuadrant;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[QuadrantViewScreen] didChangeDependencies，选中象限: $_selectedQuadrant');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAsGrid) {
      return _buildQuadrantGrid();
    } else {
      return _buildSingleQuadrantView();
    }
  }
  
  Widget _buildQuadrantGrid() {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        return Container(
          width: screenWidth,
          height: screenHeight,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // 左上角：重要且紧急
                    _buildQuadrantCard(
                      width: screenWidth / 2,
                      height: screenHeight / 2,
                      quadrant: QuadrantType.importantUrgent,
                      taskProvider: taskProvider,
                    ),
                    
                    // 右上角：重要不紧急
                    _buildQuadrantCard(
                      width: screenWidth / 2,
                      height: screenHeight / 2,
                      quadrant: QuadrantType.importantNotUrgent,
                      taskProvider: taskProvider,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // 左下角：紧急不重要
                    _buildQuadrantCard(
                      width: screenWidth / 2,
                      height: screenHeight / 2,
                      quadrant: QuadrantType.notImportantUrgent,
                      taskProvider: taskProvider,
                    ),
                    
                    // 右下角：不重要不紧急
                    _buildQuadrantCard(
                      width: screenWidth / 2,
                      height: screenHeight / 2,
                      quadrant: QuadrantType.notImportantNotUrgent,
                      taskProvider: taskProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildQuadrantCard({
    required double width,
    required double height,
    required QuadrantType quadrant,
    required TaskProvider taskProvider,
  }) {
    final tasks = taskProvider.getTasksByQuadrant(quadrant);
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
    
    return GestureDetector(
      onTap: () {
        // 设置选中的象限并导航到单象限视图
        taskProvider.setSelectedQuadrant(quadrant);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuadrantViewScreen(initialQuadrant: quadrant, showAsGrid: false),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(1),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: BorderSide(
              color: QuadrantConstants.getQuadrantColor(quadrant),
              width: 2.0,
            ),
          ),
          child: Column(
            children: [
              // 头部信息
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          QuadrantConstants.getQuadrantIcon(quadrant),
                          size: 20.0,
                          color: QuadrantConstants.getQuadrantColor(quadrant),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            QuadrantConstants.getQuadrantName(quadrant),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                        Text(
                          '$totalTasks',
                          style: TextStyle(
                            color: QuadrantConstants.getQuadrantColor(quadrant),
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    if (totalTasks > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4.0),
                        height: 2.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completionRate / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: QuadrantConstants.getQuadrantColor(quadrant),
                              borderRadius: BorderRadius.circular(1.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // 任务列表
              Expanded(
                child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        '暂无任务',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12.0,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: tasks.length > 3 ? 3 : tasks.length, // 最多显示3个任务
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: task.isCompleted 
                              ? Colors.grey[100] 
                              : QuadrantConstants.getQuadrantColor(quadrant).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: QuadrantConstants.getQuadrantColor(quadrant).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 12.0,
                                color: task.isCompleted 
                                  ? Colors.green 
                                  : QuadrantConstants.getQuadrantColor(quadrant),
                              ),
                              const SizedBox(width: 6.0),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color: task.isCompleted ? Colors.grey[600] : null,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
              
              // 底部提示
              if (tasks.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '还有 ${tasks.length - 3} 个任务...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10.0,
                    ),
                  ),
                ),
              Container(
                height: 30,
                margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addNewTask(quadrant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuadrantConstants.getQuadrantColor(quadrant),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    minimumSize: const Size(double.infinity, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '添加任务',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSingleQuadrantView() {
    final tasks = Provider.of<TaskProvider>(context).getTasksByQuadrant(_selectedQuadrant);
    String quadrantTitle = QuadrantConstants.getQuadrantName(_selectedQuadrant);
    final quadrantColor = QuadrantConstants.getQuadrantColor(_selectedQuadrant);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 象限标题和描述
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: quadrantColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  QuadrantConstants.getQuadrantIcon(_selectedQuadrant),
                  color: quadrantColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quadrantTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: quadrantColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        QuadrantConstants.getQuadrantDescription(_selectedQuadrant),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 任务列表
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState(_selectedQuadrant)
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskItem(
                        task: task,
                        onTap: () => _openTaskDetail(task),
                        onCompletedChanged: (completed) {
                          Provider.of<TaskProvider>(context, listen: false)
                              .toggleTaskCompletion(task);
                        },
                        onDeleteRequested: () {
                          if (task.id != null) {
                            Provider.of<TaskProvider>(context, listen: false)
                                .deleteTask(task.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
          
          // 添加任务按钮
          Container(
            height: 45,
            margin: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addNewTask(_selectedQuadrant),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加任务到此象限'),
              style: ElevatedButton.styleFrom(
                backgroundColor: quadrantColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // 添加空状态提示
  Widget _buildEmptyState(QuadrantType quadrant) {
    final quadrantColor = QuadrantConstants.getQuadrantColor(quadrant);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            QuadrantConstants.getQuadrantIcon(quadrant),
            size: 60,
            color: quadrantColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加新任务',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewTask(QuadrantType quadrantType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: null,
          initialQuadrantType: quadrantType,
        ),
      ),
    );
  }

  void _openTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
  }
} 
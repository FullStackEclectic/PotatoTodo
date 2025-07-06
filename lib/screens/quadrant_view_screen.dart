import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/quadrant_stats.dart';
import '../providers/task_provider.dart';
import '../constants/quadrant_constants.dart';
import '../widgets/task_item.dart';
import '../widgets/quadrant_stat_card.dart';
import 'main_layout.dart';
import 'task_detail_screen.dart';
import 'quadrant_stats_screen.dart';
import '../widgets/task_list.dart';

class QuadrantViewScreen extends StatefulWidget {
  final QuadrantType initialQuadrant;
  final bool showAsGrid;

  const QuadrantViewScreen({
    Key? key,
    required this.initialQuadrant,
    this.showAsGrid = false,
  }) : super(key: key);

  @override
  State<QuadrantViewScreen> createState() => _QuadrantViewScreenState();
}

class _QuadrantViewScreenState extends State<QuadrantViewScreen> {
  late TaskProvider _taskProvider;
  late QuadrantType _selectedQuadrant;
  late PageController _pageController;
  int _currentQuadrantIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedQuadrant = widget.initialQuadrant;
    _currentQuadrantIndex = _getQuadrantIndex(_selectedQuadrant);
    _pageController = PageController(initialPage: _currentQuadrantIndex);
    debugPrint('[QuadrantViewScreen] 初始化，选中象限: $_selectedQuadrant，索引: $_currentQuadrantIndex');
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getQuadrantIndex(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return 0;
      case QuadrantType.importantNotUrgent:
        return 1;
      case QuadrantType.notImportantUrgent:
        return 2;
      case QuadrantType.notImportantNotUrgent:
        return 3;
      default:
        return 0;
    }
  }
  
  QuadrantType _getQuadrantTypeFromIndex(int index) {
    switch (index) {
      case 0:
        return QuadrantType.importantUrgent;
      case 1:
        return QuadrantType.importantNotUrgent;
      case 2:
        return QuadrantType.notImportantUrgent;
      case 3:
        return QuadrantType.notImportantNotUrgent;
      default:
        return QuadrantType.importantUrgent;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _taskProvider = Provider.of<TaskProvider>(context);
    
    // 使用addPostFrameCallback延迟调用setSelectedQuadrant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskProvider.setSelectedQuadrant(widget.showAsGrid ? null : _selectedQuadrant);
    });
    
    debugPrint('[QuadrantViewScreen] didChangeDependencies，选中象限: $_selectedQuadrant');
  }

  void _showTaskDetail(Task task) {
    debugPrint('[QuadrantViewScreen] 显示任务详情: ${task.title}');
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  void _addNewTask(QuadrantType quadrantType) {
    debugPrint('[QuadrantViewScreen] 添加新任务，初始象限: $quadrantType');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: null,
          initialQuadrantType: quadrantType,
        ),
      ),
    );
  }
  
  void _onQuadrantSelected(QuadrantType quadrantType) {
    setState(() {
      _selectedQuadrant = quadrantType;
      _currentQuadrantIndex = _getQuadrantIndex(quadrantType);
      _pageController.animateToPage(
        _currentQuadrantIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    _taskProvider.setSelectedQuadrant(quadrantType);
  }

  String _getQuadrantTitle(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return '重要且紧急';
      case QuadrantType.importantNotUrgent:
        return '重要不紧急';
      case QuadrantType.notImportantUrgent:
        return '紧急不重要';
      case QuadrantType.notImportantNotUrgent:
        return '不重要不紧急';
    }
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
    final quadrants = [
      QuadrantType.importantUrgent,
      QuadrantType.importantNotUrgent,
      QuadrantType.notImportantUrgent,
      QuadrantType.notImportantNotUrgent,
    ];
    
    // 计算四象限统计数据
    final stats = QuadrantStats(
      totalTasks: taskProvider.tasks.length,
      importantUrgentCount: taskProvider.getTasksByQuadrant(QuadrantType.importantUrgent).length,
      importantNotUrgentCount: taskProvider.getTasksByQuadrant(QuadrantType.importantNotUrgent).length,
      notImportantUrgentCount: taskProvider.getTasksByQuadrant(QuadrantType.notImportantUrgent).length,
      notImportantNotUrgentCount: taskProvider.getTasksByQuadrant(QuadrantType.notImportantNotUrgent).length,
      completedCount: taskProvider.tasks.where((task) => task.isCompleted).length,
    );
    
    debugPrint('[QuadrantViewScreen] 构建四象限网格视图，统计数据: $stats');
    
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
            builder: (context) => QuadrantViewScreen(initialQuadrant: quadrant),
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
              color: _getQuadrantColor(quadrant),
              width: 2.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4, // 增加上部分比例
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getQuadrantIcon(quadrant),
                      size: 32.0, // 减小图标大小
                      color: _getQuadrantColor(quadrant),
                    ),
                    const SizedBox(height: 8.0), // 减小间距
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        _getQuadrantTitle(quadrant),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0, // 减小字体大小
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8.0), // 减小间距
                    Text(
                      '$totalTasks 个任务',
                      style: const TextStyle(fontSize: 13.0), // 减小字体大小
                    ),
                    const SizedBox(height: 2.0), // 减小间距
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '完成率: ',
                          style: const TextStyle(fontSize: 13.0), // 减小字体大小
                        ),
                        Text(
                          '$completionRate%',
                          style: TextStyle(
                            fontSize: 13.0, // 减小字体大小
                            fontWeight: FontWeight.bold,
                            color: _getQuadrantColor(quadrant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 30, // 固定高度，减小按钮高度
                margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0), // 调整边距
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addNewTask(quadrant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getQuadrantColor(quadrant),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 0.0), // 减小内边距
                    minimumSize: const Size(double.infinity, 30), // 减小最小高度
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 减小点击区域
                  ),
                  child: const Text(
                    '添加任务',
                    style: TextStyle(fontSize: 12.0), // 减小字体大小
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getQuadrantColor(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return Colors.red;
      case QuadrantType.importantNotUrgent:
        return Colors.blue;
      case QuadrantType.notImportantUrgent:
        return Colors.orange;
      case QuadrantType.notImportantNotUrgent:
        return Colors.green;
    }
  }
  
  IconData _getQuadrantIcon(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return Icons.priority_high;
      case QuadrantType.importantNotUrgent:
        return Icons.event;
      case QuadrantType.notImportantUrgent:
        return Icons.alarm;
      case QuadrantType.notImportantNotUrgent:
        return Icons.spa;
    }
  }
  
  Widget _buildSingleQuadrantView() {
    final tasks = _taskProvider.getTasksByQuadrant(_selectedQuadrant);
    debugPrint('[QuadrantViewScreen] 构建单象限视图，选中象限: $_selectedQuadrant，任务数量: ${tasks.length}');
    
    String quadrantTitle = _getQuadrantTitle(_selectedQuadrant);
    final quadrantColor = _getQuadrantColor(_selectedQuadrant);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(quadrantTitle),
        backgroundColor: quadrantColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: '返回四象限网格',
            onPressed: () {
              // 返回四象限网格视图
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuadrantViewScreen(
                    initialQuadrant: _selectedQuadrant,
                    showAsGrid: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 象限标题和描述
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: quadrantColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _getQuadrantIcon(_selectedQuadrant),
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
                        _getQuadrantDescription(_selectedQuadrant),
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
                : TaskList(
                    tasks: tasks,
                    onTaskTap: _showTaskDetail,
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
    );
  }
  
  // 添加空状态提示
  Widget _buildEmptyState(QuadrantType quadrant) {
    final quadrantColor = _getQuadrantColor(quadrant);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getQuadrantIcon(quadrant),
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
  
  String _getQuadrantDescription(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.importantUrgent:
        return '需要立即处理的重要任务';
      case QuadrantType.importantNotUrgent:
        return '需要计划时间的重要任务';
      case QuadrantType.notImportantUrgent:
        return '可以委派给他人的紧急任务';
      case QuadrantType.notImportantNotUrgent:
        return '可以延后或不做的任务';
    }
  }
} 
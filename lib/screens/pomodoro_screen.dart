import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../widgets/page_header_widget.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  PomodoroProvider? _pomodoroProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hook up SnackBar callback
    _pomodoroProvider = Provider.of<PomodoroProvider>(context, listen: false);
    
    _pomodoroProvider!.onWorkCompleteCallback = (minutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow),
                const SizedBox(width: 8),
                Text('专注完成！获得 +$minutes XP'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _pomodoroProvider?.onWorkCompleteCallback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          // 现代头部组件
          PageHeaderWidget(
            title: '专注时间',
            subtitle: '使用番茄钟提高工作效率',
            leading: Icon(
              Icons.timer,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/pomodoro-settings');
                },
                icon: const Icon(Icons.settings),
                tooltip: '番茄钟设置',
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
          
          // 番茄钟内容
          Expanded(
            child: _buildPomodoroContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroContent(ThemeData theme) {
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoroProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 时间显示
              _buildTimerDisplay(theme, pomodoroProvider),
              
              const SizedBox(height: 40),
              
              // 控制按钮
              _buildControlButtons(theme, pomodoroProvider),
              
              const SizedBox(height: 40),
              
              // 状态信息
              _buildStatusInfo(theme, pomodoroProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay(ThemeData theme, PomodoroProvider pomodoroProvider) {
    final minutes = pomodoroProvider.remainingTime ~/ 60;
    final seconds = pomodoroProvider.remainingTime % 60;
    
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getSessionText(pomodoroProvider.currentSession),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(ThemeData theme, PomodoroProvider pomodoroProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 重置按钮
        IconButton(
          onPressed: pomodoroProvider.currentState == PomodoroState.running ? null : () {
            pomodoroProvider.resetTimer();
          },
          icon: const Icon(Icons.refresh),
          tooltip: '重置',
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // 开始/暂停按钮
        ElevatedButton(
          onPressed: () {
            pomodoroProvider.startPauseTimer();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pomodoroProvider.currentState == PomodoroState.running ? Icons.pause : Icons.play_arrow,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                pomodoroProvider.currentState == PomodoroState.running ? '暂停' : '开始',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),
        
        // 跳过按钮
        IconButton(
          onPressed: pomodoroProvider.currentState == PomodoroState.running ? () {
            pomodoroProvider.skipSession();
          } : null,
          icon: const Icon(Icons.skip_next),
          tooltip: '跳过',
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(ThemeData theme, PomodoroProvider pomodoroProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已完成番茄钟',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '${pomodoroProvider.currentPomodoroCount}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '当前阶段',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                _getSessionText(pomodoroProvider.currentSession),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSessionText(SessionType session) {
    switch (session) {
      case SessionType.work:
        return '专注工作';
      case SessionType.shortBreak:
        return '短暂休息';
      case SessionType.longBreak:
        return '长休息';
    }
  }
}
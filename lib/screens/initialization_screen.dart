import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import 'main_layout.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _isInitialized = false;
  String _initializationStatus = 'Starting up...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      setState(() {
        _initializationStatus = 'Loading workspace data...';
      });
      
      await Future.wait([
        taskProvider.initialize(),
        categoryProvider.initialize(),
      ]);
      
      setState(() {
        _initializationStatus = 'Finalizing setup...';
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() {
        _isInitialized = true;
      });
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } catch (e) {
      debugPrint('[InitializationScreen] initialization failed: $e');
      setState(() {
        _initializationStatus = 'Initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 应用图标
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 应用名称
              Text(
                '土豆 Todo',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '高效的任务管理工具',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // 加载指示器
              if (!_isInitialized) ...[
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _initializationStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.check_circle,
                  size: 32,
                  color: Colors.green,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '初始化完成',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


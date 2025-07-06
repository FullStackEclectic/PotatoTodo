import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'models/quadrant_type.dart';
import 'screens/main_layout.dart';
import 'screens/task_detail_screen.dart';
import 'screens/quadrant_view_screen.dart';
import 'screens/quadrant_stats_screen.dart';
import 'providers/task_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/pomodoro_provider.dart'; // 导入PomodoroProvider
import 'services/database_factory.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';
import 'animations/animations.dart'; // 导入动画组件

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置应用方向为竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 获取数据库服务
  final db = DatabaseFactory.getDatabaseService();
  await db.initialize();
  
  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(db),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(db, notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => PomodoroProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '土豆 Todo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // 使用自定义页面转场动画
          onGenerateRoute: (settings) {
            Widget page;
            
            // 路由映射
            switch (settings.name) {
              case '/':
                page = const MainLayout();
                break;
              case '/task_detail':
                page = TaskDetailScreen(task: settings.arguments as dynamic);
                break;
              case '/quadrant-view':
                page = const QuadrantViewScreen(
                  initialQuadrant: QuadrantType.importantUrgent,
                  showAsGrid: true,
                );
                break;
              case '/quadrant-stats':
                page = const QuadrantStatsScreen();
                break;
              default:
                page = const MainLayout();
            }
            
            // 返回带动画的页面路由
            return SlidePageRoute(
              page: page,
              direction: SlideDirection.right,
            );
          },
          home: FadeInWidget(
            child: const MainLayout(),
          ),
        );
      },
    );
  }
}

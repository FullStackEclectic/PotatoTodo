import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'utils/status_bar_util.dart';
import 'utils/platform_util.dart';
import 'screens/initialization_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/status_bar_test_screen.dart';
import 'providers/task_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/gamification_provider.dart'; 
import 'services/database_factory.dart' as my_db;
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 为桌面平台初始化 FFI
  if (PlatformUtil.isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // 设置状态栏样式
  StatusBarUtil.setLightStatusBar();
  
  // 获取数据库服务和通知服务
  final db = my_db.DatabaseFactory.getDatabaseService();
  final notificationService = NotificationService();
  
  await Future.wait([
    db.initialize(),
    notificationService.initialize(),
    SoundService().init(),
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(db),
        ),
        ChangeNotifierProvider(
          create: (_) => GamificationProvider(),
        ),
        ChangeNotifierProxyProvider<GamificationProvider, TaskProvider>(
          create: (_) => TaskProvider(
            db,
            notificationService,
            ensureDatabaseInitialized: false,
          ),
          update: (_, gamification, taskProvider) {
            taskProvider!.gamificationProvider = gamification;
            return taskProvider;
          },
        ),
        ChangeNotifierProxyProvider<GamificationProvider, PomodoroProvider>(
          create: (_) => PomodoroProvider(),
          update: (_, gamification, pomodoroProvider) {
            pomodoroProvider!.gamificationProvider = gamification;
            return pomodoroProvider;
          },
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
          home: const InitializationScreen(),
          routes: {
            '/category_list': (context) => const CategoryListScreen(),
            '/status-bar-test': (context) => const StatusBarTestScreen(),
          },
          builder: (context, child) {
            // 根据主题设置状态栏
            StatusBarUtil.setStatusBarForTheme(Theme.of(context));
            
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
        );
      },
    );
  }
}
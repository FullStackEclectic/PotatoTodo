import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'utils/status_bar_util.dart';
import 'screens/initialization_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/test_category_screen.dart';
import 'screens/status_bar_test_screen.dart';
import 'providers/task_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'services/database_factory.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ����Ӧ�÷���Ϊ����
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // ����״̬����ʽ
  StatusBarUtil.setLightStatusBar();
  
  // ��ȡ���ݿ�����������֪ͨ����
  final db = DatabaseFactory.getDatabaseService();
  final notificationService = NotificationService();
  
  await Future.wait([
    db.initialize(),
    notificationService.initialize(),
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(db),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(
            db,
            notificationService,
            ensureDatabaseInitialized: false,
          ),
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
          title: '���� Todo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const InitializationScreen(),
          routes: {
            '/category_list': (context) => const CategoryListScreen(),
            '/test-category': (context) => const TestCategoryScreen(),
            '/status-bar-test': (context) => const StatusBarTestScreen(),
          },
          builder: (context, child) {
            // ������������״̬��
            StatusBarUtil.setStatusBarForTheme(Theme.of(context));
            
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );
          },
        );
      },
    );
  }
}

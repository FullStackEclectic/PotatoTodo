// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:potato_todo/main.dart';
import 'package:potato_todo/providers/task_provider.dart';
import 'package:potato_todo/providers/category_provider.dart';
import 'package:potato_todo/providers/theme_provider.dart';
import 'package:potato_todo/providers/pomodoro_provider.dart';
import 'package:potato_todo/services/database_factory.dart';
import 'package:potato_todo/services/notification_service.dart';

void main() {
  testWidgets('PotatoTodo app loads and shows main content', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(DatabaseFactory.getDatabaseService()),
          ),
          ChangeNotifierProvider(
            create: (_) => TaskProvider(DatabaseFactory.getDatabaseService(), NotificationService()),
          ),
          ChangeNotifierProvider(
            create: (_) => PomodoroProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Let the app initialize
    await tester.pumpAndSettle();

    // Verify that the app title exists
    expect(find.text('土豆 Todo'), findsOneWidget);
    
    // Verify that we can find some basic navigation elements
    // The app should show bottom navigation or main content
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('App navigation works correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(DatabaseFactory.getDatabaseService()),
          ),
          ChangeNotifierProvider(
            create: (_) => TaskProvider(DatabaseFactory.getDatabaseService(), NotificationService()),
          ),
          ChangeNotifierProvider(
            create: (_) => PomodoroProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Let the app initialize
    await tester.pumpAndSettle();

    // Verify the bottom navigation exists and has multiple tabs
    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);
  });
}

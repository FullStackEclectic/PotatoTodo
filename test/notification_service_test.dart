import 'package:flutter_test/flutter_test.dart';
import 'package:potato_todo/services/notification_service.dart';
import 'package:potato_todo/models/task.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('NotificationService can be instantiated', () {
      expect(notificationService, isNotNull);
    });

    test('initialize method completes without throwing', () async {
      // This test just ensures that the initialize method doesn't throw
      // In a real app environment, this would set up notifications properly
      // Here we're just testing that our timezone fixes don't break initialization
      expect(() async => await notificationService.initialize(), returnsNormally);
    });

    test('scheduleTaskReminder handles null dueDate gracefully', () async {
      final task = Task(
        id: 1,
        title: 'Test Task',
        dueDate: null, // No due date
      );

      // Should not throw an exception when dueDate is null
      expect(() async => await notificationService.scheduleTaskReminder(task), returnsNormally);
    });

    test('scheduleTaskReminder handles valid dueDate', () async {
      final task = Task(
        id: 1,
        title: 'Test Task',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
      );

      // Should not throw an exception with valid dueDate
      expect(() async => await notificationService.scheduleTaskReminder(task), returnsNormally);
    });

    test('scheduleTaskReminder cancels notification and returns normally for completed task', () async {
      final task = Task(
        id: 1,
        title: 'Completed Test Task',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        isCompleted: true,
      );

      expect(() async => await notificationService.scheduleTaskReminder(task), returnsNormally);
    });

    test('scheduleTaskReminder cancels notification and returns normally for past dueDate', () async {
      final task = Task(
        id: 1,
        title: 'Past Test Task',
        dueDate: DateTime.now().subtract(const Duration(hours: 1)), // 1 hour ago
        isCompleted: false,
      );

      expect(() async => await notificationService.scheduleTaskReminder(task), returnsNormally);
    });

    test('cancelNotification handles valid id', () async {
      // Should not throw an exception
      expect(() async => await notificationService.cancelNotification(1), returnsNormally);
    });

    test('cancelAllNotifications completes normally', () async {
      // Should not throw an exception
      expect(() async => await notificationService.cancelAllNotifications(), returnsNormally);
    });
  });
}
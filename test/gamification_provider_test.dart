import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_todo/providers/gamification_provider.dart';
import 'package:potato_todo/models/badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GamificationProvider - Check-In Streak', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Corrupt badge preferences are discarded without blocking startup',
      () async {
        SharedPreferences.setMockInitialValues({
          'user_badges': '{not-json',
          'user_xp': -10,
          'user_level': 0,
        });

        final provider = GamificationProvider();
        await provider.initialization;

        expect(provider.xp, 0);
        expect(provider.level, 1);
        final streakBadge = provider.badges.firstWhere(
          (badge) => badge.type == BadgeType.streakFire,
        );
        expect(streakBadge.progress, 1);
        expect(
          provider.badges
              .where((badge) => badge.type != BadgeType.streakFire)
              .every((badge) => badge.progress == 0),
          isTrue,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_badges'), isNot('{not-json'));
      },
    );

    test('First check-in should initialize streak to 1', () async {
      final provider = GamificationProvider();
      // Wait for _loadState (and internal checkInDaily) to complete
      await Future.delayed(Duration.zero);

      expect(provider.consecutiveCheckInDays, 1);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      expect(provider.lastCheckInDate, todayStr);

      final streakBadge = provider.badges.firstWhere(
        (b) => b.type == BadgeType.streakFire,
      );
      expect(streakBadge.progress, 1);
    });

    test('Consecutive check-in next day should increment streak', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().substring(0, 10);

      SharedPreferences.setMockInitialValues({
        'last_check_in_date': yesterdayStr,
        'consecutive_check_in_days': 2,
      });

      final provider = GamificationProvider();
      await Future.delayed(Duration.zero);

      expect(provider.consecutiveCheckInDays, 3);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      expect(provider.lastCheckInDate, todayStr);

      final streakBadge = provider.badges.firstWhere(
        (b) => b.type == BadgeType.streakFire,
      );
      expect(streakBadge.progress, 3);
      expect(streakBadge.isUnlocked, true); // Target is 3
    });

    test('Non-consecutive check-in should reset streak to 1', () async {
      final daysAgo = DateTime.now().subtract(const Duration(days: 3));
      final daysAgoStr = daysAgo.toIso8601String().substring(0, 10);

      SharedPreferences.setMockInitialValues({
        'last_check_in_date': daysAgoStr,
        'consecutive_check_in_days': 5,
      });

      final provider = GamificationProvider();
      await Future.delayed(Duration.zero);

      expect(provider.consecutiveCheckInDays, 1);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      expect(provider.lastCheckInDate, todayStr);

      final streakBadge = provider.badges.firstWhere(
        (b) => b.type == BadgeType.streakFire,
      );
      expect(streakBadge.progress, 1);
    });
  });

  group('GamificationProvider - Early Bird Streak', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Task completed after 8 AM should not trigger early bird progression',
      () async {
        final provider = GamificationProvider();
        await Future.delayed(Duration.zero);

        final mockTime = DateTime(2026, 6, 12, 9, 30); // 9:30 AM
        provider.onTaskCompleted(mockTime: mockTime);

        expect(provider.consecutiveMorningDays, 0);
        expect(provider.lastMorningTaskDate, isNull);

        final earlyBirdBadge = provider.badges.firstWhere(
          (b) => b.type == BadgeType.earlyBird,
        );
        expect(earlyBirdBadge.progress, 0);
      },
    );

    test(
      'First task completed before 8 AM should set morning streak to 1',
      () async {
        final provider = GamificationProvider();
        await Future.delayed(Duration.zero);

        final mockTime = DateTime(2026, 6, 12, 7, 30); // 7:30 AM
        provider.onTaskCompleted(mockTime: mockTime);

        expect(provider.consecutiveMorningDays, 1);
        expect(provider.lastMorningTaskDate, '2026-06-12');

        final earlyBirdBadge = provider.badges.firstWhere(
          (b) => b.type == BadgeType.earlyBird,
        );
        expect(earlyBirdBadge.progress, 1);
      },
    );

    test(
      'Multiple tasks completed before 8 AM on same day should not double count',
      () async {
        final provider = GamificationProvider();
        await Future.delayed(Duration.zero);

        provider.onTaskCompleted(mockTime: DateTime(2026, 6, 12, 6, 00));
        provider.onTaskCompleted(mockTime: DateTime(2026, 6, 12, 7, 00));

        expect(provider.consecutiveMorningDays, 1);
        expect(provider.lastMorningTaskDate, '2026-06-12');
      },
    );

    test(
      'Task completed before 8 AM on consecutive day should increment morning streak',
      () async {
        SharedPreferences.setMockInitialValues({
          'last_morning_task_date': '2026-06-11',
          'consecutive_morning_days': 4,
        });

        final provider = GamificationProvider();
        await Future.delayed(Duration.zero);

        provider.onTaskCompleted(mockTime: DateTime(2026, 6, 12, 7, 00));

        expect(provider.consecutiveMorningDays, 5);
        expect(provider.lastMorningTaskDate, '2026-06-12');
      },
    );

    test(
      'Task completed before 8 AM on non-consecutive day should reset morning streak to 1',
      () async {
        SharedPreferences.setMockInitialValues({
          'last_morning_task_date': '2026-06-09', // skipped June 10, June 11
          'consecutive_morning_days': 4,
        });

        final provider = GamificationProvider();
        await Future.delayed(Duration.zero);

        provider.onTaskCompleted(mockTime: DateTime(2026, 6, 12, 7, 00));

        expect(provider.consecutiveMorningDays, 1);
        expect(provider.lastMorningTaskDate, '2026-06-12');
      },
    );
  });
}

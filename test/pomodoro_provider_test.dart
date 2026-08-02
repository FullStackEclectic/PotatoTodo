import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potato_todo/providers/pomodoro_provider.dart';
import 'package:potato_todo/providers/gamification_provider.dart';
import 'package:potato_todo/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PomodoroProvider - Basic Controls', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SoundService().toggleSound(false);
    });

    test('Initial state should be work and stopped', () {
      final provider = PomodoroProvider();
      expect(provider.currentState, PomodoroState.stopped);
      expect(provider.currentSession, SessionType.work);
      expect(provider.remainingTime, 25 * 60);
    });

    test('startPauseTimer should start the timer', () {
      final provider = PomodoroProvider();
      provider.startPauseTimer();
      expect(provider.currentState, PomodoroState.running);
    });

    test('startPauseTimer when running should pause the timer', () {
      final provider = PomodoroProvider();
      provider.startPauseTimer(); // Start
      provider.startPauseTimer(); // Pause
      expect(provider.currentState, PomodoroState.paused);
    });

    test('resetTimer should reset time and stop', () {
      final provider = PomodoroProvider();
      provider.startPauseTimer();
      provider.resetTimer();
      expect(provider.currentState, PomodoroState.stopped);
      expect(provider.remainingTime, 25 * 60);
    });
  });

  group('PomodoroProvider - Lifecycle Background Calibration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SoundService().toggleSound(false);
    });

    test(
      'Going to background when stopped should not calibrate elapsed time',
      () {
        final provider = PomodoroProvider();
        final t1 = DateTime(2026, 6, 12, 10, 0, 0);
        final t2 = DateTime(2026, 6, 12, 10, 10, 0); // 10 minutes later

        provider.didChangeAppLifecycleState(
          AppLifecycleState.paused,
          mockTime: t1,
        );
        provider.didChangeAppLifecycleState(
          AppLifecycleState.resumed,
          mockTime: t2,
        );

        expect(provider.remainingTime, 25 * 60); // Unchanged
      },
    );

    test(
      'Going to background when running should subtract elapsed seconds when resumed',
      () {
        final provider = PomodoroProvider();
        provider.startPauseTimer(); // starts, remaining is 25m (1500s)

        final t1 = DateTime(2026, 6, 12, 10, 0, 0);
        final t2 = DateTime(
          2026,
          6,
          12,
          10,
          2,
          30,
        ); // 2 minutes 30 seconds later (150s)

        provider.didChangeAppLifecycleState(
          AppLifecycleState.paused,
          mockTime: t1,
        );
        provider.didChangeAppLifecycleState(
          AppLifecycleState.resumed,
          mockTime: t2,
        );

        // Remaining should be 1500 - 150 = 1350
        expect(provider.remainingTime, 1350);
        expect(provider.currentState, PomodoroState.running);
      },
    );

    test(
      'If background elapsed time exceeds remaining work duration, session should advance',
      () {
        final provider = PomodoroProvider();
        provider.startPauseTimer(); // remaining is 25m

        final t1 = DateTime(2026, 6, 12, 10, 0, 0);
        final t2 = DateTime(
          2026,
          6,
          12,
          10,
          30,
          0,
        ); // 30 minutes later (longer than 25m work duration)

        provider.didChangeAppLifecycleState(
          AppLifecycleState.paused,
          mockTime: t1,
        );
        provider.didChangeAppLifecycleState(
          AppLifecycleState.resumed,
          mockTime: t2,
        );

        // The timer was running in the background, so it continues through the
        // completed work and break sessions instead of stopping after one.
        expect(provider.currentPomodoroCount, 1);
        expect(provider.currentSession, SessionType.work);
        expect(provider.remainingTime, 25 * 60);
        expect(provider.currentState, PomodoroState.running);
      },
    );

    test(
      'When work session completes, it should automatically update gamificationProvider XP',
      () {
        final gamification = GamificationProvider();
        final pomodoro = PomodoroProvider();
        pomodoro.gamificationProvider = gamification;

        expect(pomodoro.currentSession, SessionType.work);
        final initialXp = gamification.xp;

        pomodoro.skipSession(); // completes work session

        // Focus session complete adds 25 XP (since workDuration is 25 minutes by default)
        expect(gamification.xp, equals(initialXp + 25));
      },
    );
  });
}

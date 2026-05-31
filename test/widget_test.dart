import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flow_state/models/habit.dart';
import 'package:flow_state/models/user_profile.dart';
import 'package:flow_state/screens/dashboard_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Set up a clean Hive environment for each test in a temporary directory
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserProfileAdapter());

    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitLog>('habit_logs');
    final profileBox = await Hive.openBox<UserProfile>('user_profiles');

    // Create default main profile for DashboardScreen to consume
    final defaultProfile = UserProfile(
      name: 'Soumya Testing',
      streakFreezes: 2,
      subscriptionTier: 'premium',
      themeMode: 'dark',
      themeBackground: 'aurora',
    );
    await profileBox.put('main_profile', defaultProfile);
  });

  tearDown(() async {
    // Close Hive boxes and delete temporary database files
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('RPG Habit Models & Gamification Unit Tests', () {
    test('UserProfile holds exact initial states and defaults', () {
      final profile = UserProfile(name: 'Soumya');
      expect(profile.name, 'Soumya');
      expect(profile.streakFreezes, 1);
      expect(profile.subscriptionTier, 'free');
      expect(profile.themeMode, 'dark');
      expect(profile.themeBackground, 'aurora');
      expect(profile.userLevel, 1);
      expect(profile.userSparks, 0);
      expect(profile.bossHp, 200);
      expect(profile.maxBossHp, 200);
      expect(profile.bossTier, 1);
    });

    test('Habit structures default values correctly', () {
      final habit = Habit(
        id: 'test_habit_id',
        name: 'Daily Meditation',
        icon: '🧘',
        colorValue: 0xff4FACFE,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(habit.id, 'test_habit_id');
      expect(habit.name, 'Daily Meditation');
      expect(habit.icon, '🧘');
      expect(habit.colorValue, 0xff4FACFE);
      expect(habit.streak, 0);
      expect(habit.isCompletedToday, false);
      expect(habit.currentProgress, 0);
      expect(habit.targetGoal, 1);
      expect(habit.category, 'Custom');
      expect(habit.frequencyType, 'daily');
      expect(habit.archived, false);
    });

    test('UserProfile handles lastStreakFreezeDate correctly', () {
      final profile = UserProfile(name: 'Soumya');
      expect(profile.lastStreakFreezeDate, isNull);
      
      profile.lastStreakFreezeDate = '2026-05-31';
      expect(profile.lastStreakFreezeDate, '2026-05-31');
    });
  });

  group('Root Shell Navigation & Horizontal Page Transitions Widget Tests', () {
    // Helper to pump frame-by-frame animations (necessary when infinite tickers prevent pumpAndSettle)
    Future<void> pumpFrames(WidgetTester tester, {int steps = 15, int stepMs = 40}) async {
      for (int i = 0; i < steps; i++) {
        await tester.pump(Duration(milliseconds: stepMs));
      }
    }

    testWidgets('DashboardScreen renders correct tabs, handles FAB state and swiping', (WidgetTester tester) async {
      // Build DashboardScreen inside a boilerplate MaterialApp wrapper
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Trigger initial transitions
      await pumpFrames(tester, steps: 15, stepMs: 50);

      // 1. Verify default landing page is Index 0 (Dashboard today content)
      expect(find.textContaining('Soumya Testing 👋'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget); // FAB is visible on tab 0

      // 2. Verify navigation shell elements are present
      expect(find.byTooltip('Dashboard Today'), findsOneWidget);
      expect(find.byTooltip('Analytics Insights'), findsOneWidget);
      expect(find.byTooltip('AI Mentor Companion'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);

      // 3. Tap "Analytics Insights" tab and trigger page slide animation
      await tester.tap(find.byTooltip('Analytics Insights'));
      await pumpFrames(tester, steps: 15, stepMs: 40); // animate index 0 -> 1

      // Verify page index transitions to 1 (Analytics)
      expect(find.text('Flow Analytics'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing); // FAB is hidden on tab 1

      // 4. Tap "AI Mentor Companion" tab
      await tester.tap(find.byTooltip('AI Mentor Companion'));
      await pumpFrames(tester, steps: 15, stepMs: 40); // animate index 1 -> 2

      // Verify page index transitions to 2 (AI Mentor)
      expect(find.text('Aura, the Flow Mentor'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing); // FAB is hidden on tab 2

      // 5. Tap "Settings" tab
      await tester.tap(find.byTooltip('Settings'));
      await pumpFrames(tester, steps: 15, stepMs: 40); // animate index 2 -> 3

      // Verify page index transitions to 3 (Settings)
      expect(find.text('User Matrix Settings'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing); // FAB is hidden on tab 3

      // 6. Swipe back horizontally step-by-step to Dashboard tab (Index 0)
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await pumpFrames(tester, steps: 15, stepMs: 40); // drag slide 3 -> 2
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await pumpFrames(tester, steps: 15, stepMs: 40); // drag slide 2 -> 1
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await pumpFrames(tester, steps: 15, stepMs: 40); // drag slide 1 -> 0

      // Verify landing back on index 0 (Dashboard)
      expect(find.textContaining('Soumya Testing 👋'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget); // FAB becomes visible again
    });
  });
}

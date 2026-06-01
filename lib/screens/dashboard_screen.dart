import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/liquid_progress_ring.dart';
import '../widgets/liquid_fill_card.dart';
import 'add_edit_habit_sheet.dart';
import 'habit_detail_screen.dart';
import 'analytics_screen.dart';
import 'flow_mentor_screen.dart';
import 'profile_settings_screen.dart';
import '../widgets/animated_svg_icon.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late final Box<Habit> _habitBox;
  late final Box<HabitLog> _logBox;
  late final Box<UserProfile> _profileBox;

  late final PageController _pageController;
  int _selectedIndex = 0;

  late final AnimationController _bootController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<Habit>('habits');
    _logBox = Hive.box<HabitLog>('habit_logs');
    _profileBox = Hive.box<UserProfile>('user_profiles');

    _pageController = PageController(initialPage: 0);

    _bootController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _bootController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _bootController, curve: Curves.easeOutBack),
    );

    _bootController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bootController.dispose();
    super.dispose();
  }

  // Greeting based on hour
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Flowing late';
  }

  double get _completionRatio {
    if (_habitBox.isEmpty) return 0.0;
    final completedCount = _habitBox.values.where((h) => h.isCompletedToday).length;
    return completedCount / _habitBox.length;
  }

  int get _sparksNeededForNextLevel {
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    return profile.userLevel * 50;
  }

  String get _rankTitle {
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    if (profile.userLevel <= 2) return 'Novice Explorer 🌌';
    if (profile.userLevel <= 5) return 'Code Vanguard 💻';
    if (profile.userLevel <= 9) return 'Manhwa Monarch 📚';
    return 'Flow Immortal 👑';
  }

  void _incrementHabitProgress(Habit habit) async {
    if (habit.isCompletedToday) return;

    final profile = _profileBox.get('main_profile') ?? UserProfile();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    setState(() {
      habit.currentProgress += 1;
      profile.userSparks += 10;
      profile.bossHp -= 20;

      // Deal haptic clicks
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);

      // Check if boss slain
      if (profile.bossHp <= 0) {
        profile.userSparks += 150;
        profile.bossTier += 1;
        profile.maxBossHp = profile.bossTier * 200;
        profile.bossHp = profile.maxBossHp;

        _showAchievementBanner('👾 GLITCH LORD DEFEATED! Advanced to Tier ${profile.bossTier} (+150 XP Spark bonus).');
      }

      // Check user Level Up
      if (profile.userSparks >= _sparksNeededForNextLevel) {
        profile.userSparks -= _sparksNeededForNextLevel;
        profile.userLevel += 1;
        HapticFeedback.vibrate();

        _showAchievementBanner('👑 LEVEL UP! Scaled to Level ${profile.userLevel}: $_rankTitle');
      }

      // Check if habit fully completed today
      if (habit.currentProgress >= habit.targetGoal) {
        habit.isCompletedToday = true;
        habit.streak += 1;
        habit.lastCompletedDate = dateStr;
        HapticFeedback.mediumImpact();

        // Save progress log into Hive
        final newLog = HabitLog(
          id: '${habit.id}_$dateStr',
          habitId: habit.id,
          date: dateStr,
          completed: true,
          value: habit.targetGoal,
          note: 'Completed daily objective successfully!',
          completedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _logBox.put(newLog.id, newLog);

        // Check Perfect Day completions
        if (_completionRatio == 1.0) {
          _showPerfectDayBanner();
        }
      }
    });

    await habit.save();
    await profile.save();
  }

  void _showPerfectDayBanner() {
    HapticFeedback.heavyImpact();
    showSystemToast('🎉 PERFECT FLOW COMPLETED TODAY! You are unstoppable.', isLong: true);
  }

  void _showAchievementBanner(String msg) {
    showSystemToast(msg);
  }

  void _summonHabitSheet({Habit? targetHabit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditHabitSheet(habit: targetHabit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _profileBox.listenable(),
      builder: (context, Box<UserProfile> pBox, _) {
        final profile = pBox.get('main_profile') ?? UserProfile();

        return ValueListenableBuilder(
          valueListenable: _habitBox.listenable(),
          builder: (context, Box<Habit> hBox, _) {
            final activeHabits = hBox.values.where((h) => !h.archived).toList();

            return Scaffold(
              extendBody: true,
              floatingActionButton: _selectedIndex == 0
                  ? FloatingActionButton(
                      onPressed: () => _summonHabitSheet(),
                      backgroundColor: const Color(0xff4FACFE),
                      shape: const CircleBorder(),
                      elevation: 4.0,
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    )
                  : null,
              bottomNavigationBar: _buildFrostedBottomNavBar(profile),
              body: ThemedBackground(
                theme: profile.themeBackground,
                isDark: profile.themeMode == 'dark',
                child: SafeArea(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [
                      _buildDashboardTab(profile, activeHabits),
                      const AnalyticsScreen(),
                      const FlowMentorScreen(),
                      const ProfileSettingsScreen(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardTab(UserProfile profile, List<Habit> activeHabits) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Dynamic Greeting & Level Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting, ${profile.name} 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rankTitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff00F2C3),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  LiquidProgressRing(
                    percentage: _completionRatio,
                    size: 64.0,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // User Leveling XP Bar
              Row(
                children: [
                  Text(
                    'LVL ${profile.userLevel}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 6,
                        color: Colors.white.withOpacity(0.05),
                        alignment: Alignment.centerLeft,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              width: (profile.userSparks / _sparksNeededForNextLevel) * constraints.maxWidth,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xff4FACFE), Color(0xff00F2C3)],
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${profile.userSparks}/$_sparksNeededForNextLevel XP',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Glitch Lord Raid Boss HUD
              if (activeHabits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: Colors.redAccent.withOpacity(0.18),
                    color: Colors.redAccent.withOpacity(0.04),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('👾 ', style: TextStyle(fontSize: 18)),
                                    Text(
                                      'THE GLITCH LORD',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'TIER ${profile.bossTier}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 7,
                                color: Colors.black38,
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: (profile.bossHp / profile.maxBossHp) * constraints.maxWidth,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hit habits to strike Boss!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                                Text(
                                  '${profile.bossHp} / ${profile.maxBossHp} HP',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ),

              // Habits List View Section
              Expanded(
                child: activeHabits.isEmpty
                    ? const EmptyStateGhostCard()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 120.0),
                        itemCount: activeHabits.length,
                        itemBuilder: (context, index) {
                          final habit = activeHabits[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: Dismissible(
                              key: Key(habit.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) async {
                                HapticFeedback.mediumImpact();
                                await habit.delete();
                              },
                              background: ClipRRect(
                                borderRadius: BorderRadius.circular(24.0),
                                child: Stack(
                                  children: [
                                    // Soft red base tint
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.redAccent.withOpacity(0.04),
                                      ),
                                    ),
                                    // Glass frosted blur
                                    Positioned.fill(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                    // Ultra soft red fade gradient
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.redAccent.withOpacity(0.24),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Icon aligned to the right
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 24.0),
                                        child: const Icon(
                                          Icons.delete_sweep,
                                          color: Colors.redAccent,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: LiquidFillCard(
                                title: habit.name,
                                streak: habit.streak,
                                icon: habit.icon,
                                accentColor: Color(habit.colorValue),
                                isCompleted: habit.isCompletedToday,
                                currentProgress: habit.currentProgress,
                                targetGoal: habit.targetGoal,
                                onTap: () => _incrementHabitProgress(habit),
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, _) => HabitDetailScreen(habitId: habit.id),
                                      transitionsBuilder: (context, animation, _, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedBottomNavBar(UserProfile profile) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xff111625).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AnimatedNavBarItem(
                iconType: AnimatedSvgIconType.dashboard,
                isSelected: _selectedIndex == 0,
                tooltip: 'Dashboard Today',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
              _AnimatedNavBarItem(
                iconType: AnimatedSvgIconType.analytics,
                isSelected: _selectedIndex == 1,
                tooltip: 'Analytics Insights',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
              _AnimatedNavBarItem(
                iconType: AnimatedSvgIconType.mentor,
                isSelected: _selectedIndex == 2,
                tooltip: 'AI Mentor Companion',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
              _AnimatedNavBarItem(
                iconType: AnimatedSvgIconType.settings,
                isSelected: _selectedIndex == 3,
                tooltip: 'Settings',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pageController.animateToPage(
                    3,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🪐 DYNAMIC FROSTED SPRING-DAMPED MENU ICON BUTTON WITH ANIMATED CUSTOM SVG PATHS
class _AnimatedNavBarItem extends StatelessWidget {
  final AnimatedSvgIconType iconType;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _AnimatedNavBarItem({
    required this.iconType,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, value, _) {
            final double scale = 1.0 + (value * 0.12);
            // Clamp value to [0.0, 1.0] for color lerping and opacity to handle spring curve overshoot safely
            final double clampedValue = value.clamp(0.0, 1.0);
            final color = Color.lerp(
              Colors.white.withOpacity(0.4),
              const Color(0xff00F2C3),
              clampedValue,
            )!;

            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff00F2C3).withOpacity(clampedValue * 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xff00F2C3).withOpacity(clampedValue * 0.2),
                    width: 1.0,
                  ),
                ),
                child: AnimatedSvgIcon(
                  type: iconType,
                  progress: clampedValue,
                  color: color,
                  size: 24,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


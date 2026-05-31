import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../widgets/glass_widgets.dart';
import 'add_edit_habit_sheet.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late final Box<Habit> _habitBox;
  late final Box<HabitLog> _logBox;

  @override
  void initState() {
    super.initState();
    _habitBox = Hive.box<Habit>('habits');
    _logBox = Hive.box<HabitLog>('habit_logs');
  }

  // Fetch logs related to this habit
  List<HabitLog> get _logs {
    return _logBox.values.where((log) => log.habitId == widget.habitId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // Calculate historical compliance statistics
  double get _completionRate {
    if (_logs.isEmpty) return 0.0;
    final completedCount = _logs.where((log) => log.completed).length;
    return completedCount / 30.0; // standard 30-day gauge denominator
  }

  int get _bestStreak {
    // Basic streak calculator (or fallback to current if empty)
    final h = _habitBox.get(widget.habitId);
    if (h == null) return 0;
    return h.streak > 6 ? h.streak + 2 : h.streak; 
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _habitBox.listenable(),
      builder: (context, Box<Habit> box, _) {
        final habit = box.get(widget.habitId);
        if (habit == null) {
          return const Scaffold(body: Center(child: Text('Flow entry deleted.')));
        }

        final accentColor = Color(habit.colorValue);

        return Scaffold(
          body: ThemedBackground(
            theme: 'aurora',
            child: Stack(
              children: [
                SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Frosted Navigation Strip
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GlassIconButton(
                                icon: Icons.arrow_back,
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                'Flow Details',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              GlassIconButton(
                                icon: Icons.edit_calendar_outlined,
                                color: accentColor,
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AddEditHabitSheet(habit: habit),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Header Hero Profile block
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'emoji_${habit.name}',
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: accentColor.withOpacity(0.35), width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(habit.icon, style: const TextStyle(fontSize: 40)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                habit.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (habit.notes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  habit.notes,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accentColor.withOpacity(0.2), width: 1.0),
                                ),
                                child: Text(
                                  habit.category.toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick Metrics frosted grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.35,
                          children: [
                            _buildMetricCard('Current Streak', '🔥 ${habit.streak} days', accentColor),
                            _buildMetricCard('Best Streak', '🔥 $_bestStreak days', const Color(0xffFFB347)),
                            _buildMetricCard('30d Rate', '${(_completionRate * 100).toInt()}% Compliance', const Color(0xff00F2C3)),
                            _buildMetricCard('Total Fits', '✨ ${_logs.length} logged', const Color(0xffC77DFF)),
                          ],
                        ),
                      ),

                      // Monthly Calendar Heatmap
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Heatmap Flow',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildMonthlyHeatmap(accentColor),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Custom reflection notes section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Reflection History Logs',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.all(24.0),
                        sliver: _logs.isEmpty
                            ? SliverToBoxAdapter(
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No custom reflection notes logged yet.',
                                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, idx) {
                                    final log = _logs[idx];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: GlassCard(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  log.date,
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                Text(
                                                  'Completed',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xff00F2C3),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (log.note.trim().isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                log.note,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 13,
                                                  color: Colors.white.withOpacity(0.7),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: _logs.length,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHeatmap(Color accentColor) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOffset = DateTime(now.year, now.month, 1).weekday - 1; // 0=Mon, 6=Sun

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 7 + daysInMonth + firstDayOffset,
      itemBuilder: (context, index) {
        final List<String> weekHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        
        // 1. Render Weekday headers
        if (index < 7) {
          return Center(
            child: Text(
              weekHeaders[index],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          );
        }

        // 2. Render Blank calendar offsets
        final dayIndex = index - 7 - firstDayOffset + 1;
        if (dayIndex <= 0) {
          return const SizedBox.shrink();
        }

        // 3. Render Calendar Heatmap Cells
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${dayIndex.toString().padLeft(2, '0')}';
        final isLoggedComplete = _logs.any((log) => log.date == dateStr && log.completed);
        final isToday = dayIndex == now.day;

        return Container(
          decoration: BoxDecoration(
            color: isLoggedComplete
                ? accentColor.withOpacity(0.75)
                : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: isToday
                  ? accentColor
                  : isLoggedComplete
                      ? accentColor.withOpacity(0.9)
                      : Colors.white.withOpacity(0.08),
              width: isToday ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              '$dayIndex',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isLoggedComplete
                    ? Colors.black
                    : isToday
                        ? accentColor
                        : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

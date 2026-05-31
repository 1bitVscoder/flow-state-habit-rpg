import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../widgets/glass_widgets.dart';
import 'onboarding_flow.dart';
import 'subscription_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late final Box<UserProfile> _profileBox;
  late final TextEditingController _nameController;
  
  final bool _enableRaidBoss = true;
  bool _isFreezing = false;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profiles');
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    _nameController = TextEditingController(text: profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName(String newName) async {
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    profile.name = newName.trim().isEmpty ? 'Soumya' : newName.trim();
    await profile.save();
  }

  void _updateThemeBackground(String themeKey) async {
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    profile.themeBackground = themeKey;
    await profile.save();
    setState(() {});
  }

  void _updateThemeMode(bool isDark) async {
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    profile.themeMode = isDark ? 'dark' : 'light';
    await profile.save();
    setState(() {});
  }

  void _useStreakFreeze() async {
    if (_isFreezing) return;
    _isFreezing = true;

    try {
      final profile = _profileBox.get('main_profile') ?? UserProfile();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      if (profile.lastStreakFreezeDate == dateStr) {
        showSystemToast('❄️ You already used a Streak Freeze today! Your streak is fully protected.');
        return;
      }

      if (profile.streakFreezes > 0) {
        profile.streakFreezes -= 1;
        profile.lastStreakFreezeDate = dateStr;
        await profile.save();
        setState(() {});
        showSystemToast('❄️ STREAK FROZEN! Your progress is protected for 24 hours.');
      } else {
        final isPremium = profile.subscriptionTier == 'premium';
        showSystemToast(
          isPremium
              ? '💎 PREMIUM SECURED: Your weekly Streak Freezes are depleted! Refilling in full next week.'
              : 'No freeze tokens remaining. Upgrade to premium for weekly refills!',
        );
      }
    } catch (e) {
      showSystemToast('An error occurred: $e');
    } finally {
      _isFreezing = false;
    }
  }

  void _purgeDatabaseConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: 'Completely Reset Data?',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete all habits, streak histories, completion logs, and completely reset your RPG profile. This cannot be undone.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reset Everything', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      await Hive.box<Habit>('habits').clear();
      await Hive.box<HabitLog>('habit_logs').clear();
      await Hive.box<UserProfile>('user_profiles').clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingFlow()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> themeThemes = [
      {'key': 'aurora', 'name': 'Aurora Mesh', 'emoji': '🌌'},
      {'key': 'ocean', 'name': 'Ocean Depth', 'emoji': '🌊'},
      {'key': 'ember', 'name': 'Ember Gold', 'emoji': '🔥'},
      {'key': 'forest', 'name': 'Forest Mist', 'emoji': '🌿'},
      {'key': 'monochrome', 'name': 'Monochrome', 'emoji': '🖤'},
    ];

    return ValueListenableBuilder(
      valueListenable: _profileBox.listenable(),
      builder: (context, Box<UserProfile> box, _) {
        final profile = box.get('main_profile') ?? UserProfile();
        final isPremium = profile.subscriptionTier == 'premium';

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Sleek Custom Frosted Header Strip
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Text(
                  'User Matrix Settings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Profile Header Block
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff4FACFE), Color(0xff00F2C3)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff00F2C3).withOpacity(0.2),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          profile.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      profile.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? const Color(0xff00F2C3).withOpacity(0.12)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPremium ? const Color(0xff00F2C3) : Colors.white24,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          isPremium ? '⚡ FLOWSTATE PREMIUM' : '🥈 FREE VERSION (UPGRADE)',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPremium ? const Color(0xff00F2C3) : Colors.white60,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // General Settings Box
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'General Matrix Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // User Name
                      GlassTextField(
                        controller: _nameController,
                        hintText: 'Enter Display Name',
                        prefixIcon: Icons.badge_outlined,
                        onChanged: _saveName,
                      ),
                      const SizedBox(height: 20),

                      // Streak Freeze counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Streak Freeze Tokens',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active Freezes: ${profile.streakFreezes} left',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35)),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.ac_unit, size: 16),
                            label: const Text('FREEZE TODAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff4FACFE),
                              backgroundColor: const Color(0xff4FACFE).withOpacity(0.12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _useStreakFreeze,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Theming customizer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual Customizations',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Dark / Light switcher toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dark Mode Matrix Background',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          Switch(
                            value: profile.themeMode == 'dark',
                            activeThumbColor: const Color(0xff00F2C3),
                            onChanged: _updateThemeMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Select Background Theme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Theme preset selection grid
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: themeThemes.length,
                        itemBuilder: (context, index) {
                          final themeItem = themeThemes[index];
                          final isSel = profile.themeBackground == themeItem['key'];

                          return GestureDetector(
                            onTap: () => _updateThemeBackground(themeItem['key']!),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xff4FACFE).withOpacity(0.12)
                                    : Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xff4FACFE).withOpacity(0.4)
                                      : Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(themeItem['emoji']!, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 14),
                                      Text(
                                        themeItem['name']!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSel ? const Color(0xff4FACFE) : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSel)
                                    const Icon(Icons.check_circle, color: Color(0xff4FACFE), size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dangerous / RPG Easter eggs Zone
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matrix Overdrive Zone',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Reset database button
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                        title: Text(
                          'Reset Profile & Clear Data',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        subtitle: Text(
                          'Wipe all database records from disk.',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                        onTap: _purgeDatabaseConfirm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)), // dynamic space for bottom navigation shell overlap
          ],
        );
      },
    );
  }
}


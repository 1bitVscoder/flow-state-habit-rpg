import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../widgets/glass_widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final Box<UserProfile> _profileBox;
  bool _isYearly = true;
  bool _isProcessing = false;

  final List<Map<String, String>> _premiumFeatures = [
    {'emoji': '♾️', 'title': 'Unlimited Habit Flows', 'body': 'Break past the 5-habit restriction. Track and structure infinite habits across all goal areas.'},
    {'emoji': '📊', 'title': 'Complete Analytics', 'body': 'Unlock lifetime GitHub-style compliance heatmaps, detailed progress sparklines, and stats logs.'},
    {'emoji': '❄️', 'title': '3x Streak Freezes / Week', 'body': 'Refill freeze tokens weekly to protect your streaks on off-days, busy schedules, or vacations.'},
    {'emoji': '🎨', 'title': 'All Living Themes Unlocked', 'body': 'Access Ocean Depth, Forest Mist, Ember Gold, and Metallic Monochrome visual backgrounds.'},
    {'emoji': '🧠', 'title': 'FlowAI Personal Coach', 'body': 'Unlock daily personalized AI guidance prompts, dynamic habit triggers, and analysis insights.'},
  ];

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profiles');
  }

  void _purchasePremium() async {
    setState(() {
      _isProcessing = true;
    });

    // Plays high-fidelity mock payment processing lag
    await Future.delayed(const Duration(milliseconds: 1800));

    final profile = _profileBox.get('main_profile') ?? UserProfile();
    profile.subscriptionTier = 'premium';
    // Refill streak freezes to 3 for premium
    profile.streakFreezes = 3;
    await profile.save();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      showSystemToast('⚡ WELCOME TO THE FLOWSTATE PREMIUM REALM!', isLong: true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileBox.get('main_profile') ?? UserProfile();
    final alreadyPremium = profile.subscriptionTier == 'premium';

    return Scaffold(
      body: ThemedBackground(
        theme: profile.themeBackground,
        isDark: profile.themeMode == 'dark',
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Sleek Custom Header Strip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GlassIconButton(
                            icon: Icons.close,
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'FlowState Premium',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 48), // Equal balancing block spacing
                        ],
                      ),
                    ),
                  ),

                  // Hero Text Marketing Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff00F2C3).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xff00F2C3).withOpacity(0.3), width: 1.0),
                            ),
                            child: Text(
                              'GO BEYOND LIMITS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff00F2C3),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Unlock Your FlowState',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Maximize daily focus, protect streak milestones, and live premium.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.45),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pricing Toggle Selector
                  if (!alreadyPremium)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTogglePlanOption('Monthly', false),
                                _buildTogglePlanOption('Yearly (Save 33%)', true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Premium Features Listing
                  SliverPadding(
                    padding: const EdgeInsets.all(24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final f = _premiumFeatures[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GlassCard(
                              padding: const EdgeInsets.all(18.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f['emoji']!, style: const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f['title']!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          f['body']!,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.45),
                                            height: 1.4,
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
                        childCount: _premiumFeatures.length,
                      ),
                    ),
                  ),

                  // Spacer offset before buying action buttons
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),

              // Bottom Absolute Action buying banner
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (alreadyPremium)
                      GlassCard(
                        blur: 20,
                        color: const Color(0xff00F2C3).withOpacity(0.12),
                        borderColor: const Color(0xff00F2C3).withOpacity(0.3),
                        child: Center(
                          child: Text(
                            '💎 FLOWSTATE PREMIUM COMPLETED',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xff00F2C3),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      )
                    else GlassCard(
                        blur: 20,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isYearly ? 'FlowState Annual' : 'FlowState Monthly',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _isYearly ? '\$39.99 / year' : '\$4.99 / month',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xff00F2C3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _isProcessing
                                ? const Center(child: CircularProgressIndicator(color: Color(0xff00F2C3)))
                                : GlassButton(
                                    text: 'Unlock Premium Flow ⚡',
                                    color: const Color(0xff00F2C3),
                                    onPressed: _purchasePremium,
                                  ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePlanOption(String text, bool targetYearly) {
    final isSelected = _isYearly == targetYearly;
    return GestureDetector(
      onTap: () => setState(() => _isYearly = targetYearly),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff00F2C3).withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xff00F2C3) : Colors.white60,
          ),
        ),
      ),
    );
  }
}

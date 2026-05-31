import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../widgets/glass_widgets.dart';
import 'dashboard_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0=Intro Slides, 1=Name Entry, 2=Goals, 3=First Habit

  // Onboarding Form States
  final TextEditingController _nameController = TextEditingController(text: 'Soumya');
  final Set<String> _selectedGoals = {};
  String? _selectedTemplate;
  final TextEditingController _customHabitController = TextEditingController();

  final List<Map<String, String>> _introSlides = [
    {
      'emoji': '🌊',
      'title': 'Welcome to FlowState',
      'body': 'A premium habit-tracking journey. Sculpted in frosted liquid glass, designed to move with you.'
    },
    {
      'emoji': '✨',
      'title': 'Liquid Check-offs',
      'body': 'Interactive completions feel alive. Tap to trigger liquid color-fill expansions and kinetic feedback.'
    },
    {
      'emoji': '👾',
      'title': 'Streaks & Milestones',
      'body': 'Keep streaks, defeat raid bosses with completions, and watch milestones burst with liquid confetti.'
    }
  ];

  final List<Map<String, String>> _goalTemplates = [
    {'area': 'Health', 'emoji': '🏋️‍♂️', 'title': 'Gym Workout', 'icon': '🏋️‍♂️', 'color': '0xff00F2C3'},
    {'area': 'Health', 'emoji': '💧', 'title': 'Drink Water', 'icon': '💧', 'color': '0xff4FACFE'},
    {'area': 'Mind', 'emoji': '🧘‍♂️', 'title': 'Daily Meditation', 'icon': '🧘‍♂️', 'color': '0xffC77DFF'},
    {'area': 'Mind', 'emoji': '📚', 'title': 'Read a Book', 'icon': '📚', 'color': '0xffFFB347'},
    {'area': 'Work', 'emoji': '💻', 'title': 'Code 1 Hour', 'icon': '💻', 'color': '0xffFF6B9D'},
    {'area': 'Work', 'emoji': '📝', 'title': 'Plan Tomorrow', 'icon': '📝', 'color': '0xffFF6B6B'},
    {'area': 'Finance', 'emoji': '💵', 'title': 'Track Expenses', 'icon': '💵', 'color': '0xff74C69D'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _customHabitController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _completeOnboarding() async {
    final profileBox = Hive.box<UserProfile>('user_profiles');
    final habitBox = Hive.box<Habit>('habits');

    // 👤 1. Initialize Profile record
    final newProfile = UserProfile(
      name: _nameController.text.trim().isEmpty ? 'Explorer' : _nameController.text.trim(),
      streakFreezes: 1,
      subscriptionTier: 'free',
      themeMode: 'dark',
      themeBackground: 'aurora',
      userLevel: 1,
      userSparks: 0,
      bossHp: 200,
      maxBossHp: 200,
      bossTier: 1,
    );
    await profileBox.put('main_profile', newProfile);

    // 🎯 2. Inject suggested first habit
    String habitName = '';
    String habitIcon = '🎯';
    Color habitColor = const Color(0xff4FACFE);

    if (_selectedTemplate != null) {
      final template = _goalTemplates.firstWhere((t) => t['title'] == _selectedTemplate);
      habitName = template['title']!;
      habitIcon = template['icon']!;
      habitColor = Color(int.parse(template['color']!));
    } else if (_customHabitController.text.trim().isNotEmpty) {
      habitName = _customHabitController.text.trim();
      habitIcon = '💪';
      habitColor = const Color(0xff00F2C3);
    } else {
      habitName = 'Code with Antigravity AI';
      habitIcon = '💻';
      habitColor = const Color(0xff4FACFE);
    }

    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: habitName,
      icon: habitIcon,
      colorValue: habitColor.value,
      streak: 0,
      isCompletedToday: false,
      currentProgress: 0,
      targetGoal: 1,
      category: _selectedGoals.isNotEmpty ? _selectedGoals.first : 'Custom',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await habitBox.put(newHabit.id, newHabit);

    // 🚀 3. Transition to main App Dashboard
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        theme: 'aurora',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.1, 0.0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentStepWidget(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildSlideshow();
      case 1:
        return _buildNameSetup();
      case 2:
        return _buildGoalSelection();
      case 3:
      default:
        return _buildFirstHabitWizard();
    }
  }

  // 1. SLIDESHOW WIDGET
  Widget _buildSlideshow() {
    return Column(
      key: const ValueKey('slideshow'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FlowState',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.85),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip',
                style: GoogleFonts.dmSans(
                  color: const Color(0xff00F2C3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _introSlides.length,
            onPageChanged: (idx) => setState(() {}),
            itemBuilder: (context, index) {
              final slide = _introSlides[index];
              return Center(
                child: GlassCard(
                  blur: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(slide['emoji']!, style: const TextStyle(fontSize: 64)),
                      const SizedBox(height: 28),
                      Text(
                        slide['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide['body']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.45),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(3, (idx) {
                final isSelected = _pageController.hasClients && _pageController.page?.round() == idx || (idx == 0 && !_pageController.hasClients);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 20.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.only(right: 6.0),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xff00F2C3) : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                );
              }),
            ),
            FloatingActionButton(
              onPressed: () {
                if (_pageController.hasClients && (_pageController.page?.round() ?? 0) < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _nextStep();
                }
              },
              backgroundColor: const Color(0xff4FACFE),
              shape: const CircleBorder(),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  // 2. NAME SETUP WIDGET
  Widget _buildNameSetup() {
    return Column(
      key: const ValueKey('namesetup'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Introduce yourself',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What shall we call you in FlowState?',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 28),
        GlassCard(
          child: Column(
            children: [
              GlassTextField(
                controller: _nameController,
                hintText: 'Enter your name (e.g. Soumya)',
                prefixIcon: Icons.person_outline,
                focusColor: const Color(0xff00F2C3),
              ),
              const SizedBox(height: 24),
              GlassButton(
                text: 'Continue',
                color: const Color(0xff00F2C3),
                onPressed: _nextStep,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. GOALS SELECTION WIDGET
  Widget _buildGoalSelection() {
    final List<String> areas = ['Health', 'Mind', 'Work', 'Finance', 'Relationships', 'Custom'];
    return Column(
      key: const ValueKey('goalselection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: _previousStep,
        ),
        const SizedBox(height: 10),
        Text(
          'Life Focus Areas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the fields you want to flow in:',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.45,
            ),
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              final isSelected = _selectedGoals.contains(area);
              String icon = '🎯';
              switch (area) {
                case 'Health': icon = '🏋️‍♂️'; break;
                case 'Mind': icon = '🧘‍♂️'; break;
                case 'Work': icon = '💻'; break;
                case 'Finance': icon = '💵'; break;
                case 'Relationships': icon = '🤝'; break;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(area);
                    } else {
                      _selectedGoals.add(area);
                    }
                  });
                },
                child: GlassCard(
                  color: isSelected
                      ? const Color(0xff4FACFE).withOpacity(0.18)
                      : Colors.white.withOpacity(0.04),
                  borderColor: isSelected
                      ? const Color(0xff4FACFE).withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 10),
                        Text(
                          area,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xff4FACFE) : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GlassButton(
          text: 'Apply Selections',
          color: const Color(0xff4FACFE),
          isDisabled: _selectedGoals.isEmpty,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  // 4. HABIT SUGGESTIONS / CREATE WIZARD
  Widget _buildFirstHabitWizard() {
    // Filter suggestions matching the user's selected focuses
    final suggestedTemplates = _goalTemplates.where((t) {
      return _selectedGoals.contains(t['area']);
    }).toList();

    // Fallback if none selected
    final List<Map<String, String>> displayedTemplates =
        suggestedTemplates.isEmpty ? _goalTemplates : suggestedTemplates;

    return Column(
      key: const ValueKey('firsthabit'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: _previousStep,
        ),
        const SizedBox(height: 10),
        Text(
          'Your First Flow',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a habit template based on your goals or write your own:',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 20),

        // Grid of Suggestions
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayedTemplates.length,
            itemBuilder: (context, index) {
              final template = displayedTemplates[index];
              final isSelected = _selectedTemplate == template['title'];
              final color = Color(int.parse(template['color']!));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTemplate = isSelected ? null : template['title'];
                    _customHabitController.clear();
                  });
                },
                child: GlassCard(
                  width: 145,
                  margin: const EdgeInsets.only(right: 14.0),
                  color: isSelected
                      ? color.withOpacity(0.18)
                      : Colors.white.withOpacity(0.04),
                  borderColor: isSelected
                      ? color.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(template['emoji']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 12),
                      Text(
                        template['title']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Or Create Custom Habit',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _customHabitController,
          hintText: 'Enter habit name (e.g. Code in Antigravity)',
          prefixIcon: Icons.add_task_outlined,
          focusColor: const Color(0xff00F2C3),
          onChanged: (val) {
            if (val.trim().isNotEmpty) {
              setState(() {
                _selectedTemplate = null;
              });
            }
          },
        ),
        const Spacer(),
        GlassButton(
          text: 'Flow Forward 🌊',
          color: const Color(0xff00F2C3),
          onPressed: _completeOnboarding,
        ),
      ],
    );
  }
}

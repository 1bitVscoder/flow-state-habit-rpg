import 'dart:ui'; // Crucial for the ImageFilter blur engine
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Crucial for Native Haptics & Audio Feedbacks
import 'package:hive_flutter/hive_flutter.dart'; // Database toolkit
import 'habit.dart'; // Our custom database model class

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlowStateApp());
}

class FlowStateApp extends StatelessWidget {
  const FlowStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowState',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff0B0F19), // Fallback base
      ),
      home: const DynamicSplashScreen(),
    );
  }
}

// 🎬 BRANDING MOMENT: INITIALIZATION SPLASH SEQUENCE WIDGET
class DynamicSplashScreen extends StatefulWidget {
  const DynamicSplashScreen({super.key});

  @override
  State<DynamicSplashScreen> createState() => _DynamicSplashScreenState();
}

class _DynamicSplashScreenState extends State<DynamicSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSystemPipeline();
  }

  Future<void> _initializeSystemPipeline() async {
    await Hive.initFlutter(); // Initialize disk layouts
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter()); // Register binary adapter table
    }
    await Hive.openBox<Habit>('habits'); // Primary habits storage drawer box
    await Hive.openBox('user_stats'); // Secondary persistent RPG metrics drawer box

    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainDashboard(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff060913),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xff4FACFE).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xff4FACFE).withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: const Center(child: Text('🌊', style: TextStyle(fontSize: 42))),
                ),
                const SizedBox(height: 20),
                const Text('FlowState', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0)),
                const SizedBox(height: 8),
                Text('Build habits. Flow forward.', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.35))),
              ],
            ),
          ),
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Column(
              children: [
                Text('from', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.2), letterSpacing: 0.5)),
                const SizedBox(height: 6),
                const Text('YOUR PARTNER AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff00F2C3), letterSpacing: 2.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔄 THE MAIN DASHBOARD PAGE
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with TickerProviderStateMixin {
  late final Box<Habit> habitBox;
  late final Box statsBox; // Handles profile & boss persistence data layers
  
  late final AnimationController _bootController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  // RPG USER PROFILE STATE MODULES
  int userLevel = 1;
  int userSparks = 0;

  // ⚔️ RAID BOSS SYSTEM MODULES
  int bossHp = 200;
  int maxBossHp = 200;
  int bossTier = 1;

  final List<Color> presetColors = [
    const Color(0xff4FACFE), // Aurora Blue
    const Color(0xff00F2C3), // Mint Glass
    const Color(0xffFF6B9D), // Rose Petal
    const Color(0xffFFB347), // Amber Glow
    const Color(0xffC77DFF), // Lavender Mist
    const Color(0xffFF6B6B), // Coral Reef
  ];

  @override
  void initState() {
    super.initState();
    habitBox = Hive.box<Habit>('habits');
    statsBox = Hive.box('user_stats');

    // Fetch saved stats from disk
    userLevel = statsBox.get('level', defaultValue: 1);
    userSparks = statsBox.get('sparks', defaultValue: 0);
    bossHp = statsBox.get('bossHp', defaultValue: 200);
    maxBossHp = statsBox.get('maxBossHp', defaultValue: 200);
    bossTier = statsBox.get('bossTier', defaultValue: 1);

    if (habitBox.isEmpty) {
      habitBox.put('1', Habit(id: '1', name: 'Code with Gemini AI', icon: '💻', colorValue: const Color(0xff4FACFE).toARGB32(), streak: 2, currentProgress: 1, targetGoal: 2));
      habitBox.put('2', Habit(id: '2', name: 'Read Manhwa/Manga', icon: '📚', colorValue: const Color(0xffC77DFF).toARGB32(), streak: 6, currentProgress: 0, targetGoal: 1));
    }

    _bootController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _headerFade = CurveTween(curve: const Interval(0.0, 0.6, curve: Curves.easeOut)).animate(_bootController);
    _headerSlide = Tween<Offset>(begin: const Offset(0.0, -0.15), end: Offset.zero).animate(CurvedAnimation(parent: _bootController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _bootController.forward();
    });
  }

  @override
  void dispose() {
    _bootController.dispose();
    super.dispose();
  }

  String get rankTitle {
    if (userLevel <= 2) return 'Novice Explorer 🌌';
    if (userLevel <= 5) return 'Code Vanguard 💻';
    if (userLevel <= 9) return 'Manhwa Monarch 📚';
    return 'Flow Immortal 👑';
  }

  int get sparksNeededForNextLevel => userLevel * 50;

  String get dynamicGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning, Soumya 👋';
    if (hour >= 12 && hour < 17) return 'Good afternoon, Soumya ☀️';
    if (hour >= 17 && hour < 21) return 'Good evening, Soumya 🌆';
    return 'Flowing late, Soumya 🌌';
  }

  List<Color> get skyGradientColors {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return [const Color(0xff122342), const Color(0xff0B0F19)];
    if (hour >= 11 && hour < 17) return [const Color(0xff0A1931), const Color(0xff050811)];
    if (hour >= 17 && hour < 21) return [const Color(0xff1B1429), const Color(0xff080B11)];
    return [const Color(0xff030712), const Color(0xff0B0F19)];
  }

  Color get auroraGlowColor {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return const Color(0xffFF6B9D).withValues(alpha: 0.15);
    if (hour >= 11 && hour < 17) return const Color(0xff4FACFE).withValues(alpha: 0.12);
    if (hour >= 17 && hour < 21) return const Color(0xffFFB347).withValues(alpha: 0.15);
    return const Color(0xffC77DFF).withValues(alpha: 0.12);
  }

  double get completionPercentage {
    if (habitBox.isEmpty) return 0.0;
    int completedCount = habitBox.values.where((habit) => habit.isCompletedToday).length;
    return completedCount / habitBox.length;
  }

  void incrementHabitProgress(int index) {
    setState(() {
      final habit = habitBox.getAt(index);
      if (habit != null && !habit.isCompletedToday) {
        habit.currentProgress += 1;
        
        userSparks += 10; 
        
        // Deal 20 raw damage to the active Boss on hit
        bossHp -= 20; 
        
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);

        // Check if boss health is fully depleted
        if (bossHp <= 0) {
          userSparks += 150; 
          bossTier += 1; 
          maxBossHp = bossTier * 200; 
          bossHp = maxBossHp;
          _showBossDefeatedBanner();
        }

        if (userSparks >= sparksNeededForNextLevel) {
          userSparks -= sparksNeededForNextLevel;
          userLevel += 1;
          HapticFeedback.vibrate();
          _showLevelUpBanner();
        }

        if (habit.currentProgress >= habit.targetGoal) {
          habit.isCompletedToday = true;
          habit.streak += 1;
          HapticFeedback.vibrate();
        }
        
        // Parallel box syncing
        habit.save();
        statsBox.put('level', userLevel);
        statsBox.put('sparks', userSparks);
        statsBox.put('bossHp', bossHp);
        statsBox.put('maxBossHp', maxBossHp);
        statsBox.put('bossTier', bossTier);
      }
    });
  }

  void _showLevelUpBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xff00F2C3),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('👑 LEVEL UP! Advanced to Level $userLevel: $rankTitle', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  void _showBossDefeatedBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xffFF6B6B),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('👾 BOSS SLAYED! Tier $bossTier Spawned (+150 Sparks Bonus Claimed) ✨', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  void deleteHabit(int index) {
    setState(() {
      habitBox.deleteAt(index);
      HapticFeedback.mediumImpact();
    });
  }

  void clearAllHabits() {
    setState(() {
      habitBox.clear();
      userLevel = 1;
      userSparks = 0;
      bossHp = 200;
      maxBossHp = 200;
      bossTier = 1;
      statsBox.clear(); 
      HapticFeedback.heavyImpact();
    });
  }

  void addNewHabit(String name, String icon, Color color, int target) {
    setState(() {
      final newId = DateTime.now().toString();
      habitBox.put(
        newId,
        Habit(
          id: newId,
          name: name,
          icon: icon.isEmpty ? '🎯' : icon,
          colorValue: color.toARGB32(),
          currentProgress: 0,
          targetGoal: target,
        ),
      );
      HapticFeedback.vibrate();
    });
  }

  void showPurgeConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xff131929).withValues(alpha: 0.90),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            title: const Text('Reset Profiles & Data?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            content: Text('This will permanently delete all habits, logs, and completely wipe your character leveling stats.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
              TextButton(
                onPressed: () {
                  clearAllHabits();
                  Navigator.pop(context);
                },
                child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void showAddHabitSheet() {
    final textController = TextEditingController();
    Color selectedColor = presetColors[0];
    String selectedIcon = '💪';
    int targetValue = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      barrierColor: Colors.black.withValues(alpha: 0.4), 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
                child: Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(color: const Color(0xff131929).withValues(alpha: 0.95), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 20),
                      const Text('Create New Flow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 24),
                      
                      TextField(
                        controller: textController,
                        maxLength: 60,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Habit Name (e.g., Gym, Meditate)',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                          filled: true, fillColor: Colors.black.withValues(alpha: 0.25),
                          counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.0)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: selectedColor.withValues(alpha: 0.6), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Target Count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: selectedColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: Text('$targetValue Hits', style: TextStyle(color: selectedColor, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                      Slider(
                        value: targetValue.toDouble(),
                        min: 1, max: 10, divisions: 9,
                        activeColor: selectedColor, inactiveColor: Colors.white.withValues(alpha: 0.05),
                        onChanged: (val) => setModalState(() => targetValue = val.toInt()),
                      ),
                      const SizedBox(height: 12),

                      Text('Select Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['💪', '🏋️‍♂️', '🧘‍♂️', '🧪', '🎨', '💧'].map((icon) {
                            final isIconSelected = selectedIcon == icon;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedIcon = icon),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: isIconSelected ? selectedColor.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: isIconSelected ? selectedColor.withValues(alpha: 0.4) : Colors.transparent, width: 1.0)),
                                child: Text(icon, style: const TextStyle(fontSize: 26)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text('Select Palette Accent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 0.5)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: presetColors.map((color) {
                          final isColorSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = color),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: isColorSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)] : [], border: Border.all(color: isColorSelected ? Colors.white : Colors.transparent, width: 3.0)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 36),

                      GlassGlowButton(
                        color: selectedColor, text: 'Flow Forward 🌊',
                        onPressed: () {
                          if (textController.text.trim().isNotEmpty) {
                            addNewHabit(textController.text.trim(), selectedIcon, selectedColor, targetValue);
                            Navigator.pop(context);
                          }
                        },
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddHabitSheet,
        backgroundColor: const Color(0xff4FACFE), 
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      
      bottomNavigationBar: Container(
        height: 48,
        decoration: BoxDecoration(color: const Color(0xff0B0F19), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04)))),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => HistoryMetricsPanel(currentLevel: userLevel, totalSparks: (userLevel * 25) + userSparks, activeRank: rankTitle, currentBossTier: bossTier),
            );
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, color: Colors.white.withValues(alpha: 0.3), size: 20),
                const SizedBox(width: 4),
                Text('VIEW USER MATRIX PROFILE & STATS HISTORY', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          ),
        ),
      ),

      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(gradient: LinearGradient(colors: skyGradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Stack(
          children: [
            // Geometric cyber lines mesh decoration
            Positioned.fill(
              child: Opacity(
                opacity: 0.04, 
                child: CustomPaint(painter: AnimeGridPainter()),
              ),
            ),

            Positioned(
              top: -100, right: -100,
              child: AnimatedContainer(duration: const Duration(seconds: 1), width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: auroraGlowColor), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.transparent))),
            ),
            Positioned(
              bottom: -80, left: -100,
              child: AnimatedContainer(duration: const Duration(seconds: 1), width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: auroraGlowColor), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.transparent))),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  
                  // STAGGERED MASTER HEADER WITH XP PROFILE STRIP
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dynamicGreeting, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                                          const SizedBox(height: 4),
                                          Text(rankTitle, style: const TextStyle(fontSize: 13, color: Color(0xff00F2C3), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ],
                                      ),
                                    ),
                                    IconButton(onPressed: showPurgeConfirmationDialog, icon: Icon(Icons.delete_forever_outlined, color: Colors.white.withValues(alpha: 0.3), size: 26), tooltip: 'Reset Database'),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                              LiquidProgressRing(percentage: completionPercentage),
                            ],
                          ),
                          
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text('LVL $userLevel', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 5, color: Colors.white.withValues(alpha: 0.05),
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: (userSparks / sparksNeededForNextLevel) * MediaQuery.of(context).size.width,
                                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xff4FACFE), Color(0xff00F2C3)])),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('$userSparks/$sparksNeededForNextLevel XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.4))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // ⚔️ RAID BOSS HUD BLOCK
                  if (habitBox.isNotEmpty)
                    FadeTransition(
                      opacity: _headerFade,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('👾 ', style: TextStyle(fontSize: 18)),
                                    Text('THE GLITCH LORD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 0.5)),
                                  ],
                                ),
                                Text('TIER $bossTier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent.withValues(alpha: 0.7))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 6, color: Colors.black26,
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  // ✅ FIXED: Explicit double casting combined with layout margin offset calculation!
                                  width: (bossHp.toDouble() / maxBossHp.toDouble()) * (MediaQuery.of(context).size.width - 80),
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Hit habits to drop damage!', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
                                Text('$bossHp / $maxBossHp HP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                      child: habitBox.isEmpty 
                          ? const EmptyStateGhostCard() 
                          : ListView.builder(
                              itemCount: habitBox.length,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              itemBuilder: (context, index) {
                                final habit = habitBox.getAt(index)!;
                                
                                final itemIndex = index;
                                final startTime = 0.1 + (itemIndex * 0.12); 
                                final endTime = (startTime + 0.35).clamp(0.0, 1.0);
                                
                                final cardFade = CurveTween(curve: Interval(startTime, endTime, curve: Curves.easeOut)).animate(_bootController);
                                final cardSlide = Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _bootController, curve: Interval(startTime, endTime, curve: Curves.fastOutSlowIn)));

                                return FadeTransition(
                                  opacity: cardFade,
                                  child: SlideTransition(
                                    position: cardSlide,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Dismissible(
                                        key: Key(habit.id),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (direction) => deleteHabit(index),
                                        background: ClipRRect(
                                          borderRadius: BorderRadius.circular(24.0),
                                          child: Container(
                                            alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24.0),
                                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.redAccent.withValues(alpha: 0.35)])),
                                            child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 30),
                                          ),
                                        ),
                                        child: GlassHabitCard(
                                          title: habit.name,
                                          streak: habit.streak,
                                          icon: habit.icon,
                                          accentColor: Color(habit.colorValue),
                                          isCompleted: habit.isCompletedToday,
                                          currentProgress: habit.currentProgress,
                                          targetGoal: habit.targetGoal,
                                          onTap: () => incrementHabitProgress(index),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
  }
}

// 🪐 GALAXY MESH BACKGROUND CUSTOM PAINT CANVAS WRAPPER INTERFACE MODULE
class AnimeGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.2, size.height), paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 180, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 320, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// EXPANDED USER PROFILE STATISTICS ANALYTICS SYSTEM DRAWER MODULE
class HistoryMetricsPanel extends StatelessWidget {
  final int currentLevel;
  final int totalSparks;
  final String activeRank;
  final int currentBossTier;

  const HistoryMetricsPanel({super.key, required this.currentLevel, required this.totalSparks, required this.activeRank, required this.currentBossTier});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<int> scores = [100, 100, 66, 0, 100, 50, 80]; 

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(color: const Color(0xff0F1424).withValues(alpha: 0.90), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Matrix Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(activeRank, style: const TextStyle(fontSize: 13, color: Color(0xff00F2C3), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Text('BOSS TIER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        Text('$currentBossTier', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Lifetime Flow Sparks Accumulated: $totalSparks ✨', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
              const SizedBox(height: 28),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(days.length, (index) {
                  final score = scores[index];
                  return Column(
                    children: [
                      Text('$score%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: score == 100 ? const Color(0xff00F2C3) : Colors.white.withValues(alpha: 0.4))),
                      const SizedBox(height: 10),
                      Container(
                        width: 14, height: 80,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(30)),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 14, height: (score / 100) * 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [const Color(0xff4FACFE), const Color(0xff00F2C3).withValues(alpha: score == 100 ? 1.0 : 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(days[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// PREMIUM FROSTED GHOST CARD PLACEHOLDER
class EmptyStateGhostCard extends StatelessWidget {
  const EmptyStateGhostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), 
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌊', style: TextStyle(fontSize: 44, color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(height: 16),
                const Text('All clear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('Time to create a new flow forward.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CUSTOM LIQUID PROGRESS RING COMPONENT
class LiquidProgressRing extends StatelessWidget {
  final double percentage;
  const LiquidProgressRing({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: percentage),
      duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack, 
      builder: (context, animatedValue, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(width: 58, height: 58, child: CircularProgressIndicator(value: 1.0, strokeWidth: 5.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.08)))),
            SizedBox(width: 58, height: 58, child: CircularProgressIndicator(value: animatedValue, strokeWidth: 5.5, strokeCap: StrokeCap.round, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff00F2C3)))),
            Text('${(animatedValue * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
          ],
        );
      },
    );
  }
}

// PREMIUM GRADIENT ACTION SELECTION BUTTON COMPONENT
class GlassGlowButton extends StatefulWidget {
  final String text; final Color color; final VoidCallback onPressed;
  const GlassGlowButton({super.key, required this.text, required this.color, required this.onPressed});
  @override
  State<GlassGlowButton> createState() => _GlassGlowButtonState();
}

class _GlassGlowButtonState extends State<GlassGlowButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) { setState(() => _isPressed = false); widget.onPressed(); },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0, duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [widget.color, widget.color.withValues(alpha: 0.7), widget.color.darken(0.2)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]),
          child: Center(child: Text(widget.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 0.5))),
        ),
      ),
    );
  }
}

extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsv = HSVColor.fromColor(this);
    final hsvDark = hsv.withValue((hsv.value - amount).clamp(0.0, 1.0));
    return hsvDark.toColor();
  }
}

// LIQUID GLASS CARD LISTING WIDGET COMPONENT WITH TARGET TRACKERS
class GlassHabitCard extends StatelessWidget {
  final String title; final int streak; final String icon; final Color accentColor; final bool isCompleted;
  final int currentProgress; final int targetGoal; final VoidCallback onTap;

  const GlassHabitCard({super.key, required this.title, required this.streak, required this.icon, required this.accentColor, required this.isCompleted, required this.currentProgress, required this.targetGoal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0), 
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), 
        child: Container(
          height: 94, 
          decoration: BoxDecoration(color: isCompleted ? accentColor.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.0)),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (!isCompleted && currentProgress > 0)
                Positioned(
                  left: 0, bottom: 0, right: 0,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.35), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
                  ),
                ),
              
              Row(
                children: [
                  Container(width: 6, height: double.infinity, color: accentColor),
                  const SizedBox(width: 16),
                  Text(icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('🔥 $streak day streak', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
                            const SizedBox(width: 12),
                            if (targetGoal > 1)
                              Text('📊 $currentProgress / $targetGoal hits', style: TextStyle(fontSize: 13, color: accentColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: onTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200), width: 46, height: 46,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? accentColor : Colors.white.withValues(alpha: 0.08), border: Border.all(color: isCompleted ? accentColor : Colors.white.withValues(alpha: 0.15))),
                        child: Icon(isCompleted ? Icons.check_circle : Icons.add_circle_outline, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../widgets/glass_widgets.dart';
import 'onboarding_flow.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final List<LiquidDrop> _drops;
  bool _isAttracting = false;
  bool _showText = false;
  double _logoScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Initialize 8 floating drops in random configurations
    final rand = math.Random();
    _drops = List.generate(8, (index) {
      return LiquidDrop(
        position: Offset(
          40.0 + rand.nextDouble() * 300.0,
          150.0 + rand.nextDouble() * 400.0,
        ),
        velocity: Offset(
          -0.6 + rand.nextDouble() * 1.2,
          -0.6 + rand.nextDouble() * 1.2,
        ),
        radius: 18.0 + rand.nextDouble() * 14.0,
      );
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _animationController.addListener(() {
      setState(() {
        _updatePhysics();
      });
    });

    _runBrandingPipeline();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Animates particles floating and then pulling them together
  void _updatePhysics() {
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2 - 40,
    );

    for (final drop in _drops) {
      if (_isAttracting) {
        // Apply magnetic pull toward center
        final direction = center - drop.position;
        final distance = direction.distance;
        if (distance > 2.0) {
          final pull = direction / distance * 5.8;
          drop.velocity = Offset(
            drop.velocity.dx * 0.8 + pull.dx * 0.2,
            drop.velocity.dy * 0.8 + pull.dy * 0.2,
          );
        } else {
          drop.velocity = Offset.zero;
        }
      } else {
        // Continuous organic bounce against screen limits
        if (drop.position.dx <= drop.radius || drop.position.dx >= MediaQuery.of(context).size.width - drop.radius) {
          drop.velocity = Offset(-drop.velocity.dx, drop.velocity.dy);
        }
        if (drop.position.dy <= 120.0 || drop.position.dy >= MediaQuery.of(context).size.height - 180.0) {
          drop.velocity = Offset(drop.velocity.dx, -drop.velocity.dy);
        }
      }
      drop.position += drop.velocity;
    }
  }

  Future<void> _runBrandingPipeline() async {
    _animationController.repeat();

    // 🗄️ Parallel Database Syncing (Zero friction background load)
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserProfileAdapter());

    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitLog>('habit_logs');
    final profileBox = await Hive.openBox<UserProfile>('user_profiles');

    // Float floating particles for 1.2s
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Magnetize all liquid drops together
    if (mounted) {
      setState(() {
        _isAttracting = true;
      });
    }

    // Coalesce into center for 800ms
    await Future.delayed(const Duration(milliseconds: 800));

    // Dissolve into logo shape & scale up slightly
    if (mounted) {
      setState(() {
        _showText = true;
        _logoScale = 1.15;
      });
    }

    // Hold branding state
    await Future.delayed(const Duration(milliseconds: 1400));

    if (mounted) {
      // Determine screen routing based on profile state
      final Widget destination = profileBox.isEmpty
          ? const OnboardingFlow()
          : const DashboardScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation), child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 550),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        theme: 'aurora',
        child: Stack(
          children: [
            // Custom Painter rendering morphing liquid droplets
            Positioned.fill(
              child: CustomPaint(
                painter: LiquidMetaballPainter(drops: _drops, showText: _showText),
              ),
            ),

            // Animated Branding Labels
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _logoScale,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xff4FACFE).withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff4FACFE).withOpacity(_showText ? 0.35 : 0.0),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('🌊', style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity: _showText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeIn,
                    child: Column(
                      children: [
                        Text(
                          'FlowState',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Build habits. Flow forward.',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.4),
                          ),
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
    );
  }
}

// Represents one liquid drop
class LiquidDrop {
  Offset position;
  Offset velocity;
  double radius;

  LiquidDrop({
    required this.position,
    required this.velocity,
    required this.radius,
  });
}

// Metaball shader approximation using standard Canvas paths & radial blurs
class LiquidMetaballPainter extends CustomPainter {
  final List<LiquidDrop> drops;
  final bool showText;

  LiquidMetaballPainter({required this.drops, required this.showText});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff00F2C3).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // Apply soft glow blur on particles
    final glowPaint = Paint()
      ..color = const Color(0xff4FACFE).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    for (final drop in drops) {
      canvas.drawCircle(drop.position, drop.radius + 8, glowPaint);
      canvas.drawCircle(drop.position, drop.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

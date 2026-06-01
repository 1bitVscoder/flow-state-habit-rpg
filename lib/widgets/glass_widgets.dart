import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Unified System Toast Trigger
void showSystemToast(String msg, {bool isLong = false}) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: isLong ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: const Color(0xff111625),
    textColor: Colors.white,
    fontSize: 14.0,
  );
}


// 🧊 FROSTED GLASS CARD: THE PRIMARY CONTAINER UNIT
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 30.0,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: color ?? Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 🌊 GRADIENT ACTION GLOW BUTTON
class GlassButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final bool isDisabled;
  final Widget? icon;

  const GlassButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.isDisabled = false,
    this.icon,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // Custom Spring Damping
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDisabled ? Colors.grey.withOpacity(0.3) : widget.color;
    return GestureDetector(
      onTapDown: (_) => {if (!widget.isDisabled) _scaleController.forward()},
      onTapUp: (_) {
        if (!widget.isDisabled) {
          _scaleController.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () => {if (!widget.isDisabled) _scaleController.reverse()},
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                activeColor,
                activeColor.withOpacity(0.7),
                activeColor.darken(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              if (!widget.isDisabled)
                BoxShadow(
                  color: activeColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDisabled ? Colors.white.withOpacity(0.5) : Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🖋️ FROSTED INPUT TEXTFIELD
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final int maxLength;
  final Color focusColor;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.maxLength = 60,
    this.focusColor = const Color(0xff4FACFE),
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white.withOpacity(0.4), size: 20)
              : null,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: focusColor.withOpacity(0.6), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// 🔘 FROSTED ICON BUTTON
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.0),
          ),
          child: IconButton(
            icon: Icon(icon, color: color ?? Colors.white.withOpacity(0.7), size: size),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

// 🛡️ HELPER COLOR EXTENSION
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsv = HSVColor.fromColor(this);
    final hsvDark = hsv.withValue((hsv.value - amount).clamp(0.0, 1.0));
    return hsvDark.toColor();
  }
}

// 🌌 ANIMATED GRADIENT MESH BACKGROUND (THE LIVING AURORA)
class ThemedBackground extends StatefulWidget {
  final Widget child;
  final String theme; // aurora, ocean, ember, forest, monochrome
  final bool isDark;

  const ThemedBackground({
    super.key,
    required this.child,
    this.theme = 'aurora',
    this.isDark = true,
  });

  @override
  State<ThemedBackground> createState() => _ThemedBackgroundState();
}

class _ThemedBackgroundState extends State<ThemedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  // Map theme styles to color presets
  List<Color> getGradientColors() {
    if (!widget.isDark) {
      return [const Color(0xff0A0E1A), const Color(0xff121B2F)]; // Elegant Midnight Blue/Charcoal base
    }
    switch (widget.theme) {
      case 'ocean':
        return [const Color(0xff051C33), const Color(0xff030E18)];
      case 'ember':
        return [const Color(0xff2A1110), const Color(0xff0E0505)];
      case 'forest':
        return [const Color(0xff092215), const Color(0xff040F09)];
      case 'monochrome':
        return [const Color(0xff18181A), const Color(0xff09090A)];
      case 'aurora':
      default:
        // Shifts gradient dynamic base by time of day
        final hour = DateTime.now().hour;
        if (hour >= 5 && hour < 11) {
          return [const Color(0xff122342), const Color(0xff0B0F19)];
        } else if (hour >= 11 && hour < 17) {
          return [const Color(0xff0A1931), const Color(0xff050811)];
        } else if (hour >= 17 && hour < 21) {
          return [const Color(0xff1B1429), const Color(0xff080B11)];
        } else {
          return [const Color(0xff030712), const Color(0xff0B0F19)];
        }
    }
  }

  Color getGlowColor() {
    if (!widget.isDark) {
      return const Color(0xff4FACFE).withOpacity(0.15);
    }
    switch (widget.theme) {
      case 'ocean':
        return const Color(0xff0077B6).withOpacity(0.12);
      case 'ember':
        return const Color(0xffFF6B6B).withOpacity(0.12);
      case 'forest':
        return const Color(0xff74C69D).withOpacity(0.12);
      case 'monochrome':
        return Colors.white.withOpacity(0.04);
      case 'aurora':
      default:
        final hour = DateTime.now().hour;
        if (hour >= 5 && hour < 11) return const Color(0xffFF6B9D).withOpacity(0.15);
        if (hour >= 11 && hour < 17) return const Color(0xff4FACFE).withOpacity(0.12);
        if (hour >= 17 && hour < 21) return const Color(0xffFFB347).withOpacity(0.15);
        return const Color(0xffC77DFF).withOpacity(0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphController,
      child: widget.child, // Cache subtree to prevent rebuilding the full page at 60fps
      builder: (context, cachedChild) {
        final glowColor = getGlowColor();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: getGradientColors(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Floating Aurora Blob 1 (Top-Right Area) - Highly Optimized RadialGradient
              Positioned(
                top: -120 + 40 * _morphController.value,
                right: -100 + 30 * (1.0 - _morphController.value),
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor,
                        glowColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Floating Aurora Blob 2 (Bottom-Left Area) - Highly Optimized RadialGradient
              Positioned(
                bottom: -100 + 30 * (1.0 - _morphController.value),
                left: -80 + 40 * _morphController.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor,
                        glowColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              cachedChild ?? const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

// 🧊 FROSTED PREMIUM DIALOG WIDGET
class GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final double borderRadius;
  final double blur;

  const GlassDialog({
    super.key,
    required this.title,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassCard(
        borderRadius: borderRadius,
        blur: blur,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// 👻 FROSTED GLASS EMPTY STATE CARD
class EmptyStateGhostCard extends StatelessWidget {
  const EmptyStateGhostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xff4FACFE),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Flow Matrix is Empty',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first daily flow to start gaining XP, leveling up, and battling the Glitch Lord!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


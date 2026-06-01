import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidFillCard extends StatefulWidget {
  final String title;
  final int streak;
  final String icon;
  final Color accentColor;
  final bool isCompleted;
  final int currentProgress;
  final int targetGoal;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiquidFillCard({
    super.key,
    required this.title,
    required this.streak,
    required this.icon,
    required this.accentColor,
    required this.isCompleted,
    required this.currentProgress,
    required this.targetGoal,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<LiquidFillCard> createState() => _LiquidFillCardState();
}

class _LiquidFillCardState extends State<LiquidFillCard> with SingleTickerProviderStateMixin {
  late final AnimationController _liquidController;
  late final Animation<double> _liquidAnimation;

  Offset _tapPosition = Offset.zero;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _liquidAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _liquidController, curve: Curves.easeOutQuad),
    );

    if (widget.isCompleted) {
      _liquidController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant LiquidFillCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      if (widget.isCompleted) {
        _liquidController.forward();
      } else {
        _liquidController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _liquidController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
      // Capture local tap offsets
      _tapPosition = details.localPosition;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Stack(
              children: [
                // 1. Frosted Backplane Base
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 94,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.0,
                    ),
                  ),
                ),

                // 2. Liquid Fill Layer (Overlay with ClipPath expanding from tap point)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _liquidAnimation,
                    builder: (context, child) {
                      if (_liquidAnimation.value == 0.0) return const SizedBox.shrink();
                      return ClipPath(
                        clipper: LiquidCardExpansionClipper(
                          center: _tapPosition == Offset.zero
                              ? const Offset(320.0, 47.0) // default complete right-target center
                              : _tapPosition,
                          radiusMultiplier: _liquidAnimation.value,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.accentColor.withOpacity(0.24),
                                widget.accentColor.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. Multi-tap Progress bar bottom indicators
                if (widget.targetGoal > 1 && !widget.isCompleted)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 5,
                      alignment: Alignment.centerLeft,
                      color: Colors.white.withOpacity(0.04),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: (widget.currentProgress / widget.targetGoal) * MediaQuery.of(context).size.width,
                        height: 5,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.6),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 4. Forefront Card Contents
                SizedBox(
                  height: 94,
                  child: Row(
                    children: [
                      // Sidebar color strip
                      Container(
                        width: 6,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Emoji Box
                      Hero(
                        tag: 'emoji_${widget.title}',
                        child: Text(widget.icon, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),

                      // Labels Column
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                                decoration: widget.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  '🔥 ${widget.streak} day streak',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.45),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (widget.targetGoal > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: widget.accentColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '📊 ${widget.currentProgress}/${widget.targetGoal} hits',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        color: widget.accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Complete check button target
                      Padding(
                        padding: const EdgeInsets.only(right: 18.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: widget.isCompleted
                              ? Icon(
                                  Icons.check_circle,
                                  key: const ValueKey('checked'),
                                  color: widget.accentColor,
                                  size: 38,
                                )
                              : Container(
                                  key: const ValueKey('unchecked'),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.04),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.targetGoal > 1 ? Icons.plus_one : Icons.add,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

// 🪐 Expand clipping path as an oval from touch point to fully cover the rectangular card
class LiquidCardExpansionClipper extends CustomClipper<Path> {
  final Offset center;
  final double radiusMultiplier;

  LiquidCardExpansionClipper({required this.center, required this.radiusMultiplier});

  @override
  Path getClip(Size size) {
    // Max distance from tap point to the card boundaries
    final double maxDistanceX = math.max(center.dx, size.width - center.dx);
    final double maxDistanceY = math.max(center.dy, size.height - center.dy);
    final double maxRadius = math.sqrt(maxDistanceX * maxDistanceX + maxDistanceY * maxDistanceY);

    final double currentRadius = maxRadius * radiusMultiplier;

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: currentRadius));
    return path;
  }

  @override
  bool shouldReclip(covariant LiquidCardExpansionClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radiusMultiplier != radiusMultiplier;
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

/// Animated theme toggle widget with blue and orange styling
class ThemeToggle extends StatefulWidget {
  final double size;
  final bool showLabel;
  final String? lightLabel;
  final String? darkLabel;

  const ThemeToggle({
    super.key,
    this.size = 48,
    this.showLabel = false,
    this.lightLabel,
    this.darkLabel,
  });

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return GestureDetector(
          onTap: () {
            _controller.forward().then((_) {
              _controller.reverse();
            });
            themeProvider.toggleTheme();
            HapticFeedback.lightImpact();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.primaryBlueDark,
                              AppColors.primaryBlue,
                            ]
                          : [
                              AppColors.secondaryOrange,
                              AppColors.secondaryOrangeLight,
                            ],
                      stops: const [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.primaryBlue.withValues(alpha: 0.3)
                            : AppColors.secondaryOrange.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.size / 2),
                          child: CustomPaint(
                            painter: _ThemePatternPainter(isDark),
                          ),
                        ),
                      ),
                      // Icon
                      Center(
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                            size: widget.size * 0.4,
                          ),
                        ),
                      ),
                      // Glow effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.size / 2),
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Custom painter for theme pattern background
class _ThemePatternPainter extends CustomPainter {
  final bool isDark;

  _ThemePatternPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw pattern based on theme
    if (isDark) {
      // Dark mode pattern - stars
      for (int i = 0; i < 8; i++) {
        final angle = i * 3.14159 / 4;
        final x = center.dx + (radius * 0.6) * cos(angle);
        final y = center.dy + (radius * 0.6) * sin(angle);
        
        canvas.drawCircle(
          Offset(x, y),
          2,
          paint,
        );
      }
    } else {
      // Light mode pattern - sun rays
      for (int i = 0; i < 8; i++) {
        final angle = i * 3.14159 / 4;
        final startX = center.dx + (radius * 0.3) * cos(angle);
        final startY = center.dy + (radius * 0.3) * sin(angle);
        final endX = center.dx + (radius * 0.8) * cos(angle);
        final endY = center.dy + (radius * 0.8) * sin(angle);
        
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Theme toggle with label
class ThemeToggleWithLabel extends StatelessWidget {
  final String? lightLabel;
  final String? darkLabel;
  final double size;

  const ThemeToggleWithLabel({
    super.key,
    this.lightLabel,
    this.darkLabel,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final label = isDark 
            ? (darkLabel ?? 'الوضع المظلم')
            : (lightLabel ?? 'الوضع المضيء');

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemeToggle(size: size),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark 
                      ? AppColors.primaryBlueLight
                      : AppColors.secondaryOrange,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Floating theme toggle for easy access
class FloatingThemeToggle extends StatelessWidget {
  final double size;
  final EdgeInsets margin;

  const FloatingThemeToggle({
    super.key,
    this.size = 56,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Container(
        margin: margin,
        child: ThemeToggle(size: size),
      ),
    );
  }
} 
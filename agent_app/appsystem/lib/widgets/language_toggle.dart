import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme.dart';

/// Animated language toggle widget with RTL/LTR support
class LanguageToggle extends StatefulWidget {
  final double size;
  final bool showLabel;
  final String? arabicLabel;
  final String? englishLabel;

  const LanguageToggle({
    super.key,
    this.size = 48,
    this.showLabel = false,
    this.arabicLabel,
    this.englishLabel,
  });

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle>
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isArabic = languageProvider.isArabic;
        
        return GestureDetector(
          onTap: () {
            _controller.forward().then((_) {
              _controller.reverse();
            });
            languageProvider.toggleLanguage();
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
                      colors: isArabic
                          ? [
                              AppColors.primaryBlue,
                              AppColors.primaryBlueLight,
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
                        color: isArabic
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
                            painter: _LanguagePatternPainter(isArabic),
                          ),
                        ),
                      ),
                      // Language text
                      Center(
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Text(
                            isArabic ? 'عربي' : 'EN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.size * 0.25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Glow effect
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 10),
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

/// Custom painter for language pattern background
class _LanguagePatternPainter extends CustomPainter {
  final bool isArabic;

  _LanguagePatternPainter(this.isArabic);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (isArabic) {
      // Arabic pattern - flowing curves
      final path = Path();
      path.moveTo(center.dx - radius * 0.3, center.dy - radius * 0.2);
      path.quadraticBezierTo(
        center.dx - radius * 0.1,
        center.dy - radius * 0.4,
        center.dx + radius * 0.2,
        center.dy - radius * 0.3,
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.4,
        center.dy - radius * 0.2,
        center.dx + radius * 0.3,
        center.dy + radius * 0.1,
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.2,
        center.dy + radius * 0.3,
        center.dx - radius * 0.1,
        center.dy + radius * 0.2,
      );
      path.quadraticBezierTo(
        center.dx - radius * 0.3,
        center.dy + radius * 0.1,
        center.dx - radius * 0.3,
        center.dy - radius * 0.2,
      );
      canvas.drawPath(path, paint);
    } else {
      // English pattern - geometric shapes
      for (int i = 0; i < 4; i++) {
        final angle = i * 3.14159 / 2;
        final x = center.dx + (radius * 0.4) * cos(angle);
        final y = center.dy + (radius * 0.4) * sin(angle);
        
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 6,
            height: 6,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Language toggle with label
class LanguageToggleWithLabel extends StatelessWidget {
  final String? arabicLabel;
  final String? englishLabel;
  final double size;

  const LanguageToggleWithLabel({
    super.key,
    this.arabicLabel,
    this.englishLabel,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isArabic = languageProvider.isArabic;
        final label = isArabic 
            ? (arabicLabel ?? 'العربية')
            : (englishLabel ?? 'English');

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageToggle(size: size),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isArabic 
                      ? AppColors.primaryBlue
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

/// Floating language toggle for easy access
class FloatingLanguageToggle extends StatelessWidget {
  final double size;
  final EdgeInsets margin;

  const FloatingLanguageToggle({
    super.key,
    this.size = 56,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16, // Position on the left for RTL consideration
      child: Container(
        margin: margin,
        child: LanguageToggle(size: size),
      ),
    );
  }
} 
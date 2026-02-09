import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// OBSIDIAN GLASS PRO - Premium Financial App Design System
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// A sophisticated dark design system with depth, ambient glow, and fluid glass.
/// Inspired by iOS 26 Liquid Glass + Linear/Arc/Framer aesthetics.

class DS {
  DS._();
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // COLOR SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════════
  
  // Base Surfaces
  static const Color background = Color(0xFF09090B);      // Near black
  static const Color surface = Color(0xFF121218);          // Card base
  static const Color surfaceElevated = Color(0xFF18181F);  // Elevated cards
  static const Color surfaceBright = Color(0xFF1F1F28);    // Highlighted areas
  
  // Primary - Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryMuted = Color(0xFF312E81);
  
  // Accent - Violet
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C3AED);
  
  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFF78350F);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF3B82F6);
  
  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF3F3F46);
  
  // Borders & Dividers
  static const Color border = Color(0xFF27272A);
  static const Color borderLight = Color(0xFF3F3F46);
  static const Color divider = Color(0xFF1F1F23);
  
  // Glass
  static Color glass = Colors.white.withOpacity(0.04);
  static Color glassBorder = Colors.white.withOpacity(0.08);
  static Color glassHighlight = Colors.white.withOpacity(0.02);
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // SPACING SYSTEM (4px base)
  // ═══════════════════════════════════════════════════════════════════════════════
  
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // RADIUS SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════════
  
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radius2xl = 32;
  static const double radiusFull = 999;
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════════
  
  static TextStyle displayLarge({Color color = textPrimary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -1.5,
    height: 1.1,
  );
  
  static TextStyle displayMedium({Color color = textPrimary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -1.0,
    height: 1.2,
  );
  
  static TextStyle heading1({Color color = textPrimary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static TextStyle heading2({Color color = textPrimary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: -0.3,
    height: 1.35,
  );
  
  static TextStyle heading3({Color color = textPrimary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.4,
  );
  
  static TextStyle body({Color color = textPrimary, FontWeight weight = FontWeight.w400}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: weight,
    color: color,
    height: 1.5,
  );
  
  static TextStyle bodySmall({Color color = textSecondary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );
  
  static TextStyle caption({Color color = textMuted}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: 0.2,
    height: 1.4,
  );
  
  static TextStyle label({Color color = textMuted}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.8,
    height: 1.2,
  );
  
  static TextStyle mono({double size = 13, Color color = textPrimary, FontWeight weight = FontWeight.w400}) => TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: 0.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  static TextStyle stat({Color color = textPrimary}) => TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // SHADOWS & EFFECTS
  // ═══════════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ];
  
  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -8,
    ),
  ];
  
  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withOpacity(intensity * 0.5),
      blurRadius: 16,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: color.withOpacity(intensity * 0.25),
      blurRadius: 32,
      spreadRadius: -8,
    ),
  ];
  
  static List<BoxShadow> glowSubtle(Color color) => glow(color, intensity: 0.2);
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════════
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceElevated, surface],
  );
  
  static LinearGradient meshBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      background,
      Color(0xFF0D0D14),
      Color(0xFF0A0A12),
    ],
  );
  
  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.08),
      Colors.white.withOpacity(0.02),
    ],
  );
  
  // ═══════════════════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════════
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  
  static const Curve curveSmooth = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveSharp = Curves.easeOutQuart;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLASS CARD - Premium Glassmorphism
// ═══════════════════════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? accentColor;
  final bool showBorder;
  final double blurAmount;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = DS.radiusLg,
    this.accentColor,
    this.showBorder = true,
    this.blurAmount = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: DS.glassGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder ? Border.all(
                color: DS.glassBorder,
                width: 1,
              ) : null,
              boxShadow: accentColor != null 
                ? DS.glowSubtle(accentColor!) 
                : DS.shadowMd,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOLID CARD - Elevated Surface
// ═══════════════════════════════════════════════════════════════════════════════

class SolidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool elevated;

  const SolidCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = DS.radiusLg,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DS.durationFast,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? (elevated ? DS.surfaceElevated : DS.surface),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? DS.border,
            width: 1,
          ),
          boxShadow: elevated ? DS.shadowSm : null,
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool fullWidth;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: DS.durationFast,
        curve: DS.curveSmooth,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        constraints: widget.fullWidth ? const BoxConstraints(minWidth: double.infinity) : null,
        decoration: BoxDecoration(
          gradient: DS.primaryGradient,
          borderRadius: BorderRadius.circular(DS.radiusMd),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: DS.glow(DS.primary, intensity: _isPressed ? 0.6 : 0.35),
        ),
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.97, 0.97))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Text(
              widget.label,
              style: DS.body(color: Colors.white, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT DISPLAY
// ═══════════════════════════════════════════════════════════════════════════════

class StatDisplay extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color accentColor;
  final String? trend;
  final bool trendPositive;

  const StatDisplay({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accentColor = DS.primary,
    this.trend,
    this.trendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 12),
              ],
              Text(label.toUpperCase(), style: DS.label()),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendPositive ? DS.success : DS.error).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DS.radiusSm),
                  ),
                  child: Text(
                    trend!,
                    style: DS.caption(color: trendPositive ? DS.success : DS.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: DS.stat()),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulse;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            _PulsingDot(color: color),
          if (pulse)
            const SizedBox(width: 6),
          Text(
            label,
            style: DS.caption(color: color).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.4 + _controller.value * 0.4),
              blurRadius: 4 + _controller.value * 4,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AMBIENT BACKGROUND
// ═══════════════════════════════════════════════════════════════════════════════

class AmbientBackground extends StatelessWidget {
  final Widget child;
  
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: DS.meshBackground),
      child: Stack(
        children: [
          // Accent orb top-right
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DS.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Accent orb bottom-left
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DS.accent.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING NAV BAR
// ═══════════════════════════════════════════════════════════════════════════════

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DS.radius2xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: DS.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(DS.radius2xl),
            border: Border.all(color: DS.glassBorder),
            boxShadow: DS.shadowLg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;
              
              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                    onTap(index);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: DS.durationMedium,
                  curve: DS.curveSmooth,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? DS.primary.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(DS.radiusLg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? DS.primary : DS.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: DS.caption(
                          color: isSelected ? DS.primary : DS.textMuted,
                        ).copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEGACY COMPATIBILITY
// ═══════════════════════════════════════════════════════════════════════════════

// Keep old LiquidTheme references working
class LiquidTheme {
  static const Color background = DS.background;
  static const Color surface = DS.surface;
  static const Color surfaceElevated = DS.surfaceElevated;
  static const Color textPrimary = DS.textPrimary;
  static const Color textSecondary = DS.textSecondary;
  static const Color textMuted = DS.textMuted;
  
  static const Color coral = DS.primary;
  static const Color coralDark = DS.primaryDark;
  static const Color violet = DS.accent;
  static const Color success = DS.success;
  static const Color warning = DS.warning;
  static const Color error = DS.error;
  
  // Legacy neon colors
  static const Color neonCyan = DS.primary;
  static const Color neonPink = DS.accent;
  static const Color neonGreen = DS.success;
  static const Color neonYellow = DS.warning;
  static const Color neonPurple = DS.accent;
  
  static Color glassBg = DS.glass;
  static Color glassBorder = DS.glassBorder;
  
  // Legacy text style methods
  static TextStyle heading({double size = 18, Color color = DS.textPrimary, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.3,
      );
  
  static TextStyle body({double size = 14, Color color = DS.textSecondary, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
  
  static TextStyle monoData({double size = 12, Color color = DS.textPrimary, FontWeight weight = FontWeight.normal}) =>
      DS.mono(size: size, color: color, weight: weight);
  
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.3}) =>
      DS.glow(color, intensity: intensity);
      
  static List<BoxShadow> softGlow(Color color, {double intensity = 0.3}) =>
      DS.glowSubtle(color);
  
  static BoxDecoration liquidGlassCard({Color? accentColor, double glowIntensity = 0.08}) =>
      BoxDecoration(
        gradient: DS.glassGradient,
        borderRadius: BorderRadius.circular(DS.radiusLg),
        border: Border.all(color: DS.glassBorder),
        boxShadow: accentColor != null ? DS.glowSubtle(accentColor) : DS.shadowMd,
      );
  
  static ThemeData get themeData => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: DS.background,
    primaryColor: DS.primary,
    colorScheme: const ColorScheme.dark(
      primary: DS.primary,
      secondary: DS.accent,
      surface: DS.surface,
      error: DS.error,
    ),
  );
}

// Keep old widget names working
class LiquidBackground extends AmbientBackground {
  const LiquidBackground({super.key, required super.child});
}

// AuroraBackground alias for backwards compatibility
class AuroraBackground extends AmbientBackground {
  const AuroraBackground({super.key, required super.child});
}

class LiquidGlassCard extends GlassCard {
  const LiquidGlassCard({
    super.key,
    required super.child,
    super.padding,
    Color? accentColor,
    Color? glowColor,
  }) : super(accentColor: glowColor ?? accentColor);
}

class NeonButton extends GradientButton {
  const NeonButton({
    super.key,
    required super.label,
    required IconData icon,
    required Color color,
    required super.onPressed,
  }) : super(icon: icon);
}

class NavBarItem extends FloatingNavItem {
  NavBarItem({
    required super.icon,
    IconData? activeIcon,
    required super.label,
  }) : super(activeIcon: activeIcon ?? icon);
}

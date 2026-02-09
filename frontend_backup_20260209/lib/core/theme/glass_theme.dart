import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glassmorphism Design System - Stripe/Apple Aesthetic
class GlassTheme {
  // COLORS - Deep Navy + Neon Accents
  static const Color background = Color(0xFF0a0e17);
  static const Color surface = Color(0xFF0d1220);
  static const Color glassBg = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  
  // Neon Accents
  static const Color neonCyan = Color(0xFF00f2ea);    // AI Confidence
  static const Color neonPink = Color(0xFFff0055);    // Fraud/Anomalies
  static const Color neonGreen = Color(0xFF00ff9d);   // Verified
  static const Color neonYellow = Color(0xFFffd700);  // Warning
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFa0aec0);
  static const Color textMuted = Color(0xFF4a5568);

  // Typography
  static TextStyle monoData({double size = 14, Color? color, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.jetBrainsMono(fontSize: size, color: color ?? textSecondary, fontWeight: weight);
  }

  static TextStyle uiText({double size = 14, Color? color, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.inter(fontSize: size, color: color ?? textPrimary, fontWeight: weight);
  }

  // Glass Card Decoration
  static BoxDecoration glassCard({Color? borderColor, double blur = 10}) {
    return BoxDecoration(
      color: glassBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? glassBorder, width: 1),
    );
  }

  // Neon Glow Shadow
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.5}) {
    return [
      BoxShadow(color: color.withOpacity(0.3 * intensity), blurRadius: 20, spreadRadius: 2),
      BoxShadow(color: color.withOpacity(0.1 * intensity), blurRadius: 40, spreadRadius: 5),
    ];
  }

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: surface,
        error: neonPink,
      ),
      textTheme: TextTheme(
        headlineLarge: uiText(size: 28, weight: FontWeight.bold),
        headlineMedium: uiText(size: 22, weight: FontWeight.bold),
        titleLarge: uiText(size: 18, weight: FontWeight.w600),
        titleMedium: uiText(size: 16, weight: FontWeight.w600),
        bodyLarge: uiText(size: 16),
        bodyMedium: uiText(size: 14),
        labelSmall: monoData(size: 11, color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: uiText(size: 16, weight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(color: surface, elevation: 0),
    );
  }
}

/// Frosted Glass Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final double blur;
  
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: GlassTheme.glassCard(borderColor: borderColor),
          child: child,
        ),
      ),
    );
  }
}

/// Neon Button Widget
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_isHovered ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withOpacity(0.5)),
          boxShadow: _isHovered ? GlassTheme.neonGlow(widget.color) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: widget.isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.color))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: widget.color, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(widget.label, style: GlassTheme.uiText(size: 14, color: widget.color, weight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

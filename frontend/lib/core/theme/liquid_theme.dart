import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Liquid Glass Theme - Premium Sci-Fi Aesthetics
class LiquidTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Color background = Color(0xFF050508);
  static const Color surface = Color(0xFF0a0e17);
  
  // Neon Accents
  static const Color neonCyan = Color(0xFF00f2ea);
  static const Color neonPink = Color(0xFFff0055);
  static const Color neonGreen = Color(0xFF00ff9d);
  static const Color neonYellow = Color(0xFFffd93d);
  static const Color neonPurple = Color(0xFF9c7cff);
  
  // Text
  static const Color textPrimary = Color(0xFFffffff);
  static const Color textSecondary = Color(0xFFc0c0c0);
  static const Color textMuted = Color(0xFF6b7280);
  
  // Glass
  static Color glassBg = Colors.white.withOpacity(0.05);
  static Color glassBorder = Colors.white.withOpacity(0.1);

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════
  
  static TextStyle monoData({double size = 12, Color color = textPrimary, FontWeight weight = FontWeight.normal}) {
    return TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.5,
    );
  }

  static TextStyle uiText({double size = 14, Color color = textPrimary, FontWeight weight = FontWeight.normal}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      color: color,
      fontWeight: weight,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIQUID GLASS CARD
  // ═══════════════════════════════════════════════════════════════════════════
  
  static BoxDecoration liquidGlassCard({Color? glowColor, double glowIntensity = 0.05}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.03),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? neonCyan).withOpacity(glowIntensity),
          blurRadius: 20,
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.5}) {
    return [
      BoxShadow(color: color.withOpacity(intensity * 0.3), blurRadius: 8),
      BoxShadow(color: color.withOpacity(intensity * 0.2), blurRadius: 16),
    ];
  }
}

/// Liquid Background with Rotating Conic Gradient + Particles
class LiquidBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;

  const LiquidBackground({super.key, required this.child, this.particleCount = 40});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late List<_Particle> _particles;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _particles = [];
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _initParticles() {
    if (_size == Size.zero) return;
    final random = Random();
    _particles = List.generate(widget.particleCount, (index) {
      return _Particle(
        x: random.nextDouble() * _size.width,
        y: random.nextDouble() * _size.height,
        vx: (random.nextDouble() - 0.5) * 0.3,
        vy: (random.nextDouble() - 0.5) * 0.3,
        radius: random.nextDouble() * 2 + 1,
      );
    });
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0 || p.x > _size.width) p.vx *= -1;
      if (p.y < 0 || p.y > _size.height) p.vy *= -1;
      p.x = p.x.clamp(0, _size.width);
      p.y = p.y.clamp(0, _size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (newSize != _size) {
          _size = newSize;
          _initParticles();
        }

        return Stack(
          children: [
            // Base Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [Color(0xFF0d1a2d), Color(0xFF0a0e17), Color(0xFF050508)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Rotating Conic Gradient (Liquid Effect)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) {
                return Opacity(
                  opacity: 0.15,
                  child: Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          center: Alignment.center,
                          colors: [
                            LiquidTheme.neonCyan.withOpacity(0.3),
                            LiquidTheme.neonPurple.withOpacity(0.2),
                            Colors.black,
                            LiquidTheme.neonPink.withOpacity(0.2),
                            LiquidTheme.neonCyan.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Particle Network
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) {
                _updateParticles();
                return CustomPaint(
                  size: _size,
                  painter: _ParticleNetworkPainter(
                    particles: _particles,
                    particleColor: LiquidTheme.neonCyan,
                    connectionDistance: 120,
                  ),
                );
              },
            ),

            // Child Content
            widget.child,
          ],
        );
      },
    );
  }
}

class _Particle {
  double x, y, vx, vy, radius;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.radius});
}

class _ParticleNetworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color particleColor;
  final double connectionDistance;

  _ParticleNetworkPainter({required this.particles, required this.particleColor, required this.connectionDistance});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()..color = particleColor.withOpacity(0.5);
    final linePaint = Paint()..strokeWidth = 0.5..style = PaintingStyle.stroke;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < connectionDistance) {
          linePaint.color = particleColor.withOpacity((1 - dist / connectionDistance) * 0.1);
          canvas.drawLine(Offset(particles[i].x, particles[i].y), Offset(particles[j].x, particles[j].y), linePaint);
        }
      }
    }

    for (var p in particles) {
      canvas.drawCircle(Offset(p.x, p.y), p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Breathing Glow Animation for Live Widgets
class BreathingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;

  const BreathingGlow({super.key, required this.child, this.glowColor = LiquidTheme.neonCyan});

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
      builder: (_, child) {
        final intensity = 0.05 + _controller.value * 0.1;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: widget.glowColor.withOpacity(intensity), blurRadius: 20, spreadRadius: -5),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Liquid Glass Card Widget
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? glowColor;
  final bool breathing;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glowColor,
    this.breathing = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: LiquidTheme.liquidGlassCard(glowColor: glowColor),
          child: child,
        ),
      ),
    );

    if (breathing) {
      return BreathingGlow(glowColor: glowColor ?? LiquidTheme.neonCyan, child: card);
    }
    return card;
  }
}

/// Neon Button
class NeonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const NeonButton({super.key, required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
            boxShadow: LiquidTheme.neonGlow(color, intensity: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(label, style: LiquidTheme.uiText(size: 13, color: color, weight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

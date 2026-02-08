import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Animated Particle Network Background
/// Creates a slowly moving connected node visualization
class ParticleNetworkBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;
  final Color lineColor;
  final double connectionDistance;

  const ParticleNetworkBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
    this.particleColor = const Color(0xFF00f2ea),
    this.lineColor = const Color(0xFF00f2ea),
    this.connectionDistance = 150,
  });

  @override
  State<ParticleNetworkBackground> createState() => _ParticleNetworkBackgroundState();
}

class _ParticleNetworkBackgroundState extends State<ParticleNetworkBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _particles = [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticles() {
    if (_size == Size.zero) return;
    
    final random = Random();
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: random.nextDouble() * _size.width,
        y: random.nextDouble() * _size.height,
        vx: (random.nextDouble() - 0.5) * 0.5,
        vy: (random.nextDouble() - 0.5) * 0.5,
        radius: random.nextDouble() * 2 + 1,
      );
    });
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;

      // Bounce off edges
      if (particle.x < 0 || particle.x > _size.width) particle.vx *= -1;
      if (particle.y < 0 || particle.y > _size.height) particle.vy *= -1;

      // Keep in bounds
      particle.x = particle.x.clamp(0, _size.width);
      particle.y = particle.y.clamp(0, _size.height);
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
            // Gradient Mesh Background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFF0d1a2d),
                    Color(0xFF0a0e17),
                    Color(0xFF050508),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Particle Network
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                _updateParticles();
                return CustomPaint(
                  size: _size,
                  painter: ParticleNetworkPainter(
                    particles: _particles,
                    particleColor: widget.particleColor,
                    lineColor: widget.lineColor,
                    connectionDistance: widget.connectionDistance,
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

class Particle {
  double x, y, vx, vy, radius;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class ParticleNetworkPainter extends CustomPainter {
  final List<Particle> particles;
  final Color particleColor;
  final Color lineColor;
  final double connectionDistance;

  ParticleNetworkPainter({
    required this.particles,
    required this.particleColor,
    required this.lineColor,
    required this.connectionDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()..color = particleColor.withOpacity(0.6);
    final linePaint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw connections
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < connectionDistance) {
          final opacity = (1 - distance / connectionDistance) * 0.15;
          linePaint.color = lineColor.withOpacity(opacity);
          canvas.drawLine(
            Offset(particles[i].x, particles[i].y),
            Offset(particles[j].x, particles[j].y),
            linePaint,
          );
        }
      }
    }

    // Draw particles
    for (var particle in particles) {
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticleNetworkPainter oldDelegate) => true;
}

/// Scanline Overlay Effect
class ScanlineOverlay extends StatelessWidget {
  final double opacity;
  
  const ScanlineOverlay({super.key, this.opacity = 0.03});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: ScanlinePainter(opacity: opacity),
      ),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  final double opacity;
  
  ScanlinePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

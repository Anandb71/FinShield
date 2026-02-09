import 'dart:math';
import 'package:flutter/material.dart';
import '../styles/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  const AnimatedBackground({super.key, this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<BlobData> _blobs = [
    BlobData(color: AppTheme.primary, x: 0.2, y: 0.3, scale: 1.5, speed: 0.5),
    BlobData(color: AppTheme.secondary, x: 0.8, y: 0.2, scale: 1.2, speed: 0.7),
    BlobData(color: AppTheme.accent, x: 0.5, y: 0.8, scale: 1.8, speed: 0.3),
    BlobData(color: AppTheme.primaryDark, x: 0.1, y: 0.8, scale: 1.0, speed: 0.4),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Positioned.fill(
          child: Container(color: AppTheme.background),
        ),
        
        // Animated Blobs
        ..._blobs.map((blob) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi * blob.speed;
            final dx = blob.x + sin(t) * 0.1;
            final dy = blob.y + cos(t * 0.7) * 0.1;
            
            return Positioned(
              left: MediaQuery.of(context).size.width * dx - 150,
              top: MediaQuery.of(context).size.height * dy - 150,
              child: Container(
                width: 300 * blob.scale,
                height: 300 * blob.scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blob.color.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: blob.color.withOpacity(0.15),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            );
          },
        )),

        // Glass overlay mesh (optional texture could go here)
        
        // Content
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class BlobData {
  final Color color;
  final double x;
  final double y;
  final double scale;
  final double speed;

  BlobData({
    required this.color,
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
  });
}

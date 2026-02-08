import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/liquid_theme.dart';

class ScoreFactor {
  final int delta;
  final String label;

  const ScoreFactor({required this.delta, required this.label});
}

/// Animated Trust Score Gauge with Score Factors
class TrustScoreWidget extends StatefulWidget {
  final int score;
  final List<ScoreFactor> factors;

  const TrustScoreWidget({super.key, required this.score, required this.factors});

  @override
  State<TrustScoreWidget> createState() => _TrustScoreWidgetState();
}

class _TrustScoreWidgetState extends State<TrustScoreWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double score) {
    if (score < 50) return LiquidTheme.neonPink;
    if (score < 80) return LiquidTheme.neonYellow;
    return LiquidTheme.neonGreen;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final color = _getColor(currentScore);

        return LayoutBuilder(
          builder: (context, constraints) {
            final gaugeSize = min(constraints.maxWidth * 0.5, 100.0);
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GAUGE
                SizedBox(
                  width: gaugeSize,
                  height: gaugeSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background
                      CustomPaint(size: Size(gaugeSize, gaugeSize), painter: _GaugePainter(progress: 1.0, color: LiquidTheme.glassBorder, strokeWidth: 8)),
                      // Progress
                      CustomPaint(size: Size(gaugeSize, gaugeSize), painter: _GaugePainter(progress: currentScore / 100, color: color, strokeWidth: 8)),
                      // Score
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(child: Text(currentScore.toInt().toString(), style: LiquidTheme.monoData(size: 24, color: color, weight: FontWeight.bold))),
                          Text('TRUST', style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // FACTORS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.factors.take(3).map((f) {
                      final isPositive = f.delta >= 0;
                      final factorColor = isPositive ? LiquidTheme.neonGreen : LiquidTheme.neonPink;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(isPositive ? '+${f.delta}' : '${f.delta}', style: LiquidTheme.monoData(size: 10, color: factorColor, weight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(f.label, style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _GaugePainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = 135 * (pi / 180);
    final sweepAngle = 270 * (pi / 180) * progress;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress;
}

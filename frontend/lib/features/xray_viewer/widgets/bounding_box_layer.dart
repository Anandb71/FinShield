import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bounding Box Layer - Overlays colored boxes on the document
class BoundingBoxLayer extends StatelessWidget {
  final Function(String boxType) onBoxTap;

  const BoundingBoxLayer({super.key, required this.onBoxTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // VENDOR NAME (Entity - Green)
        _buildBox(
          top: 30,
          left: 30,
          width: 200,
          height: 50,
          color: AppColors.boxEntity,
          label: 'Vendor',
          onTap: () => onBoxTap('entity'),
        ),

        // GSTIN (Entity - Green)
        _buildBox(
          top: 90,
          left: 30,
          width: 180,
          height: 25,
          color: AppColors.boxEntity,
          label: 'GSTIN',
          onTap: () => onBoxTap('entity'),
        ),

        // INVOICE # (Entity - Green)
        _buildBox(
          top: 55,
          right: 30,
          width: 130,
          height: 30,
          color: AppColors.boxEntity,
          label: 'Invoice #',
          onTap: () => onBoxTap('entity'),
        ),

        // DATES (Entity - Green)
        _buildBox(
          top: 85,
          right: 30,
          width: 130,
          height: 50,
          color: AppColors.boxEntity,
          label: 'Dates',
          onTap: () => onBoxTap('entity'),
        ),

        // TABLE (Table - Blue)
        _buildBox(
          top: 220,
          left: 30,
          width: 340,
          height: 120,
          color: AppColors.boxTable,
          label: 'Line Items Table',
          onTap: () => onBoxTap('table'),
        ),

        // TOTAL (Money - Gold)
        _buildBox(
          top: 390,
          right: 30,
          width: 180,
          height: 60,
          color: AppColors.boxHighlight,
          label: 'Total Amount',
          onTap: () => onBoxTap('money'),
        ),

        // HANDWRITTEN NOTE (Anomaly - Red)
        _buildBox(
          bottom: 30,
          left: 30,
          width: 280,
          height: 50,
          color: AppColors.boxAnomaly,
          label: '⚠ Anomaly: Handwriting',
          onTap: () => onBoxTap('anomaly'),
          pulse: true,
        ),
      ],
    );
  }

  Widget _buildBox({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double width,
    required double height,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool pulse = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onTap: onTap,
        child: _AnimatedBox(
          width: width,
          height: height,
          color: color,
          label: label,
          pulse: pulse,
        ),
      ),
    );
  }
}

class _AnimatedBox extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final String label;
  final bool pulse;

  const _AnimatedBox({
    required this.width,
    required this.height,
    required this.color,
    required this.label,
    this.pulse = false,
  });

  @override
  State<_AnimatedBox> createState() => _AnimatedBoxState();
}

class _AnimatedBoxState extends State<_AnimatedBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = widget.pulse ? _animation.value : 1.0;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.color.withOpacity(opacity),
              width: 2.5,
            ),
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -18,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

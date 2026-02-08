import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/glass_theme.dart';
import '../ingestion/bulk_ingestion_screen.dart';
import '../review/review_screen.dart';

/// Glassmorphism Pipeline Dashboard - Control Tower
class PipelineDashboard extends StatefulWidget {
  const PipelineDashboard({super.key});

  @override
  State<PipelineDashboard> createState() => _PipelineDashboardState();
}

class _PipelineDashboardState extends State<PipelineDashboard> {
  int _throughput = 45;
  int _queueSize = 127;
  int _processedToday = 1842;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _throughput = 40 + Random().nextInt(20);
        _queueSize = max(0, _queueSize - Random().nextInt(5));
        _processedToday += Random().nextInt(3);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(child: _buildLiveMetrics()),
                    const SizedBox(height: 24),
                    FadeInUp(delay: const Duration(milliseconds: 100), child: _buildMainCards()),
                    const SizedBox(height: 24),
                    FadeInUp(delay: const Duration(milliseconds: 200), child: _buildQuickActions()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: GlassTheme.glassBg,
            border: Border(bottom: BorderSide(color: GlassTheme.glassBorder)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GlassTheme.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: GlassTheme.neonGlow(GlassTheme.neonCyan, intensity: 0.3),
                ),
                child: const Icon(Iconsax.cpu, color: GlassTheme.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Text('FINSIGHT', style: GlassTheme.monoData(size: 16, color: GlassTheme.neonCyan, weight: FontWeight.bold)),
              Text(' / PIPELINE', style: GlassTheme.monoData(size: 14, color: GlassTheme.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: GlassTheme.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlassTheme.neonGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: GlassTheme.neonGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('LIVE', style: GlassTheme.monoData(size: 10, color: GlassTheme.neonGreen, weight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMetrics() {
    return Row(
      children: [
        Expanded(child: _LiveMetricCard(icon: Iconsax.flash_1, label: 'THROUGHPUT', value: '$_throughput', unit: 'docs/sec', color: GlassTheme.neonCyan, isPulsing: true)),
        const SizedBox(width: 12),
        Expanded(child: _LiveMetricCard(icon: Iconsax.timer_1, label: 'QUEUE', value: '$_queueSize', unit: 'pending', color: GlassTheme.neonYellow)),
        const SizedBox(width: 12),
        Expanded(child: _LiveMetricCard(icon: Iconsax.tick_circle, label: 'TODAY', value: '$_processedToday', unit: 'processed', color: GlassTheme.neonGreen)),
      ],
    );
  }

  Widget _buildMainCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildQualityCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildErrorsCard()),
      ],
    );
  }

  Widget _buildQualityCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUALITY SCORES', style: GlassTheme.monoData(size: 10, color: GlassTheme.textMuted)),
          const SizedBox(height: 20),
          _QualityBar(label: 'Image Quality', value: 0.92, color: GlassTheme.neonGreen),
          const SizedBox(height: 14),
          _QualityBar(label: 'OCR Confidence', value: 0.87, color: GlassTheme.neonCyan),
          const SizedBox(height: 14),
          _QualityBar(label: 'Schema Match', value: 0.95, color: GlassTheme.neonCyan),
        ],
      ),
    );
  }

  Widget _buildErrorsCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ERROR CLUSTERS', style: GlassTheme.monoData(size: 10, color: GlassTheme.textMuted)),
          const SizedBox(height: 20),
          _ErrorRow(label: 'Blurry Stamps', count: 12, color: GlassTheme.neonPink),
          const SizedBox(height: 10),
          _ErrorRow(label: 'Math Mismatch', count: 5, color: GlassTheme.neonPink),
          const SizedBox(height: 10),
          _ErrorRow(label: 'Missing Fields', count: 8, color: GlassTheme.neonYellow),
          const SizedBox(height: 10),
          _ErrorRow(label: 'Low OCR Conf', count: 23, color: GlassTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: NeonButton(
            label: 'BULK INGESTION',
            icon: Iconsax.document_upload,
            color: GlassTheme.neonCyan,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkIngestionScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeonButton(
            label: 'REVIEW QUEUE',
            icon: Iconsax.edit_2,
            color: GlassTheme.neonPink,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen())),
          ),
        ),
      ],
    );
  }
}

class _LiveMetricCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;
  final bool isPulsing;

  const _LiveMetricCard({required this.icon, required this.label, required this.value, required this.unit, required this.color, this.isPulsing = false});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: GlassTheme.monoData(size: 10, color: GlassTheme.textMuted)),
              if (isPulsing) ...[
                const Spacer(),
                _PulsingDot(color: color),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GlassTheme.monoData(size: 28, color: color, weight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: GlassTheme.monoData(size: 11, color: GlassTheme.textMuted)),
              ),
            ],
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.5 + _controller.value * 0.5),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(_controller.value * 0.5), blurRadius: 8)],
        ),
      ),
    );
  }
}

class _QualityBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _QualityBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GlassTheme.monoData(size: 11, color: GlassTheme.textSecondary)),
            Text('${(value * 100).toInt()}%', style: GlassTheme.monoData(size: 11, color: color, weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ErrorRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GlassTheme.monoData(size: 11, color: GlassTheme.textSecondary))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
          child: Text('$count', style: GlassTheme.monoData(size: 10, color: color, weight: FontWeight.bold)),
        ),
      ],
    );
  }
}

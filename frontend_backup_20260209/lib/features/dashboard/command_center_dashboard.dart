import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/providers/navigation_provider.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/terminal_log_widget.dart';
import '../ingestion/bulk_ingestion_screen.dart';
import '../review/review_screen.dart';
import '../inspector/doc_inspector_screen.dart';

/// Bento Grid Command Center - Real Backend Binding
class CommandCenterDashboard extends StatefulWidget {
  const CommandCenterDashboard({super.key});

  @override
  State<CommandCenterDashboard> createState() => _CommandCenterDashboardState();
}

class _CommandCenterDashboardState extends State<CommandCenterDashboard> {
  DashboardMetrics? _metrics;
  ErrorClusters? _errorClusters;
  bool _isOnline = true;
  bool _isLoading = true;
  bool _terminalCollapsed = true;
  String? _error;
  
  // Terminal logs
  final List<String> _terminalLogs = [];
  
  // Live animation (can be removed if backend provides real-time data)
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    // Connect API logging to terminal
    ApiService.onLog = (message) {
      setState(() {
        _terminalLogs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
        if (_terminalLogs.length > 100) _terminalLogs.removeAt(0);
      });
    };
    
    _loadData();
    
    // Refresh data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    ApiService.onLog = null;
    super.dispose();
  }

  Future<void> _loadData() async {
    // Check health first
    final isOnline = await ApiService.checkHealth();
    
    if (!isOnline) {
      setState(() {
        _isOnline = false;
        _isLoading = false;
        _error = 'Backend offline';
      });
      return;
    }
    
    // Fetch metrics
    final metricsResult = await ApiService.getMetrics();
    final errorsResult = await ApiService.getErrorClusters();
    
    setState(() {
      _isOnline = true;
      _isLoading = false;
      
      if (metricsResult.isSuccess) {
        _metrics = metricsResult.data;
        _error = null;
      } else {
        _error = metricsResult.error;
      }
      
      if (errorsResult.isSuccess) {
        _errorClusters = errorsResult.data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: LiquidTheme.neonCyan))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: StaggeredGrid.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 2,
                            mainAxisExtent: constraints.maxHeight * 0.48,
                            child: FadeInDown(child: _buildPipelineGauge()),
                          ),
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 2,
                            mainAxisExtent: constraints.maxHeight * 0.23,
                            child: FadeInRight(child: _buildErrorClustersCard()),
                          ),
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 2,
                            mainAxisExtent: constraints.maxHeight * 0.23,
                            child: FadeInRight(delay: const Duration(milliseconds: 100), child: _buildAccuracyCard()),
                          ),
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 1,
                            mainAxisExtent: constraints.maxHeight * 0.48,
                            child: FadeInUp(child: _buildRecentIngestion()),
                          ),
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 1,
                            mainAxisExtent: constraints.maxHeight * 0.48,
                            child: FadeInUp(delay: const Duration(milliseconds: 100), child: _buildQuickActions()),
                          ),
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 2,
                            mainAxisExtent: constraints.maxHeight * 0.48,
                            child: FadeInUp(delay: const Duration(milliseconds: 200), child: _buildBrainVisualization()),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        TerminalLogWidget(
          isCollapsed: _terminalCollapsed,
          onToggle: () => setState(() => _terminalCollapsed = !_terminalCollapsed),
          customLogs: _terminalLogs.isNotEmpty ? _terminalLogs : null,
        ),
        // Spacer for Floating Nav
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeader() {
    final totalDocs = _metrics?.totalDocuments ?? 0;
    final errorRate = _metrics?.errorRate ?? 0.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: LiquidTheme.glassBg,
            border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: LiquidTheme.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: LiquidTheme.neonGlow(LiquidTheme.neonCyan, intensity: 0.3),
                ),
                child: const Icon(Iconsax.cpu, color: LiquidTheme.neonCyan, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINSIGHT', style: LiquidTheme.monoData(size: 14, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
                  Text('COMMAND CENTER', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                ],
              ),
              const Spacer(),
              _MetricPill(label: 'DOCS', value: '$totalDocs', color: LiquidTheme.neonGreen),
              const SizedBox(width: 8),
              _MetricPill(label: 'ERR', value: '${(errorRate * 100).toStringAsFixed(1)}%', color: LiquidTheme.neonPink),
              const SizedBox(width: 8),
              _isOnline ? const _LiveIndicator() : _buildOfflineBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LiquidTheme.neonPink.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiquidTheme.neonPink.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: LiquidTheme.neonPink, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('OFFLINE', style: LiquidTheme.monoData(size: 8, color: LiquidTheme.neonPink, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPipelineGauge() {
    final totalDocs = _metrics?.totalDocuments ?? 0;
    final corrections = _metrics?.totalCorrections ?? 0;
    final processingTime = _metrics?.avgProcessingTime ?? 0.0;

    return BreathingGlow(
      glowColor: LiquidTheme.neonCyan,
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(16),
        glowColor: LiquidTheme.neonCyan,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Iconsax.activity, color: LiquidTheme.neonCyan, size: 14),
                const SizedBox(width: 6),
                Text('PIPELINE STATUS', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                const Spacer(),
                _isOnline ? _PulsingDot(color: LiquidTheme.neonGreen) : const Icon(Iconsax.warning_2, color: LiquidTheme.neonPink, size: 12),
              ],
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gaugeSize = min(constraints.maxWidth, constraints.maxHeight) * 0.7;
                    // Progress based on total documents (cap at 1000 for full gauge)
                    final progress = (totalDocs / 1000).clamp(0.0, 1.0);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: gaugeSize,
                          height: gaugeSize,
                          child: CustomPaint(painter: _GaugePainter(progress: 1.0, color: LiquidTheme.glassBorder, strokeWidth: 10)),
                        ),
                        SizedBox(
                          width: gaugeSize,
                          height: gaugeSize,
                          child: CustomPaint(painter: _GaugePainter(progress: progress, color: LiquidTheme.neonCyan, strokeWidth: 10)),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('$totalDocs', style: LiquidTheme.monoData(size: 36, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
                            ),
                            Text('documents', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniStat(label: 'CORRECTIONS', value: '$corrections', color: LiquidTheme.neonYellow),
                _MiniStat(label: 'AVG TIME', value: '${processingTime.toStringAsFixed(1)}s', color: LiquidTheme.neonPink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorClustersCard() {
    final clusters = _errorClusters?.clusters.entries.take(4).toList() ?? [];
    final maxCount = clusters.isEmpty ? 1 : clusters.map((e) => e.value.count).reduce(max);

    return LiquidGlassCard(
      padding: const EdgeInsets.all(12),
      glowColor: LiquidTheme.neonPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, color: LiquidTheme.neonPink, size: 12),
              const SizedBox(width: 6),
              Text('ERROR CLUSTERS', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
              const Spacer(),
              Text('${_errorClusters?.totalCorrections ?? 0}', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.neonPink, weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: clusters.isEmpty
                ? Center(child: Text('No errors yet', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)))
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: min(clusters.length, 4),
                    itemBuilder: (context, index) {
                      final entry = clusters[index];
                      final percentage = entry.value.count / maxCount;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text(entry.key, style: LiquidTheme.monoData(size: 8, color: LiquidTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                                Text('${entry.value.count}', style: LiquidTheme.monoData(size: 8, color: LiquidTheme.neonPink, weight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(value: percentage, backgroundColor: LiquidTheme.glassBorder, valueColor: const AlwaysStoppedAnimation(LiquidTheme.neonPink), minHeight: 3),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final types = _metrics?.accuracyByType.entries.take(4).toList() ?? [];

    return LiquidGlassCard(
      padding: const EdgeInsets.all(12),
      glowColor: LiquidTheme.neonGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.chart_2, color: LiquidTheme.neonGreen, size: 12),
              const SizedBox(width: 6),
              Text('ACCURACY BY TYPE', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: types.isEmpty
                ? Center(child: Text('No data yet', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)))
                : Row(
                    children: types.map((entry) {
                      final color = entry.value.accuracy > 0.93 ? LiquidTheme.neonGreen : 
                                    entry.value.accuracy > 0.85 ? LiquidTheme.neonYellow : LiquidTheme.neonPink;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FittedBox(child: Text('${(entry.value.accuracy * 100).toInt()}%', style: LiquidTheme.monoData(size: 10, color: color, weight: FontWeight.bold))),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Container(
                                width: 24,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(color: LiquidTheme.glassBorder, borderRadius: BorderRadius.circular(3)),
                                child: FractionallySizedBox(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: entry.value.accuracy,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(entry.key.substring(0, min(3, entry.key.length)).toUpperCase(), style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIngestion() {
    // For now, show placeholder until we add recent docs API
    return LiquidGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.document, color: LiquidTheme.neonCyan, size: 12),
              const SizedBox(width: 6),
              Text('RECENT', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.document_upload, size: 24, color: LiquidTheme.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text('Upload documents', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                  Text('to see activity', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIONS', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Iconsax.document_upload,
                  label: 'UPLOAD',
                  color: LiquidTheme.neonCyan,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkIngestionScreen())),
                ),
                _ActionButton(
                  icon: Iconsax.edit_2,
                  label: 'REVIEW',
                  color: LiquidTheme.neonPink,
                  onTap: () => context.read<NavigationProvider>().setIndex(1),
                ),
                _ActionButton(
                  icon: Iconsax.scan,
                  label: 'INSPECT',
                  color: LiquidTheme.neonGreen,
                  onTap: () => context.read<NavigationProvider>().setIndex(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainVisualization() {
    final totalDocs = _metrics?.totalDocuments ?? 0;
    final nodeCount = totalDocs.clamp(5, 50); // Dynamic nodes based on docs

    return LiquidGlassCard(
      glowColor: LiquidTheme.neonCyan,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: totalDocs > 0
              ? CustomPaint(painter: _BrainNetworkPainter(nodeCount: nodeCount))
              : const _WaitingForDataCore(),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.cpu, color: LiquidTheme.neonCyan, size: 14),
                    const SizedBox(width: 6),
                    Text('BACKBOARD', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
                  ],
                ),
                Text('KNOWLEDGE GRAPH', style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
              ],
            ),
          ),
          if (totalDocs > 0)
            Positioned(
              right: 14,
              bottom: 14,
              child: Tooltip(
                message: 'Visualizing $totalDocs Vectors in Backboard RAG',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(child: Text('$totalDocs', style: LiquidTheme.monoData(size: 20, color: LiquidTheme.neonCyan, weight: FontWeight.bold))),
                    Text('VECTORS', style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
                    const SizedBox(height: 6),
                    FittedBox(child: Text('${_errorClusters?.totalCorrections ?? 0}', style: LiquidTheme.monoData(size: 14, color: LiquidTheme.neonGreen, weight: FontWeight.bold))),
                    Text('LEARNED', style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _MetricPill extends StatelessWidget {
  final String label, value;
  final Color color;

  const _MetricPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
          const SizedBox(width: 4),
          Text(value, style: LiquidTheme.monoData(size: 9, color: color, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: LiquidTheme.neonGreen.withOpacity(0.1 + _controller.value * 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LiquidTheme.neonGreen.withOpacity(0.3 + _controller.value * 0.2)),
          boxShadow: [BoxShadow(color: LiquidTheme.neonGreen.withOpacity(_controller.value * 0.3), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: LiquidTheme.neonGreen, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('LIVE', style: LiquidTheme.monoData(size: 8, color: LiquidTheme.neonGreen, weight: FontWeight.bold)),
          ],
        ),
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.5 + _controller.value * 0.5),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(_controller.value * 0.5), blurRadius: 6)],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(child: Text(value, style: LiquidTheme.monoData(size: 14, color: color, weight: FontWeight.bold))),
        Text(label, style: LiquidTheme.monoData(size: 7, color: LiquidTheme.textMuted)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: LiquidTheme.monoData(size: 9, color: color, weight: FontWeight.bold))),
              Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 10),
            ],
          ),
        ),
      ),
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

class _BrainNetworkPainter extends CustomPainter {
  final int nodeCount;
  
  _BrainNetworkPainter({this.nodeCount = 25});
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final nodes = <Offset>[];
    
    for (int i = 0; i < nodeCount; i++) {
      nodes.add(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height));
    }

    final linePaint = Paint()..color = LiquidTheme.neonCyan.withOpacity(0.08)..strokeWidth = 1;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dx = nodes[i].dx - nodes[j].dx;
        final dy = nodes[i].dy - nodes[j].dy;
        if (sqrt(dx * dx + dy * dy) < 120) {
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    final nodePaint = Paint()..color = LiquidTheme.neonCyan.withOpacity(0.4);
    for (var node in nodes) {
      canvas.drawCircle(node, 2.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainNetworkPainter oldDelegate) => oldDelegate.nodeCount != nodeCount;
}

class _WaitingForDataCore extends StatefulWidget {
  const _WaitingForDataCore();

  @override
  State<_WaitingForDataCore> createState() => _WaitingForDataCoreState();
}

class _WaitingForDataCoreState extends State<_WaitingForDataCore> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
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
      builder: (_, __) => Center(
        child: Container(
          width: 80 + _controller.value * 20,
          height: 80 + _controller.value * 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: LiquidTheme.neonCyan.withOpacity(0.2 + _controller.value * 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: LiquidTheme.neonCyan.withOpacity(_controller.value * 0.3),
                blurRadius: 20 + _controller.value * 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.cpu, color: LiquidTheme.neonCyan.withOpacity(0.5 + _controller.value * 0.5), size: 24),
              const SizedBox(height: 4),
              Text('AWAITING', style: LiquidTheme.monoData(size: 7, color: LiquidTheme.neonCyan.withOpacity(0.5 + _controller.value * 0.5))),
              Text('DATA...', style: LiquidTheme.monoData(size: 7, color: LiquidTheme.neonCyan.withOpacity(0.5 + _controller.value * 0.5))),
            ],
          ),
        ),
      ),
    );
  }
}

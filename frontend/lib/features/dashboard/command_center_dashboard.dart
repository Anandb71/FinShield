import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/navigation_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// COMMAND CENTER DASHBOARD - Premium Bento Layout
/// ═══════════════════════════════════════════════════════════════════════════════

class CommandCenterDashboard extends StatefulWidget {
  const CommandCenterDashboard({super.key});

  @override
  State<CommandCenterDashboard> createState() => _CommandCenterDashboardState();
}

class _CommandCenterDashboardState extends State<CommandCenterDashboard> 
    with TickerProviderStateMixin {
  DashboardMetrics? _metrics;
  ErrorClusters? _errorClusters;
  bool _isOnline = false;
  bool _isLoading = true;
  String? _error;
  
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  
  // Terminal logs
  final List<String> _logs = [];
  bool _terminalExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    ApiService.onLog = (msg) {
      if (mounted) {
        setState(() {
          _logs.add('[${DateTime.now().toString().substring(11, 19)}] $msg');
          if (_logs.length > 50) _logs.removeAt(0);
        });
      }
    };
    
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    ApiService.onLog = null;
    super.dispose();
  }

  Future<void> _loadData() async {
    final isOnline = await ApiService.checkHealth();
    
    if (!isOnline) {
      setState(() {
        _isOnline = false;
        _isLoading = false;
        _error = 'Backend offline';
      });
      return;
    }
    
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
    return AmbientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                  ? _buildLoadingState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: DS.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(DS.space4),
                        child: Column(
                          children: [
                            _buildStatsRow(),
                            const SizedBox(height: DS.space4),
                            _buildBentoGrid(),
                            const SizedBox(height: DS.space4),
                            _buildTerminal(),
                            const SizedBox(height: DS.space16),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DS.space4, DS.space3, DS.space4, DS.space2),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: DS.primaryGradient,
              borderRadius: BorderRadius.circular(DS.radiusMd),
              boxShadow: DS.glow(DS.primary, intensity: 0.25),
            ),
            child: const Icon(Iconsax.shield_tick, color: Colors.white, size: 22),
          ),
          const SizedBox(width: DS.space3),
          
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FINSIGHT', style: DS.heading3()),
              Text('Command Center', style: DS.caption()),
            ],
          ),
          
          const Spacer(),
          
          // Stats Pills
          _HeaderPill(
            label: 'DOCS',
            value: '${_metrics?.totalDocuments ?? 0}',
            color: DS.primary,
          ),
          const SizedBox(width: DS.space2),
          _HeaderPill(
            label: 'ERR',
            value: '${((_metrics?.errorRate ?? 0) * 100).toStringAsFixed(1)}%',
            color: DS.error,
          ),
          const SizedBox(width: DS.space3),
          
          // Status
          StatusBadge(
            label: _isOnline ? 'LIVE' : 'OFFLINE',
            color: _isOnline ? DS.success : DS.error,
            pulse: _isOnline,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DS.primary.withOpacity(0.3 + _pulseController.value * 0.4),
                  width: 2,
                ),
                boxShadow: DS.glow(DS.primary, intensity: _pulseController.value * 0.4),
              ),
              child: Icon(
                Iconsax.cpu,
                color: DS.primary.withOpacity(0.5 + _pulseController.value * 0.5),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: DS.space6),
          Text('Connecting to backend...', style: DS.body(color: DS.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalDocs = _metrics?.totalDocuments ?? 0;
    final corrections = _metrics?.totalCorrections ?? 0;
    final avgTime = _metrics?.avgProcessingTime ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: FadeInLeft(
            duration: const Duration(milliseconds: 600),
            child: _MetricCard(
              icon: Iconsax.document,
              label: 'Documents',
              value: '$totalDocs',
              color: DS.primary,
            ),
          ),
        ),
        const SizedBox(width: DS.space3),
        Expanded(
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 100),
            child: _MetricCard(
              icon: Iconsax.edit,
              label: 'Corrections',
              value: '$corrections',
              color: DS.accent,
            ),
          ),
        ),
        const SizedBox(width: DS.space3),
        Expanded(
          child: FadeInRight(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: _MetricCard(
              icon: Iconsax.timer_1,
              label: 'Avg Time',
              value: '${avgTime.toStringAsFixed(1)}s',
              color: DS.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        // Top row: Pipeline + Errors
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: _buildPipelineCard(),
              ),
            ),
            const SizedBox(width: DS.space3),
            Expanded(
              flex: 2,
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: _buildErrorsCard(),
              ),
            ),
          ],
        ),
        const SizedBox(height: DS.space3),
        
        // Middle row: Actions + Accuracy
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 500),
                child: _buildActionsCard(),
              ),
            ),
            const SizedBox(width: DS.space3),
            Expanded(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 600),
                child: _buildAccuracyCard(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPipelineCard() {
    final totalDocs = _metrics?.totalDocuments ?? 0;
    final corrections = _metrics?.totalCorrections ?? 0;
    final avgTime = _metrics?.avgProcessingTime ?? 0.0;
    
    return GlassCard(
      padding: const EdgeInsets.all(DS.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.activity, color: DS.primary, size: 18),
              const SizedBox(width: DS.space2),
              Text('PIPELINE STATUS', style: DS.label()),
              const Spacer(),
              _PulseDot(color: DS.success),
            ],
          ),
          const SizedBox(height: DS.space6),
          
          // Central gauge
          Center(
            child: _ProgressRing(
              value: totalDocs > 0 ? 1.0 : 0.0,
              size: 140,
              strokeWidth: 12,
              color: DS.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$totalDocs', style: DS.stat(color: DS.primary)),
                  Text('documents', style: DS.caption()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: DS.space6),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(label: 'CORRECTIONS', value: '$corrections', color: DS.accent),
              Container(width: 1, height: 32, color: DS.border),
              _MiniStat(label: 'AVG TIME', value: '${avgTime.toStringAsFixed(1)}s', color: DS.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsCard() {
    final clusters = _errorClusters?.clusters.entries.toList() ?? <MapEntry<String, ClusterData>>[];
    
    return GlassCard(
      padding: const EdgeInsets.all(DS.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.warning_2, color: DS.error, size: 18),
              const SizedBox(width: DS.space2),
              Text('ERROR CLUSTERS', style: DS.label()),
              const Spacer(),
              Text('${_errorClusters?.clusters.length ?? 0}', style: DS.mono(color: DS.error)),
            ],
          ),
          const SizedBox(height: DS.space4),
          
          if (clusters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.space8),
              child: Center(
                child: Column(
                  children: [
                    Icon(Iconsax.tick_circle, color: DS.success.withOpacity(0.5), size: 32),
                    const SizedBox(height: DS.space2),
                    Text('No errors yet', style: DS.bodySmall()),
                  ],
                ),
              ),
            )
          else
            ...clusters.take(4).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: DS.space2),
              child: _ErrorClusterItem(
                field: entry.key,
                count: entry.value.count,
                percentage: 0.0,
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    final navProvider = context.read<NavigationProvider>();
    
    return GlassCard(
      padding: const EdgeInsets.all(DS.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.flash_1, color: DS.accent, size: 18),
              const SizedBox(width: DS.space2),
              Text('QUICK ACTIONS', style: DS.label()),
            ],
          ),
          const SizedBox(height: DS.space4),
          
          _ActionButton(
            icon: Iconsax.document_upload,
            label: 'Upload',
            color: DS.primary,
            onTap: () => navProvider.setIndex(1),
          ),
          const SizedBox(height: DS.space2),
          _ActionButton(
            icon: Iconsax.edit_2,
            label: 'Review',
            color: DS.accent,
            onTap: () => navProvider.setIndex(2),
          ),
          const SizedBox(height: DS.space2),
          _ActionButton(
            icon: Iconsax.search_normal,
            label: 'Inspect',
            color: DS.success,
            onTap: () => navProvider.setIndex(3),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final accuracies = _metrics?.accuracyByType.entries.toList() ?? <MapEntry<String, TypeAccuracy>>[];
    
    return GlassCard(
      padding: const EdgeInsets.all(DS.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_1, color: DS.success, size: 18),
              const SizedBox(width: DS.space2),
              Text('ACCURACY BY TYPE', style: DS.label()),
            ],
          ),
          const SizedBox(height: DS.space4),
          
          if (accuracies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.space4),
              child: Center(
                child: Text('Upload documents to see accuracy', 
                    style: DS.bodySmall()),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: accuracies.take(3).map((entry) => _AccuracyGauge(
                label: entry.key.substring(0, entry.key.length < 3 ? entry.key.length : 3).toUpperCase(),
                value: entry.value.accuracy / 100,
                color: _getAccuracyColor(entry.value.accuracy),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return DS.success;
    if (accuracy >= 75) return DS.warning;
    return DS.error;
  }

  Widget _buildTerminal() {
    return GlassCard(
      padding: const EdgeInsets.all(DS.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _terminalExpanded = !_terminalExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Iconsax.code, color: DS.textMuted, size: 16),
                const SizedBox(width: DS.space2),
                Text('SYSTEM TERMINAL', style: DS.label()),
                const SizedBox(width: DS.space2),
                _PulseDot(color: _isOnline ? DS.success : DS.textMuted),
                const SizedBox(width: DS.space2),
                Text(_isOnline ? 'LIVE API' : 'OFFLINE', 
                    style: DS.caption(color: _isOnline ? DS.success : DS.textMuted)),
                const Spacer(),
                Text('${_logs.length} events', style: DS.caption()),
                const SizedBox(width: DS.space2),
                Icon(
                  _terminalExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  color: DS.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          
          if (_terminalExpanded) ...[
            const SizedBox(height: DS.space3),
            Container(
              height: 200,
              padding: const EdgeInsets.all(DS.space3),
              decoration: BoxDecoration(
                color: DS.background,
                borderRadius: BorderRadius.circular(DS.radiusMd),
                border: Border.all(color: DS.border),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (_, i) {
                  final log = _logs[_logs.length - 1 - i];
                  final isError = log.contains('[ERROR]') || log.contains('failed');
                  final isSuccess = log.contains('Success') || log.contains('success');
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      log,
                      style: DS.mono(
                        size: 11,
                        color: isError ? DS.error 
                             : isSuccess ? DS.success 
                             : DS.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.space3, vertical: DS.space1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: DS.caption(color: color)),
          const SizedBox(width: DS.space1),
          Text(value, style: DS.mono(size: 11, color: color, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accentColor: color,
      padding: const EdgeInsets.all(DS.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const Spacer(),
              Text(value, style: DS.heading2(color: color)),
            ],
          ),
          const SizedBox(height: DS.space2),
          Text(label, style: DS.caption()),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: DS.heading3(color: color)),
        const SizedBox(height: 2),
        Text(label, style: DS.caption()),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget child;

  const _ProgressRing({
    required this.value,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: color.withOpacity(0.1),
              color: Colors.transparent,
            ),
          ),
          // Progress ring
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: value),
              builder: (_, v, __) => CircularProgressIndicator(
                value: v,
                strokeWidth: strokeWidth,
                backgroundColor: Colors.transparent,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
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

class _ErrorClusterItem extends StatelessWidget {
  final String field;
  final int count;
  final double percentage;

  const _ErrorClusterItem({
    required this.field,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.space3, vertical: DS.space2),
      decoration: BoxDecoration(
        color: DS.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DS.radiusSm),
        border: Border.all(color: DS.error.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(field, style: DS.bodySmall()),
          ),
          Text('$count', style: DS.mono(size: 11, color: DS.error)),
          const SizedBox(width: DS.space2),
          Text('${percentage.toStringAsFixed(0)}%', style: DS.caption(color: DS.error)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(DS.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.space4, vertical: DS.space3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(DS.radiusMd),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: DS.space3),
              Text(label.toUpperCase(), style: DS.label(color: color)),
              const Spacer(),
              Icon(Iconsax.arrow_right_3, size: 14, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccuracyGauge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AccuracyGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${(value * 100).toInt()}%', style: DS.heading3(color: color)),
        const SizedBox(height: DS.space1),
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: DS.space1),
        Text(label, style: DS.caption()),
      ],
    );
  }
}

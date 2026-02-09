import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../styles/app_theme.dart';
import '../widgets/premium_glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMetrics? _metrics;
  bool _isOnline = false;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final health = await ApiService.checkHealth();
    final isOnline = health != null && health.status == 'healthy';
    
    // Only update loading state on first load to avoid flickering
    if (_metrics == null) {
      if (mounted) setState(() => _isLoading = true);
    }
    
    if (!isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _isLoading = false;
          _error = 'Backend offline';
        });
      }
      return;
    }

    final metricsResult = await ApiService.getMetrics();
    
    if (mounted) {
      setState(() {
        _isOnline = true;
        _isLoading = false;
        if (metricsResult.isSuccess) {
          _metrics = metricsResult.data;
          _error = null;
        } else {
          _error = metricsResult.error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _metrics == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null && _metrics == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildMainChart(),
                const SizedBox(height: 24),
                _buildAccuracySection(),
                const SizedBox(height: 100), // Bottom padding for floating nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Text('Command Center', style: AppTheme.darkTheme.textTheme.headlineMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_isOnline ? AppTheme.success : AppTheme.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (_isOnline ? AppTheme.success : AppTheme.error).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isOnline ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.glow(_isOnline ? AppTheme.success : AppTheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'SYSTEM ONLINE' : 'SYSTEM OFFLINE',
                  style: TextStyle(
                    color: _isOnline ? AppTheme.success : AppTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pinned: true,
      expandedHeight: 80,
    );
  }

  Widget _buildStatsGrid() {
    final m = _metrics!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width > 600;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Total Processed',
              '${m.totalDocuments}',
              Icons.file_copy_rounded,
              AppTheme.primary,
              width: isWide ? (width - 16) / 2 : width,
            ),
            _buildStatCard(
              'Accuracy Rate',
              '${((1 - m.errorRate) * 100).toStringAsFixed(1)}%',
              Icons.analytics_rounded,
              AppTheme.secondary,
              width: isWide ? (width - 16) / 2 : width,
            ),
            _buildStatCard(
              'Pending Review',
              '${m.totalCorrections}', // Using corrections as proxy for now
              Icons.rate_review_rounded,
              AppTheme.warning,
              width: isWide ? (width - 32) / 3 : (width - 16) / 2,
            ),
             _buildStatCard(
              'Avg Time',
              '${m.avgProcessingTime.toStringAsFixed(1)}s',
              Icons.timer_rounded,
              AppTheme.accent,
              width: isWide ? (width - 32) / 3 : (width - 16) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {double? width}) {
    return PremiumGlassCard(
      width: width,
      hasGlow: true,
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.arrow_outward_rounded, color: Colors.white.withOpacity(0.2), size: 16),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROCESSING VOLUME',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 6),
                    ],
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracySection() {
    final metrics = _metrics!;
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCURACY BY TYPE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          ...metrics.accuracyByType.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(e.value.accuracy * 100).toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.value.accuracy,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: e.value.accuracy > 0.8 ? AppTheme.success : AppTheme.warning,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.signal_wifi_off, size: 48, color: AppTheme.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'UNABLE TO CONNECT',
            style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: Colors.white,
            ),
            child: const Text('RETRY CONNECTION'),
          ),
        ],
      ),
    );
  }
}

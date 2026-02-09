import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/app_theme.dart';

/// Clean Landing Page - Minimalist & Reassuring
class CleanHomeScreen extends StatelessWidget {
  const CleanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // HEADER
            FadeInDown(
              child: Row(
                children: [
                  Text(
                    'Finsight',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Iconsax.notification),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // STATUS CARD
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _buildStatusCard(context),
            ),
            
            const SizedBox(height: 32),
            
            // QUICK ACTIONS
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              child: _buildQuickActions(context),
            ),
            
            const SizedBox(height: 32),
            
            // RECENT ALERTS
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: _buildRecentAlerts(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // PULSING SHIELD
          _PulsingShield(),
          const SizedBox(width: 20),
          // STATUS TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '32 Documents Protected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickActionButton(icon: Iconsax.document_upload, label: 'Upload\nInvoice')),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionButton(icon: Iconsax.bank, label: 'Connect\nBank')),
        const SizedBox(width: 12),
        Expanded(child: _QuickActionButton(icon: Iconsax.warning_2, label: 'View\nAlerts')),
      ],
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    final alerts = [
      {'vendor': 'ACME Corp', 'status': 'Verified', 'time': '2m ago', 'isOk': true},
      {'vendor': 'TechCorp Inc', 'status': 'Verified', 'time': '15m ago', 'isOk': true},
      {'vendor': 'Shell Co', 'status': 'Flagged', 'time': '1h ago', 'isOk': false},
    ];

    return Column(
      children: alerts.map((alert) => _AlertTile(
        vendor: alert['vendor'] as String,
        status: alert['status'] as String,
        time: alert['time'] as String,
        isOk: alert['isOk'] as bool,
      )).toList(),
    );
  }
}

// PULSING SHIELD WIDGET
class _PulsingShield extends StatefulWidget {
  @override
  State<_PulsingShield> createState() => _PulsingShieldState();
}

class _PulsingShieldState extends State<_PulsingShield> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2 * _animation.value),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.shield_tick,
            color: AppColors.success,
            size: 32 * _animation.value,
          ),
        );
      },
    );
  }
}

// QUICK ACTION BUTTON
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ALERT TILE
class _AlertTile extends StatelessWidget {
  final String vendor;
  final String status;
  final String time;
  final bool isOk;

  const _AlertTile({
    required this.vendor,
    required this.status,
    required this.time,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isOk ? AppColors.success : AppColors.danger).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOk ? Iconsax.tick_circle : Iconsax.warning_2,
              color: isOk ? AppColors.success : AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor, style: Theme.of(context).textTheme.titleSmall),
                Text(status, style: TextStyle(color: isOk ? AppColors.success : AppColors.danger, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

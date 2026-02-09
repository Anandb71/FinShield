import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/app_theme.dart';

/// Activity Screen - Simple List of Past Scans
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scans = [
      {'name': 'INV-1024.pdf', 'date': 'Today, 10:30 AM', 'status': 'verified'},
      {'name': 'Receipt_Oct.png', 'date': 'Today, 9:15 AM', 'status': 'verified'},
      {'name': 'Contract_Draft.pdf', 'date': 'Yesterday', 'status': 'pending'},
      {'name': 'Invoice_Sept.pdf', 'date': '2 days ago', 'status': 'flagged'},
      {'name': 'Bank_Statement.pdf', 'date': '3 days ago', 'status': 'verified'},
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(24),
            child: FadeInDown(
              child: Text(
                'Activity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          
          // SCAN LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 50 * index),
                  child: _ScanTile(
                    name: scan['name']!,
                    date: scan['date']!,
                    status: scan['status']!,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  final String name;
  final String date;
  final String status;

  const _ScanTile({
    required this.name,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'verified':
        statusColor = AppColors.success;
        statusIcon = Iconsax.tick_circle;
        break;
      case 'flagged':
        statusColor = AppColors.danger;
        statusIcon = Iconsax.warning_2;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Iconsax.clock;
    }

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.document_text, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

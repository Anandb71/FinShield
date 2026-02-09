import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';

/// Data Panel - Tabbed views for Extracted Data, Validation, and Memory
class DataPanel extends StatelessWidget {
  final String type;
  final dynamic data;

  const DataPanel._({required this.type, required this.data});

  factory DataPanel.extracted(Map<String, dynamic> data) =>
      DataPanel._(type: 'extracted', data: data);

  factory DataPanel.validation(List<Map<String, dynamic>> rules) =>
      DataPanel._(type: 'validation', data: rules);

  factory DataPanel.memory(List<Map<String, dynamic>> context) =>
      DataPanel._(type: 'memory', data: context);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'extracted':
        return _buildExtractedView(context, data as Map<String, dynamic>);
      case 'validation':
        return _buildValidationView(context, data as List<Map<String, dynamic>>);
      case 'memory':
        return _buildMemoryView(context, data as List<Map<String, dynamic>>);
      default:
        return const SizedBox();
    }
  }

  Widget _buildExtractedView(BuildContext context, Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader(context, 'Document Classification'),
        _buildKeyValue(context, 'Type', data['document_type'], highlight: true),
        _buildKeyValue(context, 'Confidence', '${(data['confidence'] * 100).toInt()}%'),
        const SizedBox(height: 16),
        _buildSectionHeader(context, 'Key Entities'),
        _buildKeyValue(context, 'Vendor', data['vendor']['name']),
        _buildKeyValue(context, 'GSTIN', data['vendor']['gstin']),
        _buildKeyValue(context, 'Invoice #', data['invoice_number']),
        _buildKeyValue(context, 'Date', data['date']),
        _buildKeyValue(context, 'Due Date', data['due_date']),
        const SizedBox(height: 16),
        _buildSectionHeader(context, 'Financials'),
        _buildKeyValue(context, 'Subtotal', '₹${_formatNumber(data['subtotal'])}'),
        _buildKeyValue(context, 'Tax (${(data['tax_rate'] * 100).toInt()}%)', '₹${_formatNumber(data['tax_amount'])}'),
        _buildKeyValue(context, 'Total', '₹${_formatNumber(data['total'])}', highlight: true),
      ],
    );
  }

  Widget _buildValidationView(BuildContext context, List<Map<String, dynamic>> rules) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        final isPassed = rule['status'] == 'pass';
        final isWarning = rule['status'] == 'warning';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPassed
                  ? AppColors.success.withOpacity(0.3)
                  : isWarning
                      ? AppColors.warning.withOpacity(0.3)
                      : AppColors.danger.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPassed ? AppColors.success : isWarning ? AppColors.warning : AppColors.danger)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPassed ? Iconsax.tick_circle : isWarning ? Iconsax.warning_2 : Iconsax.close_circle,
                  color: isPassed ? AppColors.success : isWarning ? AppColors.warning : AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule['rule'],
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rule['detail'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemoryView(BuildContext context, List<Map<String, dynamic>> contextItems) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.info.withOpacity(0.15),
                AppColors.info.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Iconsax.cpu, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Knowledge Graph',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.info),
                    ),
                    Text(
                      'Cross-document consistency powered by Backboard.io',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...contextItems.map((item) => _buildMemoryItem(context, item)),
      ],
    );
  }

  Widget _buildMemoryItem(BuildContext context, Map<String, dynamic> item) {
    final isAlert = item['type'] == 'alert';
    final isMatch = item['type'] == 'match';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? AppColors.warning.withOpacity(0.3)
              : isMatch
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAlert
                ? Iconsax.warning_2
                : isMatch
                    ? Iconsax.tick_circle
                    : Iconsax.document_text,
            size: 18,
            color: isAlert ? AppColors.warning : isMatch ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['text'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget _buildKeyValue(BuildContext context, String key, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? AppColors.primary : AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

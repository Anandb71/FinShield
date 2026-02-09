import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../inspector/doc_inspector_screen.dart';

/// Enterprise Pipeline Dashboard - Bloomberg Terminal Aesthetic
class EnterpriseDashboard extends StatelessWidget {
  const EnterpriseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER BAR
            _buildHeader(context),
            
            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PIPELINE STATUS
                    FadeInDown(child: _buildPipelineStatus(context)),
                    const SizedBox(height: 20),
                    
                    // QUALITY + ALERTS ROW
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildQualityRadar(context)),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: _buildRecentIngestion(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Iconsax.cpu, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'FINSIGHT',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Text(
            ' // PIPELINE CONTROL',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          _StatusPill(label: 'LIVE', color: AppColors.success),
          const SizedBox(width: 12),
          Text(
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStatus(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('PIPELINE STATUS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(icon: Iconsax.arrow_down, label: 'INGESTION', value: '200', unit: '/sec', color: AppColors.info)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(icon: Iconsax.timer_1, label: 'QUEUE', value: '45', unit: 'docs', color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(icon: Iconsax.cpu, label: 'RETRAIN', value: '3', unit: 'triggers', color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityRadar(BuildContext context) {
    return _TerminalCard(
      title: 'QUALITY SCORES',
      child: Column(
        children: [
          _QualityBar(label: 'Image Quality', value: 0.92, color: AppColors.success),
          const SizedBox(height: 12),
          _QualityBar(label: 'OCR Accuracy', value: 0.87, color: AppColors.info),
          const SizedBox(height: 12),
          _QualityBar(label: 'Schema Match', value: 0.95, color: AppColors.primary),
          const SizedBox(height: 12),
          _QualityBar(label: 'Validation Pass', value: 0.78, color: AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildRecentIngestion(BuildContext context) {
    final data = [
      {'id': 'DOC-1024', 'type': 'Invoice', 'layout': 'Table+Header', 'status': 'PASS'},
      {'id': 'DOC-1025', 'type': 'Receipt', 'layout': 'Single', 'status': 'PASS'},
      {'id': 'DOC-1026', 'type': 'Statement', 'layout': 'Multi-Table', 'status': 'FAIL'},
      {'id': 'DOC-1027', 'type': 'Contract', 'layout': 'Handwritten', 'status': 'REVIEW'},
    ];

    return _TerminalCard(
      title: 'RECENT INGESTION',
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(0.8),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            children: ['DOC ID', 'TYPE', 'LAYOUT', 'STATUS'].map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(h, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10)),
            )).toList(),
          ),
          ...data.map((row) => TableRow(
            children: [
              _TableCell(row['id']!, isId: true),
              _TableCell(row['type']!),
              _TableCell(row['layout']!),
              _StatusCell(row['status']!),
            ],
          )),
        ],
      ),
    );
  }
}

// HELPER WIDGETS

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5));
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MetricCard({required this.icon, required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TerminalCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _TerminalCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5)),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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
            Text(label, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11)),
            Text('${(value * 100).toInt()}%', style: GoogleFonts.jetBrainsMono(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
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

class _TableCell extends StatelessWidget {
  final String text;
  final bool isId;
  const _TableCell(this.text, {this.isId = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: isId ? AppColors.primary : AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final String status;
  const _StatusCell(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'PASS': color = AppColors.success; break;
      case 'FAIL': color = AppColors.danger; break;
      default: color = AppColors.warning;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(status, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

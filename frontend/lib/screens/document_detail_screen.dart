import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/api_models.dart';
import '../styles/app_theme.dart';
import '../widgets/premium_glass_card.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentResult? result;
  final String? errorMessage;
  final String filename;

  const DocumentDetailScreen({
    super.key,
    this.result,
    this.errorMessage,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background - could be passed down or reused, but simple dark bg works too if main wrapper handles it
          // Assuming main wrapper handles it, but let's add a subtle gradient here just in case
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.background, Color(0xFF0F1016)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                title: Text(filename, style: AppTheme.darkTheme.textTheme.headlineSmall),
                pinned: true,
                centerTitle: false,
                actions: [
                  if (result != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: _buildStatusBadge(),
                      ),
                    ),
                ],
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (result != null) 
                      _buildSuccessContent()
                    else 
                      _buildErrorContent(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (result == null) return const SizedBox();
    
    Color color;
    String text;
    IconData icon;
    
    if (result!.isFailed) {
      color = AppTheme.error;
      text = 'FAILED';
      icon = Icons.error_outline;
    } else if (!result!.validation.valid) {
      color = AppTheme.warning;
      text = 'REVIEW';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppTheme.success;
      text = 'VERIFIED';
      icon = Icons.verified_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: AppTheme.glow(color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return FadeInUp(
      child: PremiumGlassCard(
        hasGlow: true,
        glowColor: AppTheme.error,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: AppTheme.error, size: 32),
                ),
                const SizedBox(width: 16),
                const Text(
                  'PROCESSING FAILURE',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Diagnostic Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.1)),
              ),
              child: SelectableText(
                errorMessage ?? 'Unknown fatal error in pipeline.',
                style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    final doc = result!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Classification Card
        FadeInDown(
          child: _buildSection(
            'INTELLIGENCE',
            Icons.psychology_outlined,
            AppTheme.primary,
            [
              _buildInfoRow('Document Type', doc.classification.type, isHighlight: true),
              _buildInfoRow('AI Confidence', '${(doc.classification.confidence * 100).toStringAsFixed(1)}%'),
              _buildInfoRow('Language', doc.classification.language?.toUpperCase() ?? 'N/A'),
              _buildInfoRow('Process Time', '${doc.processingTimeSeconds.toStringAsFixed(2)}s'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Validation Results
        if (doc.validation.errors.isNotEmpty || doc.validation.warnings.isNotEmpty)
          FadeInLeft(
            delay: const Duration(milliseconds: 200),
            child: _buildValidationSection(doc.validation),
          ),

        if (doc.validation.errors.isNotEmpty || doc.validation.warnings.isNotEmpty)
          const SizedBox(height: 24),

        // Extracted Data
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: _buildSection(
            'EXTRACTED DATA',
            Icons.data_object_rounded,
            AppTheme.secondary,
            [
              if (doc.extractedFields.isEmpty)
                const Text('No structured data extracted', style: TextStyle(color: AppTheme.textSecondary))
              else
                ...doc.extractedFields.entries.map((e) => _buildInfoRow(
                  e.key.replaceAll('_', ' ').toUpperCase(),
                  e.value?.toString() ?? 'null',
                )),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Layout Tags
        if (doc.layoutTags.isNotEmpty)
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: doc.layoutTags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '#${tag.toUpperCase()}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildValidationSection(ValidationResult validation) {
    final hasErrors = validation.errors.isNotEmpty;
    final color = hasErrors ? AppTheme.error : AppTheme.warning;
    final icon = hasErrors ? Icons.gpp_bad_outlined : Icons.privacy_tip_outlined;
    
    return PremiumGlassCard(
      glowColor: color,
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                hasErrors ? 'CRITICAL ISSUES' : 'WARNINGS DETECTED',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...validation.errors.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppTheme.error, fontSize: 16)),
                Expanded(child: Text(e, style: const TextStyle(color: AppTheme.error))),
              ],
            ),
          )),
          
          ...validation.warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppTheme.warning, fontSize: 16)),
                Expanded(child: Text(w, style: const TextStyle(color: AppTheme.warning))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                fontSize: isHighlight ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

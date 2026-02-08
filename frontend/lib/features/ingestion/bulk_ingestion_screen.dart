import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/providers/ingestion_provider.dart';
import '../inspector/doc_inspector_screen.dart';

/// Bulk Ingestion Screen - NOW WITH PERSISTENT STATE
class BulkIngestionScreen extends StatelessWidget {
  const BulkIngestionScreen({super.key});

  void _pickAndUploadFiles(BuildContext context) async {
    HapticFeedback.mediumImpact();
    
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final provider = context.read<IngestionProvider>();
      await provider.uploadFiles(result.files);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: LiquidTheme.neonPink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidTheme.background,
      body: LiquidBackground(
        particleCount: 25,
        child: SafeArea(
          child: Consumer<IngestionProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildHeader(provider),
                  _buildActionBar(context, provider),
                  _buildTableHeader(),
                  Expanded(child: _buildDocumentList(context, provider)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(IngestionProvider provider) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: LiquidTheme.glassBg,
            border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder)),
          ),
          child: Builder(
            builder: (context) => Row(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.arrow_left, color: LiquidTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DOCUMENT INGESTION', style: LiquidTheme.monoData(size: 12, color: LiquidTheme.textPrimary, weight: FontWeight.bold)),
                    Text(
                      provider.isUploading 
                        ? provider.currentStatusMessage ?? 'Processing...'
                        : '${provider.files.length} documents processed',
                      style: LiquidTheme.monoData(size: 9, color: provider.isUploading ? LiquidTheme.neonCyan : LiquidTheme.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                if (provider.isUploading)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: LiquidTheme.neonCyan),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, IngestionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LiquidTheme.surface,
        border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder)),
      ),
      child: Row(
        children: [
          // UPLOAD BUTTON
          Expanded(
            child: GestureDetector(
              onTap: provider.isUploading ? null : () => _pickAndUploadFiles(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: provider.isUploading
                        ? [Colors.grey.shade800, Colors.grey.shade700]
                        : [LiquidTheme.neonCyan.withOpacity(0.2), LiquidTheme.neonPurple.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: provider.isUploading ? Colors.grey : LiquidTheme.neonCyan.withOpacity(0.5),
                  ),
                  boxShadow: provider.isUploading ? null : [
                    BoxShadow(color: LiquidTheme.neonCyan.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      provider.isUploading ? Iconsax.cloud_add : Iconsax.document_upload,
                      color: provider.isUploading ? Colors.grey : LiquidTheme.neonCyan,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      provider.isUploading ? 'UPLOADING...' : 'UPLOAD DOCUMENTS',
                      style: LiquidTheme.monoData(
                        size: 12,
                        color: provider.isUploading ? Colors.grey : LiquidTheme.neonCyan,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip(label: 'PASS', count: provider.passCount, color: LiquidTheme.neonGreen),
          const SizedBox(width: 8),
          _FilterChip(label: 'FAIL', count: provider.failCount, color: LiquidTheme.neonPink),
          const SizedBox(width: 8),
          _FilterChip(label: 'REVIEW', count: provider.reviewCount, color: LiquidTheme.neonYellow),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: LiquidTheme.surface.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('FILENAME', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted))),
          Expanded(flex: 1, child: Text('TYPE', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted))),
          Expanded(flex: 1, child: Text('CONFIDENCE', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted))),
          Expanded(flex: 1, child: Text('STATUS', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted))),
        ],
      ),
    );
  }

  Widget _buildDocumentList(BuildContext context, IngestionProvider provider) {
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.danger, size: 48, color: LiquidTheme.neonPink),
            const SizedBox(height: 16),
            Text('Connection Error', style: LiquidTheme.monoData(size: 14, color: LiquidTheme.neonPink)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.errorMessage!,
                style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            NeonButton(
              label: 'TRY AGAIN',
              icon: Iconsax.refresh,
              color: LiquidTheme.neonCyan,
              onPressed: () => _pickAndUploadFiles(context),
            ),
          ],
        ),
      );
    }

    if (provider.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.document_cloud, size: 56, color: LiquidTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No documents uploaded', style: LiquidTheme.monoData(size: 14, color: LiquidTheme.textMuted)),
            const SizedBox(height: 8),
            Text('Click "UPLOAD DOCUMENTS" to start', style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.files.length,
      itemBuilder: (context, index) {
        final doc = provider.files[index];
        
        return FadeInUp(
          delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
          child: _DocumentRow(
            doc: doc,
            onTap: doc.status != 'UPLOADING' ? () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => DocInspectorScreen(document: doc.analysisResult),
              ));
            } : null,
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _FilterChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: LiquidTheme.monoData(size: 9, color: color, weight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('$count', style: LiquidTheme.monoData(size: 9, color: color)),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final DocumentStatus doc;
  final VoidCallback? onTap;

  const _DocumentRow({required this.doc, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (doc.status) {
      case 'PASS': statusColor = LiquidTheme.neonGreen; break;
      case 'FAIL': statusColor = LiquidTheme.neonPink; break;
      case 'REVIEW': statusColor = LiquidTheme.neonYellow; break;
      default: statusColor = LiquidTheme.textMuted;
    }

    final isUploading = doc.status == 'UPLOADING';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            // Filename
            Expanded(
              flex: 2,
              child: Text(
                doc.filename,
                style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Type
            Expanded(
              flex: 1,
              child: doc.docType != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: LiquidTheme.neonPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc.docType!,
                        style: LiquidTheme.monoData(size: 8, color: LiquidTheme.neonPurple, weight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : const SizedBox(),
            ),
            // Confidence
            Expanded(
              flex: 1,
              child: Text(
                doc.confidence != null && doc.confidence! > 0 
                  ? '${(doc.confidence! * 100).toStringAsFixed(0)}%' 
                  : '-',
                style: LiquidTheme.monoData(
                  size: 10,
                  color: doc.confidence != null && doc.confidence! > 0.8 
                      ? LiquidTheme.neonGreen
                      : doc.confidence != null && doc.confidence! > 0.6 
                          ? LiquidTheme.neonYellow
                          : LiquidTheme.textMuted,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: isUploading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: LiquidTheme.neonCyan),
                    )
                  : Text(
                      doc.status,
                      style: LiquidTheme.monoData(size: 10, color: statusColor, weight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

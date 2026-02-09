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

/// ═══════════════════════════════════════════════════════════════════════════════
/// BULK INGESTION SCREEN - Premium Document Upload
/// ═══════════════════════════════════════════════════════════════════════════════

class BulkIngestionScreen extends StatefulWidget {
  const BulkIngestionScreen({super.key});

  @override
  State<BulkIngestionScreen> createState() => _BulkIngestionScreenState();
}

class _BulkIngestionScreenState extends State<BulkIngestionScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _pickAndUploadFiles() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DS.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Consumer<IngestionProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildHeader(provider),
                  Expanded(
                    child: provider.files.isEmpty
                        ? _buildEmptyState()
                        : _buildDocumentList(provider),
                  ),
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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(DS.space4, DS.space3, DS.space4, DS.space4),
          decoration: BoxDecoration(
            color: DS.surface.withOpacity(0.85),
            border: Border(bottom: BorderSide(color: DS.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: DS.primaryGradient,
                      borderRadius: BorderRadius.circular(DS.radiusMd),
                    ),
                    child: const Icon(Iconsax.document_upload, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: DS.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Document Ingestion', style: DS.heading3()),
                        Text(
                          provider.isUploading 
                            ? provider.currentStatusMessage ?? 'Processing...'
                            : '${provider.files.length} documents in queue',
                          style: DS.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  if (provider.isUploading)
                    Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DS.primary,
                      ),
                    )
                  else
                    StatusBadge(
                      label: provider.files.isEmpty ? 'READY' : 'QUEUE',
                      color: provider.files.isEmpty ? DS.success : DS.primary,
                      pulse: false,
                    ),
                ],
              ),
              
              const SizedBox(height: DS.space4),
              
              // Upload button
              GradientButton(
                label: provider.isUploading ? 'PROCESSING...' : 'SELECT FILES',
                icon: Iconsax.add_circle,
                onPressed: provider.isUploading ? () {} : _pickAndUploadFiles,
                isLoading: provider.isUploading,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Padding(
          padding: const EdgeInsets.all(DS.space8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated upload area
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.primary.withOpacity(0.03),
                    border: Border.all(
                      color: DS.primary.withOpacity(0.2 + _pulseController.value * 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DS.primary.withOpacity(_pulseController.value * 0.2),
                        blurRadius: 30 + _pulseController.value * 20,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.document_cloud,
                        size: 56,
                        color: DS.primary.withOpacity(0.6 + _pulseController.value * 0.4),
                      ),
                      const SizedBox(height: DS.space3),
                      Text(
                        'Drop files here',
                        style: DS.body(color: DS.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: DS.space8),
              
              Text(
                'Financial Document Intelligence',
                style: DS.heading2(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DS.space2),
              Text(
                'Upload invoices, bank statements, or payslips\nfor AI-powered extraction and validation',
                style: DS.bodySmall(),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: DS.space6),
              
              // File types
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FileTypeChip(icon: Iconsax.document, label: 'PDF'),
                  const SizedBox(width: DS.space2),
                  _FileTypeChip(icon: Iconsax.gallery, label: 'PNG'),
                  const SizedBox(width: DS.space2),
                  _FileTypeChip(icon: Iconsax.image, label: 'JPG'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentList(IngestionProvider provider) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.space4, vertical: DS.space3),
          decoration: BoxDecoration(
            color: DS.surface.withOpacity(0.5),
            border: Border(bottom: BorderSide(color: DS.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('DOCUMENT', style: DS.label())),
              Expanded(flex: 2, child: Text('TYPE', style: DS.label())),
              Expanded(flex: 2, child: Text('STATUS', style: DS.label())),
              const SizedBox(width: 48),
            ],
          ),
        ),
        
        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: DS.space2),
            itemCount: provider.files.length,
            itemBuilder: (context, index) {
              final file = provider.files[index];
              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: index * 50),
                child: _DocumentRow(
                  file: file,
                  onTap: () => _openInspector(file),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openInspector(DocumentStatus file) {
    if (file.analysisResult == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocInspectorScreen(
          document: file.analysisResult,
          localPath: file.localPath,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _FileTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FileTypeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.space3, vertical: DS.space2),
      decoration: BoxDecoration(
        color: DS.surfaceElevated,
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: DS.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DS.textMuted),
          const SizedBox(width: DS.space1),
          Text(label, style: DS.caption()),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final DocumentStatus file;
  final VoidCallback onTap;

  const _DocumentRow({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = file.status;
    final isProcessing = status == 'UPLOADING';
    final isError = status == 'FAIL';
    final isSuccess = status == 'PASS' || status == 'REVIEW';
    
    final statusColor = isError ? DS.error 
                      : isSuccess ? DS.success 
                      : isProcessing ? DS.primary 
                      : DS.textMuted;
    
    final docType = file.docType ?? 'UNKNOWN';
    final confidence = file.confidence ?? 0.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSuccess ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.space4, vertical: DS.space3),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: DS.border.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              // Document info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DS.radiusSm),
                      ),
                      child: Icon(
                        isProcessing ? Iconsax.refresh_circle : Iconsax.document,
                        size: 18,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: DS.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.filename,
                            style: DS.body(weight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (confidence > 0)
                            Text(
                              'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                              style: DS.caption(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Type
              Expanded(
                flex: 2,
                child: Text(
                  docType,
                  style: DS.mono(size: 11, color: DS.textSecondary),
                ),
              ),
              
              // Status
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    if (isProcessing)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DS.primary,
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: DS.space2),
                    Text(
                      _statusLabel(status),
                      style: DS.caption(color: statusColor),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              SizedBox(
                width: 48,
                child: isSuccess
                    ? Icon(Iconsax.arrow_right_3, size: 16, color: DS.textMuted)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'UPLOADING': return 'Uploading';
      case 'PASS': return 'Complete';
      case 'FAIL': return 'Failed';
      case 'REVIEW': return 'Review';
      default: return 'Pending';
    }
  }
}

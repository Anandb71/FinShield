import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../styles/app_theme.dart';
import '../widgets/premium_glass_card.dart';
import 'document_detail_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<UploadItem> _uploads = [];
  bool _isUploading = false;
  bool _isHovering = false;

  Future<void> _pickAndUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);

    for (final file in result.files) {
      if (file.bytes == null) continue;

      final uploadItem = UploadItem(
        filename: file.name,
        bytes: file.bytes!,
        status: UploadStatus.uploading,
      );

      setState(() => _uploads.insert(0, uploadItem));

      // Upload to backend
      final response = await ApiService.analyzeDocument(
        filename: file.name,
        fileBytes: file.bytes!,
      );

      if (response.isSuccess) {
        uploadItem.status = UploadStatus.success;
        uploadItem.result = response.data;
      } else {
        uploadItem.status = UploadStatus.failed;
        uploadItem.errorMessage = response.error;
      }

      if (mounted) setState(() {});
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            title: Text('Data Ingestion', style: AppTheme.darkTheme.textTheme.headlineMedium),
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildDropZone(),
                ),
                const SizedBox(height: 32),
                if (_uploads.isNotEmpty) ...[
                  Text(
                    'RECENT UPLOADS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return FadeInLeft(
                    delay: Duration(milliseconds: index * 100),
                    child: _buildUploadItem(_uploads[index]),
                  );
                },
                childCount: _uploads.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _isUploading ? null : _pickAndUploadFiles,
        child: PremiumGlassCard(
          height: 250,
          hasGlow: _isHovering || _isUploading,
          glowColor: AppTheme.primary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(_isHovering ? 0.8 : 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _isUploading ? Icons.hourglass_empty_rounded : Icons.cloud_upload_rounded,
                  size: 48,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isUploading ? 'ANALYZING DOCUMENTS...' : 'DROP FILES HERE',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Support for PDF, JPG, PNG',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadItem(UploadItem item) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (item.status) {
      case UploadStatus.uploading:
        statusColor = AppTheme.secondary;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = 'PROCESSING';
        break;
      case UploadStatus.success:
        final result = item.result!;
        if (result.validation.valid) {
          statusColor = AppTheme.success;
          statusIcon = Icons.check_circle_rounded;
          statusText = 'CLEAN';
        } else if (result.validation.errors.isNotEmpty) {
          statusColor = AppTheme.error;
          statusIcon = Icons.error_rounded;
          statusText = 'FAILED';
        } else {
          statusColor = AppTheme.warning;
          statusIcon = Icons.warning_rounded;
          statusText = 'REVIEW';
        }
        break;
      default: // Handle any other case
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.help_outline;
        statusText = 'UNKNOWN';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: item.result != null || item.errorMessage != null
            ? () => _openDetail(item)
            : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.status == UploadStatus.uploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColor,
                      ),
                    )
                  : Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.filename,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.result?.classification.type ?? 'Processing...',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(UploadItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          result: item.result,
          errorMessage: item.errorMessage,
          filename: item.filename,
        ),
      ),
    );
  }
}

enum UploadStatus { uploading, success, failed }

class UploadItem {
  final String filename;
  final Uint8List bytes;
  UploadStatus status;
  DocumentResult? result;
  String? errorMessage;

  UploadItem({
    required this.filename,
    required this.bytes,
    required this.status,
    this.result,
    this.errorMessage,
  });
}

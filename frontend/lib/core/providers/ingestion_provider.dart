import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';

/// Global Ingestion State - Persists across navigation
class IngestionProvider extends ChangeNotifier {
  bool _isUploading = false;
  final List<DocumentStatus> _files = [];
  String? _currentStatusMessage;
  String? _errorMessage;

  bool get isUploading => _isUploading;
  List<DocumentStatus> get files => List.unmodifiable(_files);
  String? get currentStatusMessage => _currentStatusMessage;
  String? get errorMessage => _errorMessage;

  int get passCount => _files.where((f) => f.status == 'PASS').length;
  int get failCount => _files.where((f) => f.status == 'FAIL').length;
  int get reviewCount => _files.where((f) => f.status == 'REVIEW').length;

  /// Pre-flight health check + Upload
  Future<void> uploadFiles(List<PlatformFile> rawFiles) async {
    if (_isUploading) return; // Prevent double uploads

    _isUploading = true;
    _errorMessage = null;
    _currentStatusMessage = '🔍 Checking backend connectivity...';
    notifyListeners();

    // ═══════════════════════════════════════════════════════════
    // PRE-FLIGHT CHECK
    // ═══════════════════════════════════════════════════════════
    try {
      final isHealthy = await ApiService.checkHealth();
      if (!isHealthy) {
        throw Exception('❌ Cannot reach Backend (Port 8000). Is it running?');
      }
    } catch (e) {
      _isUploading = false;
      _errorMessage = e.toString();
      _currentStatusMessage = null;
      notifyListeners();
      return;
    }

    // ═══════════════════════════════════════════════════════════
    // UPLOAD FILES SEQUENTIALLY
    // ═══════════════════════════════════════════════════════════
    try {
      // Add placeholders
      final startIndex = _files.length;
      for (final file in rawFiles) {
        _files.add(DocumentStatus(
          filename: file.name,
          status: 'UPLOADING',
          progress: 0.0,
        ));
      }
      notifyListeners();

      // Process each file
      for (int i = 0; i < rawFiles.length; i++) {
        final file = rawFiles[i];
        final fileIndex = startIndex + i;

        if (file.bytes == null) {
          _files[fileIndex] = _files[fileIndex].copyWith(
            status: 'FAIL',
            error: 'No file data',
          );
          notifyListeners();
          continue;
        }

        final fileSizeMB = (file.bytes!.length / (1024 * 1024)).toStringAsFixed(2);
        _currentStatusMessage = '📤 Uploading ${file.name} ($fileSizeMB MB)...';
        notifyListeners();

        final result = await ApiService.analyzeDocument(
          filename: file.name,
          fileBytes: file.bytes!,
        );

        if (result.isSuccess && result.data != null) {
          final data = result.data!;
          _files[fileIndex] = DocumentStatus(
            filename: data.filename,
            status: data.status,
            docId: data.documentId,
            docType: data.docType,
            confidence: data.confidence,
            extractedFields: data.extractedFields,
            layouts: data.layoutTags,
            analysisResult: data,
          );
          _currentStatusMessage = '✓ ${file.name} analyzed';
        } else {
          _files[fileIndex] = _files[fileIndex].copyWith(
            status: 'FAIL',
            error: result.error ?? 'Unknown error',
          );
          _currentStatusMessage = '✗ ${file.name} failed';
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Upload error: $e';
    } finally {
      _isUploading = false;
      _currentStatusMessage = null;
      notifyListeners();
    }
  }

  /// Clear all uploaded documents
  void clearAll() {
    _files.clear();
    _errorMessage = null;
    _currentStatusMessage = null;
    notifyListeners();
  }

  /// Remove specific document
  void removeDocument(int index) {
    if (index >= 0 && index < _files.length) {
      _files.removeAt(index);
      notifyListeners();
    }
  }
}

/// Single document status
class DocumentStatus {
  final String filename;
  final String status; // UPLOADING, PASS, FAIL, REVIEW
  final double progress;
  final String? docId;
  final String? docType;
  final double? confidence;
  final Map<String, dynamic>? extractedFields;
  final List<String>? layouts;
  final String? error;
  final DocumentAnalysisResult? analysisResult;

  DocumentStatus({
    required this.filename,
    required this.status,
    this.progress = 0.0,
    this.docId,
    this.docType,
    this.confidence,
    this.extractedFields,
    this.layouts,
    this.error,
    this.analysisResult,
  });

  DocumentStatus copyWith({
    String? filename,
    String? status,
    double? progress,
    String? docId,
    String? docType,
    double? confidence,
    Map<String, dynamic>? extractedFields,
    List<String>? layouts,
    String? error,
    DocumentAnalysisResult? analysisResult,
  }) {
    return DocumentStatus(
      filename: filename ?? this.filename,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      docId: docId ?? this.docId,
      docType: docType ?? this.docType,
      confidence: confidence ?? this.confidence,
      extractedFields: extractedFields ?? this.extractedFields,
      layouts: layouts ?? this.layouts,
      error: error ?? this.error,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }
}

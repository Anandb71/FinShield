import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// API Service - REAL Backend Connection
/// NO MOCK DATA - Shows errors if backend is offline
class ApiService {
  static String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Debug logging callback - connects to System Terminal
  static void Function(String message)? onLog;

  static void _log(String message) {
    print('[API] $message');
    onLog?.call(message);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════════════════════
  
  static Future<bool> checkHealth() async {
    // 1. Try dedicated health endpoint (Current BaseUrl)
    try {
      _log('[HEALTH] Checking $baseUrl/v1/health...');
      final response = await http.get(Uri.parse('$baseUrl/v1/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _log('[HEALTH] Success!');
        return true;
      }
    } catch (e) {
      _log('[HEALTH] Primary check failed: $e');
    }

    // 2. Fallback: Root endpoint (127.0.0.1)
    try {
      _log('[HEALTH] Trying root fallback (127.0.0.1)...');
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        baseUrl = 'http://127.0.0.1:8000/api'; // Update base url
        return true;
      }
    } catch (e) {
      _log('[HEALTH] Root fallback failed: $e');
    }

    // 3. Fallback: Android Emulator (10.0.2.2)
    try {
      _log('[HEALTH] Trying Android fallback (10.0.2.2)...');
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        baseUrl = 'http://10.0.2.2:8000/api'; // Update to Android host
        _log('[HEALTH] Switched to Android host!');
        return true;
      }
    } catch (e) {
      _log('[HEALTH] Android fallback failed: $e');
    }

    // 4. Fallback: Localhost (Chrome specific)
    try {
      _log('[HEALTH] Trying localhost fallback...');
      final response = await http.get(Uri.parse('http://localhost:8000/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        baseUrl = 'http://localhost:8000/api'; // Update to localhost
        _log('[HEALTH] Switched to localhost!');
        return true;
      }
    } catch (e) {
      _log('[HEALTH] Localhost fallback failed: $e');
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOCUMENT UPLOAD & ANALYSIS (REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static Future<ApiResult<DocumentAnalysisResult>> analyzeDocument({
    required String filename,
    required Uint8List fileBytes,
  }) async {
    _log('[UPLOAD] Starting: $filename (${(fileBytes.length / 1024).toStringAsFixed(1)} KB)');
    
    try {
      final uri = Uri.parse('$baseUrl/documents/analyze');
      final request = http.MultipartRequest('POST', uri);
      
      // Determine content type
      final ext = filename.split('.').last.toLowerCase();
      String contentType;
      if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (['png', 'jpg', 'jpeg'].contains(ext)) {
        contentType = 'image/$ext';
      } else {
        contentType = 'application/octet-stream';
      }
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);
      
      _log('[UPLOAD] Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('[ML] Classification: ${data['classification']?['type']} (${((data['classification']?['confidence'] ?? 0) * 100).toStringAsFixed(1)}%)');
        
        if (data['status'] == 'failed') {
          return ApiResult.error(data['error'] ?? 'Analysis failed');
        }
        
        return ApiResult.success(DocumentAnalysisResult.fromJson(data));
      } else {
        return ApiResult.error('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      _log('[ERROR] Connection failed: $e');
      return ApiResult.error('Backend offline');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOCUMENT RETRIEVAL (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static Future<ApiResult<DocumentAnalysisResult>> getDocument(String docId) async {
    _log('[FETCH] Document: $docId');
    try {
      final response = await http.get(Uri.parse('$baseUrl/documents/$docId'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResult.success(DocumentAnalysisResult.fromJson(data));
      } else {
        return ApiResult.error('Not found');
      }
    } catch (e) {
      return ApiResult.error('Connection failed');
    }
  }

  static String getDocumentFileUrl(String docId) {
    return '$baseUrl/documents/$docId/file';
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD METRICS (REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static Future<ApiResult<DashboardMetrics>> getMetrics() async {
    _log('[METRICS] Fetching dashboard data...');
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/metrics'))
        .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('[METRICS] Docs: ${data['overview']?['total_documents_processed']}, Corrections: ${data['overview']?['total_corrections']}');
        return ApiResult.success(DashboardMetrics.fromJson(data));
      } else {
        _log('[ERROR] Metrics failed: ${response.statusCode}');
        return ApiResult.error('Metrics failed: ${response.statusCode}');
      }
    } catch (e) {
      _log('[ERROR] Backend offline');
      return ApiResult.error('Backend offline');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // REVIEW QUEUE (REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static Future<ApiResult<List<ReviewItem>>> getReviewQueue() async {
    _log('[QUEUE] Fetching review items...');
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/review/queue'))
        .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final queue = (data['queue'] as List?) ?? [];
        _log('[QUEUE] ${queue.length} items pending review');
        return ApiResult.success(queue.map((e) => ReviewItem.fromJson(e)).toList());
      } else {
        _log('[ERROR] Queue failed: ${response.statusCode}');
        return ApiResult.error('Queue failed: ${response.statusCode}');
      }
    } catch (e) {
      _log('[ERROR] Backend offline');
      return ApiResult.error('Backend offline');
    }
  }
  
  /// Submit correction to backend
  static Future<ApiResult<CorrectionResult>> submitCorrection({
    required String docId,
    required String fieldName,
    required String originalValue,
    required String correctedValue,
  }) async {
    _log('[CORRECT] $fieldName: "$originalValue" → "$correctedValue"');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review/$docId/correct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_id': docId,
          'field_name': fieldName,
          'original_value': originalValue,
          'corrected_value': correctedValue,
          'corrected_by': 'user@finsight.ai',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _log('[LEARN] Correction saved to Backboard');
        return ApiResult.success(CorrectionResult.fromJson(jsonDecode(response.body)));
      } else {
        _log('[ERROR] Correction failed: ${response.statusCode}');
        return ApiResult.error('Correction failed');
      }
    } catch (e) {
      _log('[ERROR] Backend offline');
      return ApiResult.error('Backend offline');
    }
  }
  
  /// Approve document
  static Future<ApiResult<bool>> approveDocument(String docId) async {
    _log('[APPROVE] Document: $docId');
    
    try {
      final response = await http.post(Uri.parse('$baseUrl/review/$docId/approve'))
        .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _log('[APPROVE] ✓ Success');
        return ApiResult.success(true);
      } else {
        _log('[ERROR] Approve failed: ${response.statusCode}');
        return ApiResult.error('Approve failed');
      }
    } catch (e) {
      _log('[ERROR] Backend offline');
      return ApiResult.error('Backend offline');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR CLUSTERS (REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static Future<ApiResult<ErrorClusters>> getErrorClusters() async {
    _log('[CLUSTERS] Fetching error patterns...');
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/review/errors/clusters'))
        .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('[CLUSTERS] ${data['total_corrections']} total corrections');
        return ApiResult.success(ErrorClusters.fromJson(data));
      } else {
        _log('[ERROR] Clusters failed: ${response.statusCode}');
        return ApiResult.error('Clusters failed');
      }
    } catch (e) {
      _log('[ERROR] Backend offline');
      return ApiResult.error('Backend offline');
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESULT WRAPPER
// ═════════════════════════════════════════════════════════════════════════════

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult._({this.data, this.error, required this.isSuccess});

  factory ApiResult.success(T data) => ApiResult._(data: data, isSuccess: true);
  factory ApiResult.error(String message) => ApiResult._(error: message, isSuccess: false);
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═════════════════════════════════════════════════════════════════════════════

class DocumentAnalysisResult {
  final String documentId;
  final String filename;
  final String docType;
  final double confidence;
  final Map<String, dynamic> extractedFields;
  final List<String> layoutTags;
  final ValidationResult validation;
  final double processingTime;

  DocumentAnalysisResult({
    required this.documentId,
    required this.filename,
    required this.docType,
    required this.confidence,
    required this.extractedFields,
    required this.layoutTags,
    required this.validation,
    required this.processingTime,
  });

  factory DocumentAnalysisResult.fromJson(Map<String, dynamic> json) {
    final layouts = <String>[];
    if (json['layout'] != null) {
      if (json['layout']['tables'] == true) layouts.add('Table');
      if (json['layout']['handwritten'] == true) layouts.add('Handwritten');
      if (json['layout']['stamps'] == true) layouts.add('Stamp');
      if (json['layout']['signatures'] == true) layouts.add('Signature');
      if (json['layout']['headers'] == true) layouts.add('Header');
    }
    
    return DocumentAnalysisResult(
      documentId: json['document_id'] ?? '',
      filename: json['filename'] ?? '',
      docType: (json['classification']?['type'] ?? 'unknown').toString().toUpperCase(),
      confidence: (json['classification']?['confidence'] ?? 0.0).toDouble(),
      extractedFields: json['extracted_fields'] ?? {},
      layoutTags: layouts,
      validation: ValidationResult.fromJson(json['validation'] ?? {}),
      processingTime: (json['processing_time_seconds'] ?? 0.0).toDouble(),
    );
  }
  
  String get status {
    if (!validation.valid) return 'FAIL';
    if (confidence < 0.7) return 'REVIEW';
    return 'PASS';
  }
}

class ValidationResult {
  final bool valid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({required this.valid, required this.errors, required this.warnings});

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      valid: json['valid'] ?? true,
      errors: (json['errors'] as List?)?.cast<String>() ?? [],
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
    );
  }
}

class DashboardMetrics {
  final int totalDocuments;
  final int totalCorrections;
  final double errorRate;
  final double avgProcessingTime;
  final Map<String, TypeAccuracy> accuracyByType;
  final List<ErrorField> topErrorFields;

  DashboardMetrics({
    required this.totalDocuments,
    required this.totalCorrections,
    required this.errorRate,
    required this.avgProcessingTime,
    required this.accuracyByType,
    required this.topErrorFields,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] ?? {};
    final accuracyMap = <String, TypeAccuracy>{};
    (json['accuracy_by_type'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      accuracyMap[k] = TypeAccuracy.fromJson(v);
    });
    
    return DashboardMetrics(
      totalDocuments: overview['total_documents_processed'] ?? 0,
      totalCorrections: overview['total_corrections'] ?? 0,
      errorRate: (overview['error_rate'] ?? 0.0).toDouble(),
      avgProcessingTime: (overview['avg_processing_time'] ?? 0.0).toDouble(),
      accuracyByType: accuracyMap,
      topErrorFields: (json['top_error_fields'] as List? ?? [])
          .map((e) => ErrorField.fromJson(e))
          .toList(),
    );
  }
}

class TypeAccuracy {
  final double accuracy;
  final int count;

  TypeAccuracy({required this.accuracy, required this.count});

  factory TypeAccuracy.fromJson(Map<String, dynamic> json) {
    return TypeAccuracy(
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class ErrorField {
  final String field;
  final int count;

  ErrorField({required this.field, required this.count});

  factory ErrorField.fromJson(Map<String, dynamic> json) {
    return ErrorField(
      field: json['field'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ReviewItem {
  final String docId;
  final String field;
  final String ocrValue;
  final String? suggestion;
  final int confidence;
  final String docType;

  ReviewItem({
    required this.docId,
    required this.field,
    required this.ocrValue,
    this.suggestion,
    required this.confidence,
    required this.docType,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      docId: json['document_id'] ?? '',
      field: json['field'] ?? '',
      ocrValue: json['ocr_value'] ?? '',
      suggestion: json['suggestion'],
      confidence: json['confidence'] ?? 50,
      docType: json['doc_type'] ?? 'unknown',
    );
  }
}

class CorrectionResult {
  final bool success;
  final String correctionId;
  final String message;

  CorrectionResult({required this.success, required this.correctionId, required this.message});

  factory CorrectionResult.fromJson(Map<String, dynamic> json) {
    return CorrectionResult(
      success: json['status'] == 'success',
      correctionId: json['correction_id'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class ErrorClusters {
  final Map<String, ClusterData> clusters;
  final int totalCorrections;

  ErrorClusters({required this.clusters, required this.totalCorrections});

  factory ErrorClusters.fromJson(Map<String, dynamic> json) {
    final clustersMap = <String, ClusterData>{};
    (json['clusters'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      clustersMap[k] = ClusterData.fromJson(v);
    });
    return ErrorClusters(
      clusters: clustersMap,
      totalCorrections: json['total_corrections'] ?? 0,
    );
  }
}

class ClusterData {
  final int count;
  final List<dynamic> examples;

  ClusterData({required this.count, required this.examples});

  factory ClusterData.fromJson(Map<String, dynamic> json) {
    return ClusterData(
      count: json['count'] ?? 0,
      examples: json['examples'] ?? [],
    );
  }
}

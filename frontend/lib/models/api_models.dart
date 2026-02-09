/// API Models - Exact match to backend responses
/// NO fallbacks, NO defaults, NO mock data

class HealthResponse {
  final String status;
  final String service;
  final String version;
  final String timestamp;
  final Map<String, String> components;

  HealthResponse({
    required this.status,
    required this.service,
    required this.version,
    required this.timestamp,
    required this.components,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String,
      service: json['service'] as String,
      version: json['version'] as String,
      timestamp: json['timestamp'] as String,
      components: Map<String, String>.from(json['components'] ?? {}),
    );
  }
}

class DocumentResult {
  final String documentId;
  final String filename;
  final String status;
  final Classification classification;
  final Map<String, dynamic> extractedFields;
  final LayoutInfo layout;
  final List<String> layoutTags;
  final ValidationResult validation;
  final ConsistencyCheck? consistencyCheck;
  final double processingTimeSeconds;
  final String? error;

  DocumentResult({
    required this.documentId,
    required this.filename,
    required this.status,
    required this.classification,
    required this.extractedFields,
    required this.layout,
    required this.layoutTags,
    required this.validation,
    this.consistencyCheck,
    required this.processingTimeSeconds,
    this.error,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';

  factory DocumentResult.fromJson(Map<String, dynamic> json) {
    return DocumentResult(
      documentId: json['document_id'] as String? ?? '',
      filename: json['filename'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      classification: Classification.fromJson(json['classification'] ?? {}),
      extractedFields: Map<String, dynamic>.from(json['extracted_fields'] ?? {}),
      layout: LayoutInfo.fromJson(json['layout'] ?? {}),
      layoutTags: List<String>.from(json['layout_tags'] ?? []),
      validation: ValidationResult.fromJson(json['validation'] ?? {}),
      consistencyCheck: json['consistency_check'] != null
          ? ConsistencyCheck.fromJson(json['consistency_check'])
          : null,
      processingTimeSeconds: (json['processing_time_seconds'] ?? 0).toDouble(),
      error: json['error'] as String?,
    );
  }
}

class Classification {
  final String type;
  final double confidence;
  final String? language;
  final double? imageQualityScore;

  Classification({
    required this.type,
    required this.confidence,
    this.language,
    this.imageQualityScore,
  });

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      type: (json['type'] as String?) ?? 'UNKNOWN',
      confidence: (json['confidence'] ?? 0).toDouble(),
      language: json['language'] as String?,
      imageQualityScore: json['image_quality_score'] != null
          ? (json['image_quality_score']).toDouble()
          : null,
    );
  }
}

class LayoutInfo {
  final bool tables;
  final bool handwritten;
  final bool stamps;
  final bool signatures;
  final bool headers;

  LayoutInfo({
    required this.tables,
    required this.handwritten,
    required this.stamps,
    required this.signatures,
    required this.headers,
  });

  factory LayoutInfo.fromJson(Map<String, dynamic> json) {
    return LayoutInfo(
      tables: json['tables'] == true,
      handwritten: json['handwritten'] == true,
      stamps: json['stamps'] == true,
      signatures: json['signatures'] == true,
      headers: json['headers'] == true,
    );
  }
}

class ValidationResult {
  final bool valid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.valid,
    required this.errors,
    required this.warnings,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      valid: json['valid'] == true,
      errors: List<String>.from(json['errors'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

class ConsistencyCheck {
  final String status;
  final List<String> messages;

  ConsistencyCheck({required this.status, required this.messages});

  factory ConsistencyCheck.fromJson(Map<String, dynamic> json) {
    return ConsistencyCheck(
      status: json['status'] as String? ?? 'unknown',
      messages: List<String>.from(json['messages'] ?? []),
    );
  }
}

class DashboardMetrics {
  final int totalDocuments;
  final int totalCorrections;
  final double errorRate;
  final double avgProcessingTime;
  final Map<String, TypeAccuracy> accuracyByType;
  final List<TopErrorField> topErrorFields;

  DashboardMetrics({
    required this.totalDocuments,
    required this.totalCorrections,
    required this.errorRate,
    required this.avgProcessingTime,
    required this.accuracyByType,
    required this.topErrorFields,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] as Map<String, dynamic>? ?? {};
    final accuracyMap = <String, TypeAccuracy>{};
    final rawAccuracy = json['accuracy_by_type'] as Map<String, dynamic>? ?? {};
    rawAccuracy.forEach((k, v) {
      accuracyMap[k] = TypeAccuracy.fromJson(v as Map<String, dynamic>);
    });

    return DashboardMetrics(
      totalDocuments: overview['total_documents_processed'] as int? ?? 0,
      totalCorrections: overview['total_corrections'] as int? ?? 0,
      errorRate: (overview['error_rate'] ?? 0).toDouble(),
      avgProcessingTime: (overview['avg_processing_time'] ?? 0).toDouble(),
      accuracyByType: accuracyMap,
      topErrorFields: (json['top_error_fields'] as List<dynamic>? ?? [])
          .map((e) => TopErrorField.fromJson(e as Map<String, dynamic>))
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
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      count: json['count'] as int? ?? 0,
    );
  }
}

class TopErrorField {
  final String field;
  final int count;

  TopErrorField({required this.field, required this.count});

  factory TopErrorField.fromJson(Map<String, dynamic> json) {
    return TopErrorField(
      field: json['field'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class ReviewQueueItem {
  final String docId;
  final String field;
  final String ocrValue;
  final String? suggestion;
  final int confidence;
  final String docType;

  ReviewQueueItem({
    required this.docId,
    required this.field,
    required this.ocrValue,
    this.suggestion,
    required this.confidence,
    required this.docType,
  });

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) {
    return ReviewQueueItem(
      docId: json['doc_id'] as String? ?? '',
      field: json['field'] as String? ?? '',
      ocrValue: json['ocr_value'] as String? ?? '',
      suggestion: json['suggestion'] as String?,
      confidence: json['confidence'] as int? ?? 0,
      docType: json['doc_type'] as String? ?? 'unknown',
    );
  }
}

class ReviewQueueResponse {
  final List<ReviewQueueItem> queue;
  final int count;
  final String message;

  ReviewQueueResponse({
    required this.queue,
    required this.count,
    required this.message,
  });

  factory ReviewQueueResponse.fromJson(Map<String, dynamic> json) {
    return ReviewQueueResponse(
      queue: (json['queue'] as List<dynamic>? ?? [])
          .map((e) => ReviewQueueItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

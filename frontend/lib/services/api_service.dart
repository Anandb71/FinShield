import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/api_models.dart';

/// API Service - Direct connection to backend
/// NO fallbacks, NO mock data - real API calls only
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Check if backend is online
  static Future<HealthResponse?> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/v1/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return HealthResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('[API] Health check failed: $e');
      return null;
    }
  }

  /// Upload and analyze document
  static Future<ApiResponse<DocumentResult>> analyzeDocument({
    required String filename,
    required Uint8List fileBytes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/documents/analyze');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: MediaType('application', 'octet-stream'),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120), // Long timeout for AI processing
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(DocumentResult.fromJson(json));
      } else {
        final errorBody = response.body;
        String errorMsg = 'Upload failed (${response.statusCode})';
        try {
          final errorJson = jsonDecode(errorBody);
          errorMsg = errorJson['detail'] ?? errorMsg;
        } catch (_) {}
        return ApiResponse.error(errorMsg);
      }
    } catch (e) {
      return ApiResponse.error('Connection failed: $e');
    }
  }

  /// Get dashboard metrics
  static Future<ApiResponse<DashboardMetrics>> getMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard/metrics'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          DashboardMetrics.fromJson(jsonDecode(response.body)),
        );
      }
      return ApiResponse.error('Metrics failed (${response.statusCode})');
    } catch (e) {
      return ApiResponse.error('Connection failed: $e');
    }
  }

  /// Get review queue
  static Future<ApiResponse<ReviewQueueResponse>> getReviewQueue() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/review/queue'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          ReviewQueueResponse.fromJson(jsonDecode(response.body)),
        );
      }
      return ApiResponse.error('Queue failed (${response.statusCode})');
    } catch (e) {
      return ApiResponse.error('Connection failed: $e');
    }
  }

  /// Get document by ID
  static Future<ApiResponse<DocumentResult>> getDocument(String docId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/documents/$docId'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          DocumentResult.fromJson(jsonDecode(response.body)),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse.error('Document not found');
      }
      return ApiResponse.error('Failed (${response.statusCode})');
    } catch (e) {
      return ApiResponse.error('Connection failed: $e');
    }
  }

  /// Get document file URL for display
  static String getDocumentFileUrl(String docId) {
    return '$baseUrl/documents/$docId/file';
  }

  /// Approve document
  static Future<ApiResponse<bool>> approveDocument(String docId) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/review/$docId/approve'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      }
      return ApiResponse.error('Approve failed (${response.statusCode})');
    } catch (e) {
      return ApiResponse.error('Connection failed: $e');
    }
  }

  /// Submit correction
  static Future<ApiResponse<Map<String, dynamic>>> submitCorrection({
    required String docId,
    required String fieldName,
    required String originalValue,
    required String correctedValue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review/$docId/correct'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_id': docId,
          'field_name': fieldName,
          'original_value': originalValue,
          'corrected_value': correctedValue,
          'corrected_by': 'user',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(jsonDecode(response.body));
      }
      return ApiResponse.error('Correction failed (${response.statusCode})');
    } catch (e) {
      return ApiResponse.error('Connection failed: $e');
    }
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) => ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(String message) => ApiResponse._(error: message, isSuccess: false);
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../styles/app_theme.dart';
import '../widgets/premium_glass_card.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<ReviewQueueItem>? _queue;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadQueue());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    final result = await ApiService.getReviewQueue();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _queue = result.data!.queue;
          _error = null;
        } else {
          _error = result.error;
        }
      });
    }
  }

  Future<void> _approveItem(ReviewQueueItem item) async {
    final result = await ApiService.approveDocument(item.docId);
    
    if (result.isSuccess) {
      setState(() {
        _queue?.removeWhere((i) => i.docId == item.docId && i.field == item.field);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document Approved'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${result.error}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            title: Text('Review Queue', style: AppTheme.darkTheme.textTheme.headlineMedium),
            centerTitle: false,
            pinned: true,
            actions: [
              if (_queue != null)
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_queue!.length} PENDING',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          if (_isLoading)
             const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
             )
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_queue!.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50),
                      child: _buildQueueItem(_queue![index]),
                    );
                  },
                  childCount: _queue!.length,
                ),
              ),
            ),
            
           const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withOpacity(0.1),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.success),
          ),
          const SizedBox(height: 24),
          const Text(
            'ALL CAUGHT UP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No documents pending review',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(child: Text(_error ?? 'Unknown error', style: const TextStyle(color: AppTheme.error)));
  }

  Widget _buildQueueItem(ReviewQueueItem item) {
    // Determine status color based on confidence
    final color = item.confidence > 80 
        ? AppTheme.success 
        : item.confidence > 50 
            ? AppTheme.warning 
            : AppTheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.docType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.docId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${item.confidence}% CONFIDENCE',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FIELD', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(item.field, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VALUE EXTRACTED', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          item.ocrValue, 
                          style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (item.suggestion != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.warning),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        'Suggestion: ${item.suggestion}',
                        style: const TextStyle(color: AppTheme.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 20),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCorrectionDialog(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CORRECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveItem(item),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCorrectionDialog(ReviewQueueItem item) {
    final controller = TextEditingController(text: item.ocrValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Make Correction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Correct Value',
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.submitCorrection(
                docId: item.docId,
                fieldName: item.field,
                originalValue: item.ocrValue,
                correctedValue: controller.text,
              );
              if (result.isSuccess) {
                _loadQueue();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correction submitted')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}

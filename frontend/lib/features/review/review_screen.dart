import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/services/api_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// REVIEW SCREEN - Human-in-the-Loop Correction Console
/// ═══════════════════════════════════════════════════════════════════════════════

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with TickerProviderStateMixin {
  final _correctionController = TextEditingController();
  List<ReviewItem> _queue = [];
  bool _isLoading = true;
  bool _isOnline = true;
  String? _error;
  int _correctedCount = 0;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _loadQueue();
  }

  @override
  void dispose() {
    _correctionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    
    final result = await ApiService.getReviewQueue();
    
    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _queue = result.data ?? [];
        _isOnline = true;
        _error = null;
        if (_queue.isNotEmpty) {
          _correctionController.text = _queue[0].suggestion ?? _queue[0].ocrValue;
        }
      } else {
        _isOnline = false;
        _error = result.error;
      }
    });
  }

  Future<void> _handleApprove() async {
    if (_queue.isEmpty) return;
    
    HapticFeedback.heavyImpact();
    final item = _queue[0];
    
    await ApiService.submitCorrection(
      docId: item.docId,
      fieldName: item.field,
      originalValue: item.ocrValue,
      correctedValue: _correctionController.text,
    );
    
    setState(() {
      _correctedCount++;
      _queue.removeAt(0);
      if (_queue.isNotEmpty) {
        _correctionController.text = _queue[0].suggestion ?? _queue[0].ocrValue;
      }
    });
  }

  Future<void> _handleSkip() async {
    if (_queue.isEmpty) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _queue.removeAt(0);
      if (_queue.isNotEmpty) {
        _correctionController.text = _queue[0].suggestion ?? _queue[0].ocrValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading 
                    ? _buildLoadingState()
                    : _queue.isEmpty 
                        ? _buildEmptyState()
                        : _buildReviewContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(DS.space4, DS.space3, DS.space4, DS.space4),
          decoration: BoxDecoration(
            color: DS.surface.withOpacity(0.85),
            border: Border(bottom: BorderSide(color: DS.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: DS.primaryGradient,
                  borderRadius: BorderRadius.circular(DS.radiusMd),
                ),
                child: const Icon(Iconsax.edit_2, color: Colors.white, size: 20),
              ),
              const SizedBox(width: DS.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review Console', style: DS.heading3()),
                    Text(
                      '${_queue.length} items pending • $_correctedCount corrected',
                      style: DS.bodySmall(),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: _isOnline ? 'ONLINE' : 'OFFLINE',
                color: _isOnline ? DS.success : DS.error,
                pulse: _isOnline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DS.primary.withOpacity(0.3 + _pulseController.value * 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Iconsax.refresh,
                color: DS.primary.withOpacity(0.5 + _pulseController.value * 0.5),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: DS.space4),
          Text('Loading review queue...', style: DS.body(color: DS.textMuted)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.success.withOpacity(0.1),
                border: Border.all(color: DS.success.withOpacity(0.3), width: 2),
              ),
              child: Icon(Iconsax.tick_circle, size: 56, color: DS.success),
            ),
            const SizedBox(height: DS.space6),
            Text('All Caught Up!', style: DS.heading2()),
            const SizedBox(height: DS.space2),
            Text(
              'No items pending review.\nUpload documents to get started.',
              style: DS.bodySmall(),
              textAlign: TextAlign.center,
            ),
            if (_correctedCount > 0) ...[
              const SizedBox(height: DS.space6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: DS.space4, vertical: DS.space3),
                decoration: BoxDecoration(
                  color: DS.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: Border.all(color: DS.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.medal, size: 18, color: DS.primary),
                    const SizedBox(width: DS.space2),
                    Text(
                      '$_correctedCount corrections this session',
                      style: DS.body(color: DS.primary, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    final item = _queue[0];
    
    return Padding(
      padding: const EdgeInsets.all(DS.space4),
      child: Column(
        children: [
          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: DS.space4),
          
          // Current item card
          Expanded(
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: GlassCard(
                padding: const EdgeInsets.all(DS.space5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(DS.space2),
                          decoration: BoxDecoration(
                            color: DS.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(DS.radiusSm),
                          ),
                          child: Icon(Iconsax.document, size: 18, color: DS.primary),
                        ),
                        const SizedBox(width: DS.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.docId, 
                                  style: DS.mono(size: 12, color: DS.primary, weight: FontWeight.bold)),
                              Text(item.docType, style: DS.caption()),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: DS.space3, vertical: DS.space1),
                          decoration: BoxDecoration(
                            color: DS.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(DS.radiusFull),
                          ),
                          child: Text(
                            '${item.confidence}% conf',
                            style: DS.caption(color: DS.warning),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: DS.space6),
                    
                    // Field info
                    Text('FIELD', style: DS.label()),
                    const SizedBox(height: DS.space2),
                    Text(item.field.replaceAll('_', ' ').toUpperCase(), 
                        style: DS.heading3()),
                    
                    const SizedBox(height: DS.space4),
                    
                    // OCR Value (original)
                    Text('ORIGINAL VALUE', style: DS.label()),
                    const SizedBox(height: DS.space2),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DS.space3),
                      decoration: BoxDecoration(
                        color: DS.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(DS.radiusMd),
                        border: Border.all(color: DS.error.withOpacity(0.2)),
                      ),
                      child: Text(item.ocrValue, style: DS.mono(size: 14, color: DS.error)),
                    ),
                    
                    const SizedBox(height: DS.space4),
                    
                    // Correction input
                    Text('CORRECTED VALUE', style: DS.label(color: DS.success)),
                    const SizedBox(height: DS.space2),
                    Container(
                      decoration: BoxDecoration(
                        color: DS.surfaceElevated,
                        borderRadius: BorderRadius.circular(DS.radiusMd),
                        border: Border.all(color: DS.success.withOpacity(0.3)),
                        boxShadow: DS.glowSubtle(DS.success),
                      ),
                      child: TextField(
                        controller: _correctionController,
                        style: DS.mono(size: 14, color: DS.success),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(DS.space3),
                          hintText: 'Enter corrected value...',
                          hintStyle: DS.mono(size: 14, color: DS.textMuted),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'SKIP',
                            icon: Iconsax.arrow_right_3,
                            color: DS.textMuted,
                            onTap: _handleSkip,
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: DS.space3),
                        Expanded(
                          flex: 2,
                          child: GradientButton(
                            label: 'APPROVE',
                            icon: Iconsax.tick_circle,
                            onPressed: _handleApprove,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = _queue.length + _correctedCount;
    final progress = total > 0 ? _correctedCount / total : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(DS.space3),
      decoration: BoxDecoration(
        color: DS.surfaceElevated,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: DS.border),
      ),
      child: Row(
        children: [
          Icon(Iconsax.activity, size: 16, color: DS.textMuted),
          const SizedBox(width: DS.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Session Progress', style: DS.caption()),
                    Text('$_correctedCount / $total', style: DS.mono(size: 11)),
                  ],
                ),
                const SizedBox(height: DS.space1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: DS.border,
                    color: DS.primary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(DS.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.space4, vertical: DS.space3),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DS.radiusMd),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: DS.space2),
              Text(label, style: DS.label(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

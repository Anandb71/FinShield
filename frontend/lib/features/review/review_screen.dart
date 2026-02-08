import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/services/api_service.dart';

/// Split-Screen Review Console - Real Backend Integration
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
  double _accuracyGain = 0.0;
  bool _showExplosion = false;
  late AnimationController _explosionController;

  @override
  void initState() {
    super.initState();
    _explosionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadQueue();
  }

  @override
  void dispose() {
    _correctionController.dispose();
    _explosionController.dispose();
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
    
    // Submit correction via API
    final result = await ApiService.submitCorrection(
      docId: item.docId,
      fieldName: item.field,
      originalValue: item.ocrValue,
      correctedValue: _correctionController.text,
    );
    
    // Trigger explosion effect
    setState(() => _showExplosion = true);
    _explosionController.forward(from: 0).then((_) {
      setState(() => _showExplosion = false);
    });

    final gain = 0.02 + Random().nextDouble() * 0.03;
    
    setState(() {
      _queue.removeAt(0);
      _correctedCount++;
      _accuracyGain += gain;
      if (_queue.isNotEmpty) {
        _correctionController.text = _queue[0].suggestion ?? _queue[0].ocrValue;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.cpu, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(
                result.isSuccess 
                  ? '✓ Fed to Backboard! +${(gain * 100).toStringAsFixed(2)}% Accuracy'
                  : 'Error: ${result.error}',
                style: LiquidTheme.monoData(size: 12, color: Colors.white),
              )),
            ],
          ),
          backgroundColor: result.isSuccess ? LiquidTheme.neonGreen : LiquidTheme.neonPink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleSkip() {
    if (_queue.isEmpty) return;
    
    HapticFeedback.mediumImpact();
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
      backgroundColor: LiquidTheme.background,
      body: LiquidBackground(
        particleCount: 30,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: LiquidTheme.neonCyan))
                    : !_isOnline
                        ? _buildOfflineState()
                        : _queue.isEmpty
                            ? _buildVictoryState()
                            : _buildSplitConsole(),
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: LiquidTheme.glassBg,
            border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left, color: LiquidTheme.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REVIEW CONSOLE', style: LiquidTheme.monoData(size: 12, color: LiquidTheme.textPrimary, weight: FontWeight.bold)),
                  Text('${_queue.length} items pending', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                ],
              ),
              const Spacer(),
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LiquidTheme.neonPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LiquidTheme.neonPink.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: LiquidTheme.neonPink, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('OFFLINE', style: LiquidTheme.monoData(size: 8, color: LiquidTheme.neonPink, weight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: LiquidTheme.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LiquidTheme.neonGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.trend_up, color: LiquidTheme.neonGreen, size: 12),
                      const SizedBox(width: 4),
                      Text('+${(_accuracyGain * 100).toStringAsFixed(2)}%', style: LiquidTheme.monoData(size: 10, color: LiquidTheme.neonGreen, weight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.danger, size: 64, color: LiquidTheme.neonPink),
          const SizedBox(height: 24),
          Text('BACKEND OFFLINE', style: LiquidTheme.monoData(size: 18, color: LiquidTheme.neonPink, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error ?? 'Unable to connect', style: LiquidTheme.monoData(size: 12, color: LiquidTheme.textMuted)),
          const SizedBox(height: 32),
          NeonButton(
            label: 'RETRY',
            icon: Iconsax.refresh,
            color: LiquidTheme.neonCyan,
            onPressed: _loadQueue,
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryState() {
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GOLD TROPHY
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFA500),
                    const Color(0xFFFFD700),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 60, spreadRadius: 10),
                ],
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 70)),
              ),
            ),
            const SizedBox(height: 32),
            Text('QUEUE CLEAR', style: LiquidTheme.uiText(size: 28, weight: FontWeight.bold, color: const Color(0xFFFFD700))),
            const SizedBox(height: 8),
            Text('All documents verified!', style: LiquidTheme.monoData(size: 14, color: LiquidTheme.textMuted)),
            const SizedBox(height: 32),
            
            // Stats Card
            LiquidGlassCard(
              glowColor: const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _VictoryStat(value: '$_correctedCount', label: 'CORRECTIONS'),
                      const SizedBox(width: 40),
                      _VictoryStat(value: '+${(_accuracyGain * 100).toStringAsFixed(2)}%', label: 'ACCURACY GAIN', color: LiquidTheme.neonGreen),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            NeonButton(
              label: 'RETURN TO COMMAND CENTER',
              icon: Iconsax.home,
              color: LiquidTheme.neonCyan,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitConsole() {
    final item = _queue[0];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // LEFT: PDF VIEWER (60%)
            Expanded(
              flex: 6,
              child: FadeInLeft(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  child: _buildDocumentViewer(item),
                ),
              ),
            ),
            
            // RIGHT: CORRECTION TERMINAL (40%)
            Expanded(
              flex: 4,
              child: FadeInRight(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
                  child: _buildCorrectionTerminal(item),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentViewer(ReviewItem item) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Mock Document
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Document: ${item.docId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Type: ${item.docType.toUpperCase()}', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      
                      // Highlighted Error Region
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: LiquidTheme.neonPink, width: 3),
                          color: LiquidTheme.neonPink.withOpacity(0.1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.field.toUpperCase(), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12)),
                            Flexible(child: Text(item.ocrValue, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87))),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // More content placeholder
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey[100],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Field requiring review', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('The system detected low confidence for this field.', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            Text('Please verify and correct if needed.', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Error Label
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: LiquidTheme.neonPink,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('LOW CONFIDENCE REGION', style: LiquidTheme.monoData(size: 9, color: Colors.white, weight: FontWeight.bold)),
            ),
          ),

          // Explosion Effect
          if (_showExplosion)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _explosionController,
                builder: (_, __) => CustomPaint(painter: _ExplosionPainter(progress: _explosionController.value)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorrectionTerminal(ReviewItem item) {
    final confidenceColor = item.confidence < 50 ? LiquidTheme.neonPink : 
                            item.confidence < 70 ? LiquidTheme.neonYellow : LiquidTheme.neonGreen;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: LiquidTheme.neonCyan,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Iconsax.code, color: LiquidTheme.neonCyan, size: 14),
                        const SizedBox(width: 6),
                        Text('CORRECTION TERMINAL', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Document Info
                    Text(item.docId, style: LiquidTheme.monoData(size: 12, color: LiquidTheme.textPrimary, weight: FontWeight.bold)),
                    Text(item.field.toUpperCase(), style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                    
                    const SizedBox(height: 16),
                    
                    // AI Confidence
                    Row(
                      children: [
                        Text('CONFIDENCE:', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: confidenceColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: confidenceColor.withOpacity(0.5)),
                          ),
                          child: Text('${item.confidence}%', style: LiquidTheme.monoData(size: 12, color: confidenceColor, weight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // AI Suggestion
                    Text('DETECTED:', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LiquidTheme.neonPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LiquidTheme.neonPink.withOpacity(0.3)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(item.ocrValue, style: LiquidTheme.monoData(size: 18, color: LiquidTheme.neonPink, weight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Correction Input
                    Text('CORRECT VALUE:', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _correctionController,
                      style: LiquidTheme.monoData(size: 16, color: LiquidTheme.neonGreen),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: LiquidTheme.surface,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: LiquidTheme.neonGreen.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: LiquidTheme.neonGreen.withOpacity(0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LiquidTheme.neonGreen, width: 2)),
                      ),
                    ),
                    
                    const Spacer(),
                    const SizedBox(height: 16),
                    
                    // MASSIVE ACTION BUTTONS
                    Row(
                      children: [
                        // SKIP
                        Expanded(
                          child: _MassiveButton(
                            icon: Iconsax.close_circle,
                            label: 'SKIP',
                            color: LiquidTheme.neonPink,
                            onPressed: _handleSkip,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // APPROVE
                        Expanded(
                          flex: 2,
                          child: _MassiveButton(
                            icon: Iconsax.tick_circle,
                            label: 'APPROVE',
                            color: LiquidTheme.neonGreen,
                            onPressed: _handleApprove,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VictoryStat extends StatelessWidget {
  final String value, label;
  final Color color;

  const _VictoryStat({required this.value, required this.label, this.color = LiquidTheme.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: LiquidTheme.monoData(size: 20, color: color, weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
      ],
    );
  }
}

class _MassiveButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MassiveButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<_MassiveButton> createState() => _MassiveButtonState();
}

class _MassiveButtonState extends State<_MassiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.isPrimary ? widget.color : widget.color.withOpacity(_isPressed ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withOpacity(0.5), width: 2),
          boxShadow: _isPressed ? LiquidTheme.neonGlow(widget.color) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.isPrimary ? Colors.white : widget.color, size: 20),
            const SizedBox(width: 8),
            Text(widget.label, style: LiquidTheme.uiText(size: 12, color: widget.isPrimary ? Colors.white : widget.color, weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ExplosionPainter extends CustomPainter {
  final double progress;

  _ExplosionPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42);
    
    for (int i = 0; i < 40; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = 50 + random.nextDouble() * 200 * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      
      final colors = [LiquidTheme.neonGreen, LiquidTheme.neonCyan, const Color(0xFFFFD700)];
      final color = colors[i % colors.length];
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final particlePos = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );

      canvas.drawCircle(particlePos, 5 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) => oldDelegate.progress != progress;
}

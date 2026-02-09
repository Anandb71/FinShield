import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/app_theme.dart';

/// Human Review Queue - Queue-based correction interface
class HumanReviewQueue extends StatefulWidget {
  const HumanReviewQueue({super.key});

  @override
  State<HumanReviewQueue> createState() => _HumanReviewQueueState();
}

class _HumanReviewQueueState extends State<HumanReviewQueue> {
  final _correctionController = TextEditingController();
  int _currentIndex = 0;
  int _correctedCount = 0;

  final _reviewQueue = [
    {'docId': 'DOC-1026', 'field': 'Invoice Date', 'ocr': '0ct 24, 2024', 'expected': 'Oct 24, 2024', 'confidence': 67, 'reason': 'OCR confusion: 0 vs O'},
    {'docId': 'DOC-1031', 'field': 'Total Amount', 'ocr': '₹55,00', 'expected': '₹55,000', 'confidence': 72, 'reason': 'Missing digit'},
    {'docId': 'DOC-1033', 'field': 'Vendor GSTIN', 'ocr': '27AAACA1234A1Z', 'expected': '27AAACA1234A1ZV', 'confidence': 58, 'reason': 'Truncated field'},
    {'docId': 'DOC-1045', 'field': 'Due Date', 'ocr': 'Nov 31, 2024', 'expected': 'Nov 30, 2024', 'confidence': 45, 'reason': 'Invalid date'},
    {'docId': 'DOC-1048', 'field': 'Bank IFSC', 'ocr': 'HDFC0001234', 'expected': 'HDFC0012345', 'confidence': 62, 'reason': 'Digit transposition'},
  ];

  @override
  void initState() {
    super.initState();
    _correctionController.text = _reviewQueue[0]['expected'] as String;
  }

  @override
  void dispose() {
    _correctionController.dispose();
    super.dispose();
  }

  void _handleCorrect() {
    HapticFeedback.mediumImpact();
    setState(() => _correctedCount++);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.cpu, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text('Correction logged. Retraining trigger queued.', style: GoogleFonts.jetBrainsMono(fontSize: 12))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    _moveToNext();
  }

  void _handleSkip() {
    _moveToNext();
  }

  void _moveToNext() {
    if (_currentIndex < _reviewQueue.length - 1) {
      setState(() {
        _currentIndex++;
        _correctionController.text = _reviewQueue[_currentIndex]['expected'] as String;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _reviewQueue[_currentIndex];
    final remaining = _reviewQueue.length - _currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text('REVIEW QUEUE', style: GoogleFonts.jetBrainsMono(fontSize: 14)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('$remaining remaining', style: GoogleFonts.jetBrainsMono(color: AppColors.warning, fontSize: 11)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROGRESS BAR
            FadeInDown(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11)),
                      Text('$_correctedCount corrected', style: GoogleFonts.jetBrainsMono(color: AppColors.success, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _reviewQueue.length,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // DOC ID + CONFIDENCE
            FadeIn(
              child: Row(
                children: [
                  Text(item['docId'] as String, style: GoogleFonts.jetBrainsMono(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('${item['confidence']}% confidence', style: GoogleFonts.jetBrainsMono(color: AppColors.warning, fontSize: 10)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(item['field'] as String, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),

            const SizedBox(height: 20),

            // OCR VALUE BOX
            FadeInLeft(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.cpu, color: AppColors.danger, size: 14),
                        const SizedBox(width: 8),
                        Text('AI READ:', style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item['ocr'] as String, style: GoogleFonts.jetBrainsMono(color: AppColors.danger, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item['reason'] as String, style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CORRECTION INPUT
            Text('YOUR CORRECTION:', style: GoogleFonts.jetBrainsMono(color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 8),
            TextField(
              controller: _correctionController,
              style: GoogleFonts.jetBrainsMono(color: AppColors.success, fontSize: 22),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D0D14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.success.withOpacity(0.5))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.success.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.success)),
              ),
            ),

            const Spacer(),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleSkip,
                    icon: const Icon(Iconsax.arrow_right_3),
                    label: Text('SKIP', style: GoogleFonts.jetBrainsMono()),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted, padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _handleCorrect,
                    icon: const Icon(Iconsax.tick_circle),
                    label: Text('CORRECT & RETRAIN', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

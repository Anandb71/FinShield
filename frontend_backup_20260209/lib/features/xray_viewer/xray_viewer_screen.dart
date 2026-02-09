import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/app_theme.dart';
import 'widgets/mock_document.dart';
import 'widgets/bounding_box_layer.dart';
import 'widgets/data_panel.dart';
import 'widgets/reconciliation_tab.dart';

/// X-Ray Viewer - The Heart of Document Intelligence
class XRayViewerScreen extends ConsumerStatefulWidget {
  final String fileName;
  final Uint8List? fileBytes;

  const XRayViewerScreen({
    super.key,
    required this.fileName,
    this.fileBytes,
  });

  @override
  ConsumerState<XRayViewerScreen> createState() => _XRayViewerScreenState();
}

class _XRayViewerScreenState extends ConsumerState<XRayViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOverlays = true;
  bool _isProcessing = true;
  double _processingProgress = 0.0;

  // Mock extracted data (would come from backend in production)
  final Map<String, dynamic> _extractedData = {
    'document_type': 'INVOICE',
    'confidence': 0.97,
    'vendor': {'name': 'ACME Corporation', 'gstin': '27AAACA1234A1ZV'},
    'invoice_number': 'INV-2024-1024',
    'date': '2024-10-24',
    'due_date': '2024-11-24',
    'line_items': [
      {'description': 'Consulting Services', 'qty': 10, 'rate': 4500, 'amount': 45000},
      {'description': 'Server Maintenance', 'qty': 1, 'rate': 5000, 'amount': 5000},
    ],
    'subtotal': 50000,
    'tax_rate': 0.10,
    'tax_amount': 5000,
    'total': 55000,
  };

  final List<Map<String, dynamic>> _validationResults = [
    {'rule': 'Document Format', 'status': 'pass', 'detail': 'Valid invoice structure'},
    {'rule': 'Math Integrity', 'status': 'pass', 'detail': 'Subtotal + Tax = Total ✓'},
    {'rule': 'Date Sequence', 'status': 'pass', 'detail': 'Invoice Date < Due Date ✓'},
    {'rule': 'GSTIN Format', 'status': 'pass', 'detail': 'Valid 15-character format'},
    {'rule': 'Anomaly Scan', 'status': 'warning', 'detail': 'Handwritten note detected'},
  ];

  final List<Map<String, dynamic>> _memoryContext = [
    {'type': 'history', 'text': 'Vendor "ACME Corporation" found in 3 previous documents'},
    {'type': 'history', 'text': 'Average invoice amount: ₹48,500'},
    {'type': 'alert', 'text': 'Current amount (₹55,000) is 13% above average'},
    {'type': 'match', 'text': 'Bank account matches previous records ✓'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _simulateProcessing();
  }

  void _simulateProcessing() async {
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() => _processingProgress = i / 100);
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            if (!_isProcessing)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Processed • ${(_extractedData['confidence'] * 100).toInt()}% confidence',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOverlays ? Iconsax.eye : Iconsax.eye_slash,
              color: _showOverlays ? AppColors.primary : AppColors.textMuted,
            ),
            onPressed: () => setState(() => _showOverlays = !_showOverlays),
            tooltip: 'Toggle X-Ray Vision',
          ),
          IconButton(
            icon: const Icon(Iconsax.export),
            onPressed: () {},
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _isProcessing ? _buildProcessingView() : _buildMainView(),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _processingProgress,
                    strokeWidth: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                Text(
                  '${(_processingProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Analyzing Document',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _getProcessingStage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProcessingStage() {
    if (_processingProgress < 0.3) return 'Detecting layout structure...';
    if (_processingProgress < 0.5) return 'Extracting tables and entities...';
    if (_processingProgress < 0.7) return 'Running validation checks...';
    if (_processingProgress < 0.9) return 'Querying knowledge graph...';
    return 'Finalizing analysis...';
  }

  Widget _buildMainView() {
    return Column(
      children: [
        // X-RAY VIEWER (Top)
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Document Layer
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: const MockDocument(),
                    ),
                  ),
                  // Bounding Box Overlays
                  if (_showOverlays)
                    FadeIn(
                      child: BoundingBoxLayer(
                        onBoxTap: _handleBoxTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // DATA PANEL (Bottom)
        Expanded(
          flex: 4,
          child: FadeInUp(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Extracted'),
                        Tab(text: 'Validation'),
                        Tab(text: 'Memory'),
                        Tab(text: 'Reconcile'),
                      ],
                    ),
                  ),
                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        DataPanel.extracted(_extractedData),
                        DataPanel.validation(_validationResults),
                        DataPanel.memory(_memoryContext),
                        ReconciliationTab(
                          invoiceTotal: (_extractedData['total'] as int).toDouble(),
                          invoiceVendor: _extractedData['vendor']['name'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleBoxTap(String boxType) {
    if (boxType == 'anomaly') {
      _showLearningLoopDialog();
    }
  }

  void _showLearningLoopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.cpu, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Learning Loop'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2, color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Low confidence detected',
                      style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'OCR Read:',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '₹50,00',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expected (based on context):',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '₹5,000',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter correct value',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              controller: TextEditingController(text: '5,000'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignore'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Iconsax.tick_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text('Correction saved. Model learning triggered.'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Iconsax.tick_circle),
            label: const Text('Confirm Correction'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }
}

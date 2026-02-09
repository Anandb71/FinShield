import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/services/api_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// DOC INSPECTOR SCREEN - Professional Document Analysis View
/// ═══════════════════════════════════════════════════════════════════════════════

class DocInspectorScreen extends StatefulWidget {
  final DocumentAnalysisResult? document;
  final String? localPath;

  const DocInspectorScreen({
    super.key,
    this.document,
    this.localPath,
  });

  @override
  State<DocInspectorScreen> createState() => _DocInspectorScreenState();
}

class _DocInspectorScreenState extends State<DocInspectorScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Computed getters
  bool get _hasRealData => widget.document != null;
  String get _docId => widget.document?.documentId ?? 'DOC-1024';
  String get _docType => widget.document?.docType ?? 'INVOICE';
  String get _filename => widget.localPath?.split('/').last ?? 
                           widget.localPath?.split('\\').last ?? 
                           'sample_document.pdf';
  double get _confidence => widget.document?.confidence ?? 0.95;
  Map<String, dynamic> get _fields => widget.document?.extractedFields ?? {};
  List<String> get _layouts => widget.document?.layoutTags ?? [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                child: Row(
                  children: [
                    // Left: Document preview
                    Expanded(
                      flex: 5,
                      child: _buildDocumentPreview(),
                    ),
                    // Right: Analysis panel
                    Container(
                      width: 360,
                      decoration: BoxDecoration(
                        color: DS.surface,
                        border: Border(left: BorderSide(color: DS.border)),
                      ),
                      child: _buildAnalysisPanel(),
                    ),
                  ],
                ),
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
          padding: const EdgeInsets.fromLTRB(DS.space4, DS.space2, DS.space4, DS.space2),
          decoration: BoxDecoration(
            color: DS.surface.withOpacity(0.85),
            border: Border(bottom: BorderSide(color: DS.border)),
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Iconsax.arrow_left_2, color: DS.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              
              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docId,
                      style: DS.mono(size: 14, color: DS.primary, weight: FontWeight.w600),
                    ),
                    Text(
                      '$_docType • $_filename',
                      style: DS.caption(),
                    ),
                  ],
                ),
              ),
              
              // Layer toggles
              Row(
                children: [
                  _LayerToggle(label: 'TBL', icon: Iconsax.maximize_4, 
                      color: DS.primary, active: _layouts.contains('Table')),
                  const SizedBox(width: DS.space2),
                  _LayerToggle(label: 'HND', icon: Iconsax.edit, 
                      color: DS.warning, active: _layouts.contains('Handwritten')),
                  const SizedBox(width: DS.space2),
                  _LayerToggle(label: 'STP', icon: Iconsax.verify, 
                      color: DS.accent, active: _layouts.contains('Stamp')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Container(
      margin: const EdgeInsets.all(DS.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusLg),
        boxShadow: DS.shadowLg,
      ),
      child: Stack(
        children: [
          // Document content simulation
          Padding(
            padding: const EdgeInsets.all(DS.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  '$_docType: $_docId',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _filename,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                
                const Divider(height: 32),
                
                // Extracted fields preview
                ..._fields.entries.take(8).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          // Zoom controls overlay
          Positioned(
            bottom: DS.space4,
            right: DS.space4,
            child: Container(
              padding: const EdgeInsets.all(DS.space2),
              decoration: BoxDecoration(
                color: DS.surface,
                borderRadius: BorderRadius.circular(DS.radiusMd),
                border: Border.all(color: DS.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconBtn(icon: Iconsax.minus, onTap: () {}),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DS.space2),
                    child: Text('100%', style: DS.caption()),
                  ),
                  _IconBtn(icon: Iconsax.add, onTap: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel() {
    return Column(
      children: [
        // Trust score
        FadeInRight(
          duration: const Duration(milliseconds: 500),
          child: _buildTrustScore(),
        ),
        
        // Tabs
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: DS.border)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: DS.primary,
            unselectedLabelColor: DS.textMuted,
            indicatorColor: DS.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: DS.label(),
            tabs: const [
              Tab(text: 'LOGIC'),
              Tab(text: 'DATA'),
              Tab(text: 'LINKS'),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLogicTab(),
              _buildDataTab(),
              _buildLinksTab(),
            ],
          ),
        ),
        
        // Review button
        Padding(
          padding: const EdgeInsets.all(DS.space4),
          child: GradientButton(
            label: 'REVIEW',
            icon: Iconsax.edit_2,
            onPressed: () {},
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustScore() {
    final score = (_confidence * 100).round();
    final scoreColor = score >= 90 ? DS.success : score >= 70 ? DS.warning : DS.error;
    
    return Container(
      padding: const EdgeInsets.all(DS.space4),
      child: Row(
        children: [
          // Gauge
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 6,
                    backgroundColor: scoreColor.withOpacity(0.15),
                    color: Colors.transparent,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: _confidence),
                  builder: (_, v, __) => SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      color: scoreColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$score', style: DS.stat(color: scoreColor)),
                    Text('TRUST', style: DS.caption()),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: DS.space4),
          
          // Breakdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreItem(label: 'Validation', delta: -20, positive: false),
                const SizedBox(height: DS.space2),
                _ScoreItem(label: 'High ML confidence', delta: 10, positive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogicTab() {
    final validation = widget.document?.validation;
    final errors = validation?.errors ?? [];
    final warnings = validation?.warnings ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(DS.space4),
      children: [
        if (errors.isNotEmpty)
          ...errors.map((e) => _ValidationItem(
            type: 'FAIL',
            message: e,
            color: DS.error,
          )),
        if (warnings.isNotEmpty)
          ...warnings.map((w) => _ValidationItem(
            type: 'WARN',
            message: w,
            color: DS.warning,
          )),
        if (errors.isEmpty && warnings.isEmpty)
          _ValidationItem(
            type: 'PASS',
            message: 'High confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
            color: DS.success,
          ),
      ],
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(DS.space4),
      children: _fields.entries.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: DS.space3),
        child: _FieldItem(
          fieldName: entry.key,
          value: entry.value.toString(),
        ),
      )).toList(),
    );
  }

  Widget _buildLinksTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DS.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.hierarchy_3, size: 48, color: DS.textMuted.withOpacity(0.5)),
            const SizedBox(height: DS.space4),
            Text('Knowledge Graph', style: DS.heading3(color: DS.textMuted)),
            Text('Entity links will appear here', style: DS.bodySmall()),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _LayerToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;

  const _LayerToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.space3, vertical: DS.space1),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: active ? color.withOpacity(0.3) : DS.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: active ? color : DS.textMuted),
          const SizedBox(width: 4),
          Text(label, style: DS.caption(color: active ? color : DS.textMuted)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 16, color: DS.textMuted),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int delta;
  final bool positive;

  const _ScoreItem({
    required this.label,
    required this.delta,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? DS.success : DS.error;
    return Row(
      children: [
        Text(
          '${positive ? '+' : ''}$delta',
          style: DS.mono(size: 12, color: color, weight: FontWeight.bold),
        ),
        const SizedBox(width: DS.space2),
        Expanded(
          child: Text(label, style: DS.bodySmall()),
        ),
      ],
    );
  }
}

class _ValidationItem extends StatelessWidget {
  final String type;
  final String message;
  final Color color;

  const _ValidationItem({
    required this.type,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DS.space2),
      padding: const EdgeInsets.all(DS.space3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DS.space2, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(DS.radiusSm),
            ),
            child: Text(
              '[$type]',
              style: DS.caption(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: DS.space3),
          Expanded(
            child: Text(message, style: DS.bodySmall()),
          ),
        ],
      ),
    );
  }
}

class _FieldItem extends StatelessWidget {
  final String fieldName;
  final String value;

  const _FieldItem({
    required this.fieldName,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DS.space3),
      decoration: BoxDecoration(
        color: DS.surfaceElevated,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: DS.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName.replaceAll('_', ' ').toUpperCase(),
            style: DS.label(),
          ),
          const SizedBox(height: DS.space1),
          Text(value, style: DS.body()),
        ],
      ),
    );
  }
}

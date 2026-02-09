import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../core/providers/navigation_provider.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/services/api_service.dart';
import 'trust_score_widget.dart';
import '../review/review_screen.dart';

/// Deep Inspection View - Real Data Binding
/// Accepts optional DocumentAnalysisResult for real data display
import 'dart:typed_data';


// ... (keep matches)

class DocInspectorScreen extends StatefulWidget {
  final DocumentAnalysisResult? document;
  final String? localPath;
  final Uint8List? fileBytes;

  const DocInspectorScreen({super.key, this.document, this.localPath, this.fileBytes});

  @override
  State<DocInspectorScreen> createState() => _DocInspectorScreenState();
}

class _DocInspectorScreenState extends State<DocInspectorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _showTables = true;
  bool _showHandwritten = true;
  bool _showStamps = false;

  // ... (keep getters)

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
      backgroundColor: LiquidTheme.background,
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 5, child: FadeIn(child: _buildDocumentViewer())),
                    Expanded(flex: 3, child: FadeInRight(child: _buildOutputPanel())),
                  ],
                ),
              ),
              // Spacer for Floating Nav
              const SizedBox(height: 100),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_docId, style: LiquidTheme.monoData(size: 12, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
                    Text('$_docType • $_filename', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (!_hasRealData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LiquidTheme.neonYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LiquidTheme.neonYellow.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: LiquidTheme.neonYellow, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('DEMO MODE', style: LiquidTheme.monoData(size: 8, color: LiquidTheme.neonYellow, weight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(width: 10),
              Text('LAYERS:', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
              const SizedBox(width: 10),
              _ToggleButton(icon: Iconsax.maximize_4, label: 'TBL', color: LiquidTheme.neonCyan, isActive: _showTables || _layouts.contains('Table'), onTap: () => setState(() => _showTables = !_showTables)),
              const SizedBox(width: 6),
              _ToggleButton(icon: Iconsax.edit, label: 'HND', color: LiquidTheme.neonYellow, isActive: _showHandwritten || _layouts.contains('Handwritten'), onTap: () => setState(() => _showHandwritten = !_showHandwritten)),
              const SizedBox(width: 6),
              _ToggleButton(icon: Iconsax.verify, label: 'STP', color: LiquidTheme.neonPink, isActive: _showStamps || _layouts.contains('Stamp'), onTap: () => setState(() => _showStamps = !_showStamps)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: LiquidGlassCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: LiquidTheme.neonGlow(LiquidTheme.neonCyan, intensity: 0.2),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Iconsax.document, size: 48, color: LiquidTheme.neonCyan),
                    SizedBox(height: 16),
                    Text('PDF Viewer Placeholder', style: TextStyle(color: LiquidTheme.textPrimary)),
                  ],
                ),
              )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _hasRealData ? _buildRealDocContent() : _buildDemoDocContent(),
                        );
                      },
                    ),
            ),
            // ... (keep overlays)
          ],
        ),
      ),
    );
  }

  Widget _buildRealDocContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_docType: $_docId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        Text(_filename, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text('Confidence: ${(_confidence * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 24),
        
        // Show extracted fields
        if (_fields.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              children: _fields.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[700])),
                    Flexible(child: Text('${e.value}', textAlign: TextAlign.right)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ] else
          Center(
            child: Column(
              children: [
                Icon(Iconsax.document_text, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Document processed', style: TextStyle(color: Colors.grey[600])),
                Text('Visual preview not available', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDemoDocContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INVOICE #INV-1024', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        Text('ACME Corporation', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text('GSTIN: 27AAACA1234A1ZV', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Consulting Services'), Text('₹45,000')]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Maintenance'), Text('₹5,000')]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Tax (18%)'), Text('₹9,000')]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)), Text('₹59,000', style: TextStyle(fontWeight: FontWeight.bold))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutputPanel() {
    // Calculate trust score from confidence and validation
    int trustScore = _hasRealData 
        ? ((_confidence * 100).round())
        : 85;

    List<ScoreFactor> factors = _hasRealData && widget.document != null
        ? [
            if (widget.document!.validation.valid)
              const ScoreFactor(delta: 15, label: 'Validation Passed'),
            if (!widget.document!.validation.valid)
              const ScoreFactor(delta: -20, label: 'Validation Failed'),
            for (var warning in widget.document!.validation.warnings.take(2))
              ScoreFactor(delta: -5, label: warning),
            if (_confidence > 0.9)
              const ScoreFactor(delta: 10, label: 'High ML Confidence'),
          ]
        : [
            const ScoreFactor(delta: 15, label: 'Vendor History Match'),
            const ScoreFactor(delta: 10, label: 'Math Checks Out'),
            const ScoreFactor(delta: -5, label: 'Blurry Stamp Detected'),
          ];

    return Container(
      margin: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
      child: Column(
        children: [
          // TRUST SCORE
          LiquidGlassCard(
            glowColor: LiquidTheme.neonCyan,
            padding: const EdgeInsets.all(14),
            child: TrustScoreWidget(
              score: trustScore,
              factors: factors,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // TABS
          Expanded(
            child: LiquidGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder))),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: LiquidTheme.neonCyan,
                      labelStyle: LiquidTheme.monoData(size: 9, weight: FontWeight.bold),
                      unselectedLabelColor: LiquidTheme.textMuted,
                      tabs: const [Tab(text: 'LOGIC'), Tab(text: 'DATA'), Tab(text: 'LINKS')],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLogicConsole(), _buildStructuredData(), _buildEntityLinks()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // REVIEW BUTTON
          NeonButton(
            label: 'REVIEW',
            icon: Iconsax.edit_2,
            color: LiquidTheme.neonPink,
            onPressed: () => context.read<NavigationProvider>().setIndex(1),
          ),
        ],
      ),
    );
  }

  Widget _buildLogicConsole() {
    final logs = <(String, String)>[];
    
    if (_hasRealData && widget.document != null) {
      // Real validation results
      final validation = widget.document!.validation;
      if (validation.valid) {
        logs.add(('PASS', 'Document validated successfully'));
      }
      for (var error in validation.errors) {
        logs.add(('FAIL', error));
      }
      for (var warning in validation.warnings) {
        logs.add(('WARN', warning));
      }
      if (_confidence > 0.9) {
        logs.add(('PASS', 'High confidence: ${(_confidence * 100).toStringAsFixed(1)}%'));
      } else if (_confidence < 0.7) {
        logs.add(('WARN', 'Low confidence: ${(_confidence * 100).toStringAsFixed(1)}%'));
      }
      if (logs.isEmpty) {
        logs.add(('PASS', 'No issues detected'));
      }
    } else {
      // Demo data
      logs.addAll([
        ('PASS', 'Date Sequencing (Invoice < Due)'),
        ('PASS', 'GSTIN Format Valid'),
        ('PASS', 'Line Items Sum = Subtotal'),
        ('FAIL', 'Balance (50000 + 9000 ≠ 59000)'),
        ('WARN', 'Handwritten annotation'),
      ]);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final (status, msg) = logs[index];
        Color color;
        switch (status) {
          case 'PASS': color = LiquidTheme.neonGreen; break;
          case 'FAIL': color = LiquidTheme.neonPink; break;
          default: color = LiquidTheme.neonYellow;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                child: Text('[$status]', style: LiquidTheme.monoData(size: 8, color: color, weight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(msg, style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textSecondary))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStructuredData() {
    String jsonDisplay;
    
    if (_hasRealData) {
      // Real data
      final buffer = StringBuffer();
      buffer.writeln('{');
      buffer.writeln('  "document_id": "$_docId",');
      buffer.writeln('  "type": "$_docType",');
      buffer.writeln('  "confidence": ${(_confidence * 100).toStringAsFixed(1)}%,');
      if (_fields.isNotEmpty) {
        buffer.writeln('  "extracted_fields": {');
        var i = 0;
        _fields.forEach((k, v) {
          final comma = ++i < _fields.length ? ',' : '';
          buffer.writeln('    "$k": "$v"$comma');
        });
        buffer.writeln('  }');
      }
      buffer.writeln('}');
      jsonDisplay = buffer.toString();
    } else {
      jsonDisplay = '''
{
  "type": "INVOICE",
  "vendor": {
    "name": "ACME Corp",
    "gstin": "27AAACA1234A1ZV"
  },
  "invoice": "INV-1024",
  "date": "2024-10-01",
  "total": 59000
}''';
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Text(
        jsonDisplay,
        style: LiquidTheme.monoData(size: 10, color: LiquidTheme.neonCyan),
      ),
    );
  }

  Widget _buildEntityLinks() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('RELATED DOCS', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textMuted)),
        const SizedBox(height: 10),
        if (_hasRealData)
          Center(
            child: Column(
              children: [
                Icon(Iconsax.link, size: 32, color: LiquidTheme.textMuted.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text('Entity matching', style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textMuted)),
                Text('requires more documents', style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textMuted)),
              ],
            ),
          )
        else ...[
          const _EntityRow(docId: 'DOC-0812', match: 'Same Vendor', confidence: 98),
          const _EntityRow(docId: 'DOC-0915', match: 'Same Vendor', confidence: 95),
          const _EntityRow(docId: 'DOC-0928', match: 'Same Bank', confidence: 88),
        ],
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({required this.icon, required this.label, required this.color, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? color.withOpacity(0.5) : LiquidTheme.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : LiquidTheme.textMuted, size: 12),
            const SizedBox(width: 4),
            Text(label, style: LiquidTheme.monoData(size: 8, color: isActive ? color : LiquidTheme.textMuted, weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  final double left, top, width, height;
  final Color color;
  final String label;

  const _Overlay({required this.left, required this.top, required this.width, required this.height, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          color: color.withOpacity(0.1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            color: color,
            child: Text(label, style: LiquidTheme.monoData(size: 7, color: Colors.white, weight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _EntityRow extends StatelessWidget {
  final String docId, match;
  final int confidence;

  const _EntityRow({required this.docId, required this.match, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: LiquidTheme.liquidGlassCard(),
      child: Row(
        children: [
          Text(docId, style: LiquidTheme.monoData(size: 10, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Text(match, style: LiquidTheme.monoData(size: 9, color: LiquidTheme.textSecondary))),
          Text('$confidence%', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.neonGreen, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}

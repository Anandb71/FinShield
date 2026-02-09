import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphview/GraphView.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../core/theme/liquid_theme.dart';
import '../xray_viewer/xray_viewer_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// INVESTIGATION GRAPH - Premium Knowledge Graph Visualization
/// ═══════════════════════════════════════════════════════════════════════════════

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> with TickerProviderStateMixin {
  final Graph _graph = Graph()..isTree = false;
  late Algorithm _builder;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  // Time Slider State
  double _timeSliderValue = 2.0;
  
  // Selected node
  String? _selectedNode;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    final config = BuchheimWalkerConfiguration()
      ..siblingSeparation = 120
      ..levelSeparation = 180
      ..subtreeSeparation = 150
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    _builder = BuchheimWalkerAlgorithm(config, ArrowEdgeRenderer());
    
    _buildGraphData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _buildGraphData() {
    // Nodes represent documents and entities
    final node1 = Node.Id('INV-1024');
    final node2 = Node.Id('ACME Corp');
    final node3 = Node.Id('+91-9876543210');
    final node4 = Node.Id('Shell Co');
    final node5 = Node.Id('Employee #42');
    final node6 = Node.Id('123 Tech Park');

    _graph.addNode(node1);
    _graph.addNode(node2);
    _graph.addNode(node3);
    _graph.addNode(node4);
    _graph.addNode(node5);
    _graph.addNode(node6);

    // Edges with styling
    _graph.addEdge(node1, node2, paint: Paint()..color = DS.textMuted..strokeWidth = 2);
    _graph.addEdge(node2, node3, paint: Paint()..color = DS.textMuted..strokeWidth = 2);
    _graph.addEdge(node3, node4, paint: Paint()..color = DS.error..strokeWidth = 3);
    _graph.addEdge(node5, node6, paint: Paint()..color = DS.textMuted..strokeWidth = 2);
    _graph.addEdge(node2, node6, paint: Paint()..color = DS.error..strokeWidth = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // GRAPH VIEW
              InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.3,
                maxScale: 3.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 120, bottom: 160),
                  child: GraphView(
                    graph: _graph,
                    algorithm: _builder,
                    paint: Paint()
                      ..color = DS.border.withOpacity(0.3)
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      final id = node.key!.value as String;
                      return _buildNodeWidget(id);
                    },
                  ),
                ),
              ),
              
              // HEADER
              _buildHeader(),
              
              // TIMELINE SLIDER
              _buildTimelineSlider(),
              
              // LEGEND
              _buildLegend(),
              
              // DETAILS PANEL (when node selected)
              if (_selectedNode != null)
                _buildDetailsPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(DS.space4),
            decoration: BoxDecoration(
              color: DS.surface.withOpacity(0.8),
              border: Border(bottom: BorderSide(color: DS.border)),
            ),
            child: FadeInDown(
              child: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DS.primary, DS.accent],
                      ),
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                    ),
                    child: const Icon(Iconsax.hierarchy_2, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: DS.space3),
                  
                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Investigation Board', style: LiquidTheme.heading(size: 18)),
                      Text('Forensic Knowledge Graph', style: DS.caption()),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Alert Badge
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: DS.space3, vertical: DS.space2),
                        decoration: BoxDecoration(
                          color: DS.error.withOpacity(0.1 + _pulseController.value * 0.05),
                          borderRadius: BorderRadius.circular(DS.radiusFull),
                          border: Border.all(color: DS.error.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.warning_2, color: DS.error, size: 14),
                            const SizedBox(width: DS.space2),
                            Text(
                              '2 Conflicts',
                              style: TextStyle(color: DS.error, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSlider() {
    return Positioned(
      bottom: DS.space4,
      left: DS.space4,
      right: DS.space4,
      child: FadeInUp(
        child: GlassCard(
          padding: const EdgeInsets.all(DS.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.calendar_1, size: 14, color: DS.textMuted),
                  const SizedBox(width: DS.space2),
                  Text('Timeline Filter', style: DS.caption()),
                ],
              ),
              const SizedBox(height: DS.space2),
              Row(
                children: [
                  Text('Jan', style: DS.mono(
                    size: 11,
                    color: _timeSliderValue == 0 ? DS.primary : DS.textMuted,
                  )),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: DS.primary,
                        inactiveTrackColor: DS.surfaceElevated,
                        thumbColor: DS.primary,
                        overlayColor: DS.primary.withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _timeSliderValue,
                        min: 0,
                        max: 2,
                        divisions: 2,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _timeSliderValue = value);
                        },
                      ),
                    ),
                  ),
                  Text('Mar', style: DS.mono(
                    size: 11,
                    color: _timeSliderValue == 2 ? DS.primary : DS.textMuted,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 120,
      right: DS.space4,
      child: FadeInRight(
        child: GlassCard(
          padding: const EdgeInsets.all(DS.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Legend', style: DS.caption()),
              const SizedBox(height: DS.space2),
              _LegendItem(color: DS.primary, label: 'Document'),
              const SizedBox(height: DS.space1),
              _LegendItem(color: DS.warning, label: 'Entity'),
              const SizedBox(height: DS.space1),
              _LegendItem(color: DS.error, label: 'Anomaly'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPanel() {
    return Positioned(
      left: DS.space4,
      bottom: 120,
      child: FadeInLeft(
        child: SizedBox(
          width: 220,
          child: GlassCard(
            padding: const EdgeInsets.all(DS.space4),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_getNodeIcon(_selectedNode!), color: _getNodeColor(_selectedNode!), size: 16),
                  const SizedBox(width: DS.space2),
                  Expanded(
                    child: Text(
                      _selectedNode!,
                      style: DS.body(weight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedNode = null),
                    child: Icon(Iconsax.close_circle, size: 16, color: DS.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: DS.space3),
              _DetailRow(label: 'Type', value: _getNodeType(_selectedNode!)),
              _DetailRow(label: 'Connections', value: '3'),
              _DetailRow(label: 'Risk Score', value: _selectedNode!.contains('Shell') ? 'HIGH' : 'LOW'),
              const SizedBox(height: DS.space3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedNode!.startsWith('INV')) {
                      _openDocumentViewer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: DS.space2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                    ),
                  ),
                  child: Text('View Details', style: DS.bodySmall(color: Colors.white)),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(String id) {
    final isSelected = _selectedNode == id;
    final isAnomaly = id == 'Shell Co' || id.contains('Shell');
    final nodeColor = _getNodeColor(id);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedNode = _selectedNode == id ? null : id);
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowIntensity = isAnomaly ? 0.3 + _glowController.value * 0.2 : 0.0;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: DS.space4, vertical: DS.space3),
            decoration: BoxDecoration(
              color: DS.surface,
              borderRadius: BorderRadius.circular(DS.radiusMd),
              border: Border.all(
                color: isSelected ? nodeColor : nodeColor.withOpacity(0.5),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withOpacity(isSelected ? 0.4 : (isAnomaly ? glowIntensity : 0.15)),
                  blurRadius: isSelected ? 20 : (isAnomaly ? 15 : 8),
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getNodeIcon(id), color: nodeColor, size: 22),
                const SizedBox(height: DS.space1),
                Text(
                  id.length > 15 ? '${id.substring(0, 12)}...' : id,
                  style: DS.mono(size: 10, color: DS.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getNodeColor(String id) {
    if (id.startsWith('INV')) return DS.primary;
    if (id == 'Shell Co') return DS.error;
    return DS.warning;
  }

  IconData _getNodeIcon(String id) {
    if (id.startsWith('INV')) return Iconsax.document_text;
    if (id == 'Shell Co') return Iconsax.warning_2;
    if (id.contains('Employee')) return Iconsax.user;
    if (id.contains('+')) return Iconsax.call;
    if (id.contains('Park') || id.contains('Tech')) return Iconsax.location;
    return Iconsax.building;
  }

  String _getNodeType(String id) {
    if (id.startsWith('INV')) return 'Document';
    if (id == 'Shell Co') return 'Anomaly';
    if (id.contains('Employee')) return 'Person';
    if (id.contains('+')) return 'Phone';
    if (id.contains('Park')) return 'Address';
    return 'Organization';
  }

  void _openDocumentViewer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: constraints.maxHeight * 0.9,
              color: DS.background,
              child: const XRayViewerScreen(
                fileName: 'INV-1024.pdf',
              ),
            ),
          );
        }
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DS.space2),
        Text(label, style: DS.caption()),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isHighRisk = value == 'HIGH';
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: DS.caption()),
          Text(
            value,
            style: DS.mono(
              size: 11,
              color: isHighRisk ? DS.error : DS.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

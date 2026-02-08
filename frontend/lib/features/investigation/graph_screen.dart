import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/app_theme.dart';
import '../xray_viewer/xray_viewer_screen.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final Graph _graph = Graph()..isTree = false;
  late Algorithm _builder;
  
  // Time Slider State
  double _timeSliderValue = 2.0; // 0=Jan, 1=Feb, 2=Mar

  @override
  void initState() {
    super.initState();
    
    // Use BuchheimWalkerAlgorithm for stable layout
    final config = BuchheimWalkerConfiguration()
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

    _builder = BuchheimWalkerAlgorithm(config, ArrowEdgeRenderer());
    
    _buildGraphData();
  }

  void _buildGraphData() {
    // Nodes
    final node1 = Node.Id('INV-1024'); // Invoice (Blue)
    final node2 = Node.Id('ACME Corp'); // Vendor (Yellow)
    final node3 = Node.Id('Phone: +91-9876543210'); // Phone (Yellow)
    final node4 = Node.Id('Shell Co'); // Blacklisted (Red)
    final node5 = Node.Id('Employee #42'); // Employee (Yellow)
    final node6 = Node.Id('123 Tech Park'); // Address (Yellow)

    _graph.addNode(node1);
    _graph.addNode(node2);
    _graph.addNode(node3);
    _graph.addNode(node4);
    _graph.addNode(node5);
    _graph.addNode(node6);

    // Edges
    _graph.addEdge(node1, node2, paint: Paint()..color = Colors.grey..strokeWidth = 1); // Inv -> Vendor
    _graph.addEdge(node2, node3, paint: Paint()..color = Colors.grey..strokeWidth = 1); // Vendor -> Phone
    _graph.addEdge(node3, node4, paint: Paint()..color = AppColors.danger..strokeWidth = 3); // Phone -> Blacklisted (Red Link!)
    _graph.addEdge(node5, node6, paint: Paint()..color = Colors.grey..strokeWidth = 1); // Employee -> Address
    _graph.addEdge(node2, node6, paint: Paint()..color = AppColors.danger..strokeWidth = 3); // Vendor -> Address (Conflict!)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // GRAPH VIEW
          InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 5.0,
            child: GraphView(
              graph: _graph,
              algorithm: _builder,
              paint: Paint()..color = Colors.grey.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke,
              builder: (Node node) {
                final id = node.key!.value as String;
                return _buildNodeWidget(id);
              },
            ),
          ),
          
          // HEADER OVERLAY
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: FadeInDown(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.radar_2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investigation Board',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Forensic Knowledge Graph',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.warning_2, color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '2 Conflicts Detected',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // TIME SLIDER (Bottom)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline Filter',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Row(
                      children: [
                        Text('Jan', style: _getTimeLabelStyle(0)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.surfaceLight,
                              thumbColor: AppColors.primary,
                              overlayColor: AppColors.primary.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _timeSliderValue,
                              min: 0,
                              max: 2,
                              divisions: 2,
                              onChanged: (value) {
                                setState(() => _timeSliderValue = value);
                                // Mock filtering visual effect
                                _updateGraphVisibility();
                              },
                            ),
                          ),
                        ),
                        Text('Mar', style: _getTimeLabelStyle(2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // LEGEND
          Positioned(
            bottom: 140,
            right: 20,
            child: FadeInRight(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(AppColors.boxTable, 'Document'),
                    const SizedBox(height: 8),
                    _buildLegendItem(AppColors.boxHighlight, 'Entity'),
                    const SizedBox(height: 8),
                    _buildLegendItem(AppColors.danger, 'Anomaly'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateGraphVisibility() {
    setState(() {});
  }

  TextStyle? _getTimeLabelStyle(int index) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: _timeSliderValue == index ? AppColors.primary : AppColors.textMuted,
      fontWeight: _timeSliderValue == index ? FontWeight.bold : FontWeight.normal,
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildNodeWidget(String id) {
    Color color;
    IconData icon;
    
    if (id.startsWith('INV')) {
      color = AppColors.boxTable; // Document (Blue)
      icon = Iconsax.document_text;
    } else if (id == 'Shell Co' || id.contains('Conflict')) {
      color = AppColors.danger; // Anomaly/Blacklisted (Red)
      icon = Iconsax.warning_2;
    } else {
      color = AppColors.boxHighlight; // Entity (Yellow/Gold)
      icon = Iconsax.building;
      if (id.contains('Employee')) icon = Iconsax.user;
      if (id.contains('Phone')) icon = Iconsax.call;
      if (id.contains('Tech Park')) icon = Iconsax.location;
    }

    return GestureDetector(
      onTap: () {
        if (id.startsWith('INV')) {
          _openDocumentViewer();
        } else {
          _showEntityDetails(id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              id,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDocumentViewer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: constraints.maxHeight * 0.9,
              color: AppColors.background,
              child: const XRayViewerScreen(
                fileName: 'INV-1024.pdf',
              ),
            ),
          );
        }
      ),
    );
  }

  void _showEntityDetails(String entityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(entityId),
        content: const Text('Entity details and history would appear here powered by Backboard.io.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

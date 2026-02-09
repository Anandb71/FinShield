import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/theme/liquid_theme.dart';
import '../../core/providers/navigation_provider.dart';
import '../dashboard/command_center_dashboard.dart';
import '../review/review_screen.dart';
import '../inspector/doc_inspector_screen.dart';
import '../ingestion/bulk_ingestion_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// HOME SCREEN - Premium Navigation Shell
/// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = const [
    CommandCenterDashboard(),
    BulkIngestionScreen(),
    ReviewScreen(),
    DocInspectorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    final currentIndex = navigation.currentIndex;

    return Scaffold(
      backgroundColor: DS.background,
      body: AmbientBackground(
        child: Stack(
          children: [
            // Body Content
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: currentIndex,
                children: _screens,
              ),
            ),

            // Floating Navigation Bar
            Positioned(
              left: DS.space6,
              right: 100,
              bottom: DS.space8,
              child: FloatingNavBar(
                currentIndex: currentIndex,
                onTap: navigation.setIndex,
                items: const [
                  FloatingNavItem(
                    icon: Iconsax.command,
                    activeIcon: Iconsax.command,
                    label: 'COMMAND',
                  ),
                  FloatingNavItem(
                    icon: Iconsax.document_upload,
                    activeIcon: Iconsax.document_upload,
                    label: 'UPLOAD',
                  ),
                  FloatingNavItem(
                    icon: Iconsax.verify,
                    activeIcon: Iconsax.verify,
                    label: 'REVIEW',
                  ),
                  FloatingNavItem(
                    icon: Iconsax.scan,
                    activeIcon: Iconsax.scan,
                    label: 'INSPECT',
                  ),
                ],
              ),
            ),

            // Primary Action Button (FAB)
            Positioned(
              right: DS.space6,
              bottom: DS.space8,
              child: _buildPrimaryAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BulkIngestionScreen()),
        );
      },
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: DS.primaryGradient,
          boxShadow: DS.glow(DS.primary, intensity: 0.4),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Icon(
          Iconsax.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

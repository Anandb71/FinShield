import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/liquid_theme.dart';
import '../dashboard/command_center_dashboard.dart';
import '../review/review_screen.dart';
import '../inspector/doc_inspector_screen.dart';
import '../ingestion/bulk_ingestion_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = [
    const CommandCenterDashboard(),
    const ReviewScreen(),
    const DocInspectorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = Provider.of<NavigationProvider>(context);
    final currentIndex = navigation.currentIndex;

    return Scaffold(
      backgroundColor: LiquidTheme.background,
      body: LiquidBackground(
        particleCount: 50,
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
              left: 24,
              right: 120, // Leave space for Primary Action
              bottom: 34,
              child: _buildFloatingNavBar(navigation),
            ),

            // Primary Action Button (FAB) - Separated
            Positioned(
              right: 24,
              bottom: 34,
              child: _buildPrimaryAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(NavigationProvider navigation) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: LiquidTheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: Iconsax.command_square,
                label: 'COMMAND',
                isSelected: navigation.currentIndex == 0,
                onTap: () => navigation.setIndex(0),
              ),
              _NavBarItem(
                icon: Iconsax.verify,
                label: 'REVIEW',
                isSelected: navigation.currentIndex == 1,
                onTap: () => navigation.setIndex(1),
              ),
              _NavBarItem(
                icon: Iconsax.scan,
                label: 'INSPECT',
                isSelected: navigation.currentIndex == 2,
                onTap: () => navigation.setIndex(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LiquidTheme.neonCyan, Color(0xFF00c2bb)],
        ),
        boxShadow: LiquidTheme.neonGlow(LiquidTheme.neonCyan, intensity: 0.6),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkIngestionScreen()));
          },
          borderRadius: BorderRadius.circular(36),
          child: const Icon(Iconsax.add, color: Colors.black, size: 32),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? LiquidTheme.neonCyan : LiquidTheme.textMuted;
    
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: LiquidTheme.monoData(
                size: 9,
                color: color,
                weight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_background.dart';
import '../styles/app_theme.dart';
import 'dashboard_screen.dart';
import 'upload_screen.dart';
import 'review_screen.dart';
import 'documents_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    UploadScreen(),
    ReviewScreen(),
    DocumentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // For glass bottom nav
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            height: 70,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            indicatorColor: AppTheme.primary.withOpacity(0.2),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              _buildNavDest(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
              _buildNavDest(Icons.cloud_upload_outlined, Icons.cloud_upload_rounded, 'Upload'),
              _buildNavDest(Icons.rate_review_outlined, Icons.rate_review_rounded, 'Review'),
              _buildNavDest(Icons.folder_open_outlined, Icons.folder_rounded, 'Documents'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDest(IconData icon, IconData selectedIcon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: AppTheme.textSecondary),
      selectedIcon: Icon(selectedIcon, color: AppTheme.primary),
      label: label,
    );
  }
}

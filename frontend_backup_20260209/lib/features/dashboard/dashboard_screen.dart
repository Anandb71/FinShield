import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../xray_viewer/xray_viewer_screen.dart';
import 'widgets/stat_card.dart';
import 'widgets/recent_documents.dart';

/// Main Dashboard - The Command Center
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = false;

  Future<void> _pickAndAnalyzeDocument() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      
      if (result != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => XRayViewerScreen(
              fileName: result.files.first.name,
              fileBytes: result.files.first.bytes,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: const Icon(Iconsax.shield_tick, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Finsight',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'Autonomous Auditor',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Iconsax.setting_2, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // STATS ROW
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.document_text,
                              label: 'Documents',
                              value: '2,847',
                              trend: '+12%',
                              trendUp: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.tick_circle,
                              label: 'Validated',
                              value: '98.2%',
                              trend: '+3.1%',
                              trendUp: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.warning_2,
                              label: 'Anomalies',
                              value: '23',
                              trend: '-5',
                              trendUp: false,
                              accentColor: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // MAIN ACTION CARD
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Iconsax.scan, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'X-Ray Document Analysis',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Upload any financial document for intelligent extraction',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _pickAndAnalyzeDocument,
                                icon: _isLoading 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Iconsax.document_upload),
                                label: Text(_isLoading ? 'Processing...' : 'Upload Document'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // DEMO QUICK ACCESS
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEMO MODE',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const XRayViewerScreen(
                                    fileName: 'Demo_Invoice_ACME.pdf',
                                    fileBytes: null, // Will use mock data
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.play_circle),
                            label: const Text('Launch Demo with Sample Invoice'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // RECENT DOCUMENTS SECTION
            SliverToBoxAdapter(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: const RecentDocuments(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

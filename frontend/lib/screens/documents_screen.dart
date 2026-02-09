import 'package:flutter/material.dart';
import '../styles/app_theme.dart';
import '../widgets/premium_glass_card.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: PremiumGlassCard(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                'SECURE ARCHIVE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Document history and archival search coming in next module update.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

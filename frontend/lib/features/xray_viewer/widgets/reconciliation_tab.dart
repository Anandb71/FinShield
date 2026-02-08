import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_theme.dart';

/// Bank Transaction Model
class BankTransaction {
  final String id;
  final String description;
  final double amount;
  final String date;
  final String category;

  BankTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'payment',
  });
}

/// Reconciliation Tab - Smart Match for Invoice vs Bank Statement
class ReconciliationTab extends StatefulWidget {
  final double invoiceTotal;
  final String invoiceVendor;
  final VoidCallback? onMatchConfirmed;

  const ReconciliationTab({
    super.key,
    required this.invoiceTotal,
    required this.invoiceVendor,
    this.onMatchConfirmed,
  });

  @override
  State<ReconciliationTab> createState() => _ReconciliationTabState();
}

class _ReconciliationTabState extends State<ReconciliationTab> {
  late List<BankTransaction> _transactions;
  int? _matchedIndex;
  bool _isMatched = false;
  String _matchType = '';
  bool _showMatchAnimation = false;

  @override
  void initState() {
    super.initState();
    _transactions = _getDemoTransactions();
    _performSmartMatch();
  }

  List<BankTransaction> _getDemoTransactions() {
    return [
      BankTransaction(
        id: 'TXN-001',
        description: 'TechCorp Inc',
        amount: 12000,
        date: '2024-10-01',
        category: 'vendor_payment',
      ),
      BankTransaction(
        id: 'TXN-002',
        description: 'ACME Corporation',
        amount: 55000, // Matches demo invoice
        date: '2024-10-05',
        category: 'vendor_payment',
      ),
      BankTransaction(
        id: 'TXN-003',
        description: 'Uber Ride',
        amount: 450,
        date: '2024-10-06',
        category: 'expense',
      ),
      BankTransaction(
        id: 'TXN-004',
        description: 'AWS Hosting',
        amount: 8500,
        date: '2024-10-08',
        category: 'infrastructure',
      ),
      BankTransaction(
        id: 'TXN-005',
        description: 'Office Supplies',
        amount: 3200,
        date: '2024-10-10',
        category: 'expense',
      ),
    ];
  }

  void _performSmartMatch() {
    // Delay for visual effect
    Future.delayed(const Duration(milliseconds: 500), () {
      for (int i = 0; i < _transactions.length; i++) {
        final txn = _transactions[i];
        
        // Priority 1: Exact match
        if (txn.amount == widget.invoiceTotal) {
          setState(() {
            _matchedIndex = i;
            _isMatched = true;
            _matchType = 'exact';
            _showMatchAnimation = true;
          });
          HapticFeedback.mediumImpact();
          return;
        }
        
        // Priority 2: Fuzzy match (within 2%)
        final tolerance = widget.invoiceTotal * 0.02;
        if ((txn.amount - widget.invoiceTotal).abs() <= tolerance) {
          setState(() {
            _matchedIndex = i;
            _isMatched = true;
            _matchType = 'fuzzy';
            _showMatchAnimation = true;
          });
          HapticFeedback.mediumImpact();
          return;
        }
      }
      
      // No match - Ghost Invoice
      setState(() {
        _isMatched = false;
        _matchType = 'none';
      });
    });
  }

  void _forceMatch(int index) {
    HapticFeedback.heavyImpact();
    setState(() {
      _matchedIndex = index;
      _isMatched = true;
      _matchType = 'manual';
      _showMatchAnimation = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.cpu, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Manual Reconciliation Logged for Retraining'),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    
    widget.onMatchConfirmed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // STATUS BANNER
        _buildStatusBanner(),
        
        // BANK STATEMENT HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(Iconsax.bank, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Bank Statement Transactions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                'Long-press to force match',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        // TRANSACTION LIST
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _transactions.length,
            itemBuilder: (context, index) => _buildTransactionRow(index),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final isGhost = !_isMatched && _matchType == 'none';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGhost
              ? [AppColors.danger.withOpacity(0.2), AppColors.danger.withOpacity(0.05)]
              : _isMatched
                  ? [AppColors.success.withOpacity(0.2), AppColors.success.withOpacity(0.05)]
                  : [AppColors.surfaceLight, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGhost
              ? AppColors.danger.withOpacity(0.5)
              : _isMatched
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.border,
          width: isGhost || _isMatched ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGhost
                  ? AppColors.danger.withOpacity(0.2)
                  : _isMatched
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGhost
                  ? Iconsax.warning_2
                  : _isMatched
                      ? Iconsax.tick_circle
                      : Iconsax.search_normal,
              color: isGhost
                  ? AppColors.danger
                  : _isMatched
                      ? AppColors.success
                      : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGhost
                      ? 'GHOST INVOICE'
                      : _isMatched
                          ? 'PAYMENT VERIFIED'
                          : 'Searching...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isGhost
                        ? AppColors.danger
                        : _isMatched
                            ? AppColors.success
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGhost
                      ? 'No matching payment found in bank records'
                      : _isMatched
                          ? _matchType == 'exact'
                              ? 'Exact amount match found'
                              : _matchType == 'fuzzy'
                                  ? 'Fuzzy match (within 2% tolerance)'
                                  : 'Manually reconciled'
                          : 'Scanning bank transactions...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_isMatched && _showMatchAnimation)
            FadeIn(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.link, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Linked',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(int index) {
    final txn = _transactions[index];
    final isMatched = _matchedIndex == index;
    
    return GestureDetector(
      onLongPress: () => _forceMatch(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMatched ? AppColors.success.withOpacity(0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched ? AppColors.success : AppColors.border,
            width: isMatched ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // MATCH INDICATOR
            if (isMatched)
              FadeIn(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing ring
                      _PulsingRing(color: AppColors.success),
                      Icon(Iconsax.link_21, color: AppColors.success, size: 20),
                    ],
                  ),
                ),
              ),
            
            // TRANSACTION DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isMatched ? AppColors.success : AppColors.textPrimary,
                      fontWeight: isMatched ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    txn.date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            
            // AMOUNT
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_formatNumber(txn.amount.toInt())}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isMatched ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isMatched)
                  FadeIn(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'MATCH',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// Pulsing ring animation for matched transactions
class _PulsingRing extends StatefulWidget {
  final Color color;
  const _PulsingRing({required this.color});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 40 * _animation.value,
          height: 40 * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(1 - (_animation.value - 0.8) / 0.7),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

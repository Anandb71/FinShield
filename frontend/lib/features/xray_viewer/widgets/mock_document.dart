import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Mock Document - Renders a realistic invoice for demo purposes
class MockDocument extends StatelessWidget {
  const MockDocument({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACME Corporation',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Technology Solutions',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GSTIN: 27AAACA1234A1ZV',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'INVOICE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '#INV-2024-1024',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: Oct 24, 2024',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Due: Nov 24, 2024',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),

          // BILL TO
          Text(
            'BILL TO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FinShield Technologies Pvt Ltd',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '123 Tech Park, Bangalore 560001',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),

          const SizedBox(height: 32),

          // TABLE HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('Description', style: _headerStyle),
                ),
                Expanded(child: Text('Qty', style: _headerStyle, textAlign: TextAlign.center)),
                Expanded(child: Text('Rate', style: _headerStyle, textAlign: TextAlign.right)),
                Expanded(child: Text('Amount', style: _headerStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),

          // TABLE ROWS
          _buildRow('Consulting Services', '10', '₹4,500', '₹45,000'),
          _buildRow('Server Maintenance', '1', '₹5,000', '₹5,000'),

          const SizedBox(height: 24),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),

          // TOTALS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTotalRow('Subtotal', '₹50,000'),
                  const SizedBox(height: 8),
                  _buildTotalRow('Tax (10%)', '₹5,000'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL:  ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Text(
                          '₹55,000',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // FOOTER NOTE (Anomaly)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Text(
                  'Handwritten: "Paid in cash - Ramesh"',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Colors.blue[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle get _headerStyle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      );

  Widget _buildRow(String desc, String qty, String rate, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(desc, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          Expanded(
            child: Text(qty, style: TextStyle(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(rate, style: TextStyle(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(width: 24),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}

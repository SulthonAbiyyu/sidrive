import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/financial_tracking_model.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';

class FinancialSummaryBar extends StatelessWidget {
  const FinancialSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final s = provider.financialSummary ?? FinancialSummary.empty();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _SummaryCell(
                label: 'Revenue',
                value: CurrencyFormatter.format(s.totalRevenue),
                color: const Color(0xFF10B981),
              ),
              _buildDivider(),
              _SummaryCell(
                label: 'Held',
                value: CurrencyFormatter.format(s.totalHeld),
                color: const Color(0xFFF59E0B),
              ),
              _buildDivider(),
              _SummaryCell(
                label: 'Paid Out',
                value: CurrencyFormatter.format(s.totalPaidOut),
                color: const Color(0xFF3B82F6),
              ),
              _buildDivider(),
              _SummaryCell(
                label: 'Pending',
                value: CurrencyFormatter.format(s.totalPending),
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
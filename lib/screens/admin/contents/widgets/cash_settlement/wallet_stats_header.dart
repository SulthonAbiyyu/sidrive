import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/cash_settlement_model.dart';
import 'package:sidrive/models/financial_tracking_model.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/screens/admin/contents/widgets/cash_settlement/withdraw_dialog.dart';


class WalletStatsHeader extends StatelessWidget {
  const WalletStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final stats = provider.walletStats ?? AdminWalletStats.empty();
        final summary = provider.financialSummary ?? FinancialSummary.empty();

        // ── Layout baru: kiri = wallet card, kanan = 2×2 stat grid ──────────
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + pending badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Wallet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Text(
                      'Cash Settlement & Financial Monitoring',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                if (stats.pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${stats.pendingCount} Pending',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Baris utama: wallet (kiri) + 2×2 grid (kanan) ──────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── KIRI: Wallet card compact ───────────────────────────
                  Container(
                    width: 240,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon + label
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF6366F1),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Cash Masuk',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Nominal
                        Text(
                          CurrencyFormatter.format(stats.totalCashMasuk),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Tarik Saldo button full width
                        SizedBox(
                          width: double.infinity,
                          child: _WithdrawButton(
                            availableBalance: stats.totalCashMasuk,
                            onWithdraw: (amount, bankCode, bankName, accountNumber, accountHolderName, notes, saveAccount, setAsDefault) async {
                              final success = await provider.createAdminPayout(
                                amount: amount,
                                bankCode: bankCode,
                                bankName: bankName,
                                accountNumber: accountNumber,
                                accountHolderName: accountHolderName,
                                notes: notes,
                                saveAccount: saveAccount,
                                setAsDefault: setAsDefault,
                              );
                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Penarikan saldo berhasil diproses!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Gagal: ${provider.payoutError ?? "Unknown error"}'),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── KANAN: 2×2 stat grid ────────────────────────────────
                  Expanded(
                    child: Column(
                      children: [
                        // Row atas
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Approved',
                                  value: stats.totalSettlementApproved.toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  color: const Color(0xFF10B981),
                                  bgColor: const Color(0xFFD1FAE5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Rejected',
                                  value: stats.totalSettlementRejected.toString(),
                                  icon: Icons.cancel_outlined,
                                  color: const Color(0xFFEF4444),
                                  bgColor: const Color(0xFFFEE2E2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Row bawah
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Orders',
                                  value: summary.totalOrders.toString(),
                                  icon: Icons.receipt_long_outlined,
                                  color: const Color(0xFF3B82F6),
                                  bgColor: const Color(0xFFDBEAFE),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Selesai',
                                  value: summary.completedOrders.toString(),
                                  icon: Icons.done_all_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  bgColor: const Color(0xFFEDE9FE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WITHDRAW BUTTON WIDGET
// ============================================================================

class _WithdrawButton extends StatelessWidget {
  final double availableBalance;
  final Function(double amount, String bankCode, String bankName, String accountNumber, String accountHolderName, String notes, bool saveAccount, bool setAsDefault) onWithdraw;

  const _WithdrawButton({
    required this.availableBalance,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF6366F1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () async {
          // Load saved accounts first
          final provider = context.read<AdminProvider>();
          await provider.loadSavedBankAccounts();
          
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (_) => WithdrawDialog(
                availableBalance: availableBalance,
                savedAccounts: provider.savedBankAccounts,
                onSubmit: onWithdraw,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_outlined,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Tarik Saldo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:sidrive/models/cash_settlement_model.dart';
import 'package:sidrive/models/financial_tracking_model.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/screens/admin/contents/widgets/cash_settlement/withdraw_dialog.dart';

import 'package:sidrive/screens/admin/contents/widgets/cash_settlement/settlement_card.dart';
import 'package:sidrive/screens/admin/contents/widgets/cash_settlement/financial_tracking_card.dart';
import 'package:sidrive/screens/admin/contents/widgets/cash_settlement/financial_summary_bar.dart';

class CashSettlementContent extends StatefulWidget {
  const CashSettlementContent({super.key});

  @override
  State<CashSettlementContent> createState() => _CashSettlementContentState();
}

class _CashSettlementContentState extends State<CashSettlementContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Track jumlah settlements untuk detect perubahan realtime dari provider
  int _lastSettlementCount = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ AUTO-RELOAD: AdminProvider.startRealtimeBadges() subscribe 'cash_settlements'.
  /// Saat settlement berubah, pendingSettlements.length berubah →
  /// _SettlementTab (Consumer<AdminProvider>) rebuild otomatis.
  /// _loadData() juga dipanggil ulang untuk refresh walletStats.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCount = context.read<AdminProvider>().pendingSettlements.length;
    if (_lastSettlementCount != -1 && currentCount != _lastSettlementCount) {
      debugPrint('🔴 [Settlement] Count berubah ($currentCount) → reload wallet stats');
      context.read<AdminProvider>().loadAdminWalletStats();
    }
    _lastSettlementCount = currentCount;
  }

  Future<void> _loadData() async {
    final provider = context.read<AdminProvider>();
    await Future.wait([
      provider.loadPendingSettlements(),
      provider.loadAdminWalletStats(),
      provider.loadFinancialSummary(),
      provider.loadFinancialTracking(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOPBAR SUPER COMPACT: semua info dalam 1 baris ──────────────
          _buildTopBar(),

          SizedBox(height: ResponsiveAdmin.spaceMD()),

          // Tab content — dapat semua sisa ruang
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SettlementTab(),
                _FinancialTrackingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Topbar 1 baris:
  /// [wallet icon + nominal + Tarik Saldo] | [4 stat chips] | [tab toggle]
  Widget _buildTopBar() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final stats = provider.walletStats ?? AdminWalletStats.empty();
        final summary = provider.financialSummary ?? FinancialSummary.empty();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Wallet: icon + nominal + tombol ─────────────────────────
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF6366F1),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cash Masuk',
                    style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    CurrencyFormatter.format(stats.totalCashMasuk),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Tarik Saldo button compact
              _WithdrawButtonCompact(
                availableBalance: stats.totalCashMasuk,
                onWithdraw: (amount, bankCode, bankName, accountNumber,
                    accountHolderName, notes, saveAccount, setAsDefault) async {
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? '✅ Penarikan berhasil!'
                            : '❌ Gagal: ${provider.payoutError ?? "Unknown error"}'),
                        backgroundColor: success
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    );
                  }
                },
              ),

              // ── Divider ──────────────────────────────────────────────────
              Container(
                  width: 1, height: 32, color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 20)),
              _StatChip(
                label: 'Approved',
                value: stats.totalSettlementApproved.toString(),
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Rejected',
                value: stats.totalSettlementRejected.toString(),
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Orders',
                value: summary.totalOrders.toString(),
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Selesai',
                value: summary.completedOrders.toString(),
                color: const Color(0xFF8B5CF6),
              ),

              // ── Divider ──────────────────────────────────────────────────
              Container(
                  width: 1, height: 32, color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 12)),

              // ── Pending badge (jika ada) ──────────────────────────────────
              if (stats.pendingCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    '${stats.pendingCount} Pending',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              const Spacer(),

              // ── Tab toggle (Settlement / Financial Tracking) ──────────────
              _buildTabToggle(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabToggle() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final selected = _tabController.index;
        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabToggleItem(
                label: 'Settlement',
                selected: selected == 0,
                onTap: () => _tabController.animateTo(0),
              ),
              _TabToggleItem(
                label: 'Financial Tracking',
                selected: selected == 1,
                onTap: () => _tabController.animateTo(1),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab Toggle Item ──────────────────────────────────────────────────────────

class _TabToggleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? const Color(0xFF6366F1)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Withdraw Button Compact ──────────────────────────────────────────────────

class _WithdrawButtonCompact extends StatelessWidget {
  final double availableBalance;
  final Function(double, String, String, String, String, String, bool, bool)
      onWithdraw;

  const _WithdrawButtonCompact({
    required this.availableBalance,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF6366F1),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: () async {
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
        borderRadius: BorderRadius.circular(7),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_outlined,
                  color: Colors.white, size: 13),
              SizedBox(width: 4),
              Text(
                'Tarik',
                style: TextStyle(
                  fontSize: 11,
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

// ─── Settlement Tab ───────────────────────────────────────────────────────────

class _SettlementTab extends StatelessWidget {
  const _SettlementTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingSettlements) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
              strokeWidth: 2,
            ),
          );
        }

        if (provider.pendingSettlements.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () => provider.loadPendingSettlements(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: provider.pendingSettlements.length,
            itemBuilder: (context, index) {
              return SettlementCard(
                settlement: provider.pendingSettlements[index],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada settlement pending',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Semua settlement sudah diproses',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

// ─── Financial Tracking Tab ───────────────────────────────────────────────────

class _FinancialTrackingTab extends StatefulWidget {
  const _FinancialTrackingTab();

  @override
  State<_FinancialTrackingTab> createState() => _FinancialTrackingTabState();
}

class _FinancialTrackingTabState extends State<_FinancialTrackingTab> {
  String? _jenisFilter;
  String? _metodePembayaranFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadFinancialTracking();
    });
  }

  void _applyFilters() {
    context.read<AdminProvider>().loadFinancialTracking(
          jenisFilter: _jenisFilter,
          metodePembayaran: _metodePembayaranFilter,
          statusFilter: _statusFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar (compact)
        const FinancialSummaryBar(),

        const SizedBox(height: 8),

        // Filter row
        _buildFilterRow(),

        const SizedBox(height: 8),

        // List — Expanded agar sisanya dipakai penuh
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        _FilterButton(
          label: 'Jenis',
          value: _jenisFilter,
          options: const ['Semua', 'Ojek', 'UMKM'],
          onSelected: (v) {
            setState(() => _jenisFilter = v == 'Semua' ? null : v?.toLowerCase());
            _applyFilters();
          },
        ),
        const SizedBox(width: 8),
        _FilterButton(
          label: 'Pembayaran',
          value: _metodePembayaranFilter,
          options: const ['Semua', 'Cash', 'Wallet', 'Transfer'],
          onSelected: (v) {
            setState(
                () => _metodePembayaranFilter = v == 'Semua' ? null : v?.toLowerCase());
            _applyFilters();
          },
        ),
        const SizedBox(width: 8),
        _FilterButton(
          label: 'Status',
          value: _statusFilter,
          options: const ['Semua', 'OK', 'Pending', 'Selesai', 'Bermasalah'],
          onSelected: (v) {
            setState(() => _statusFilter = v == 'Semua' ? null : v?.toLowerCase());
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _buildList() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFinancialTracking) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
              strokeWidth: 2,
            ),
          );
        }

        if (provider.financialTrackingList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tidak ada data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () => provider.loadFinancialTracking(
            jenisFilter: _jenisFilter,
            metodePembayaran: _metodePembayaranFilter,
            statusFilter: _statusFilter,
          ),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: provider.financialTrackingList.length,
            itemBuilder: (context, index) {
              return FinancialTrackingCard(
                data: provider.financialTrackingList[index],
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Filter Button ────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final Function(String?) onSelected;

  const _FilterButton({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      elevation: 4,
      color: Colors.white,
      itemBuilder: (_) => options
          .map(
            (o) => PopupMenuItem<String>(
              value: o,
              height: 36,
              child: Text(
                o,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive && value == o.toLowerCase()
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF374151),
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE9FE) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive && value != null && value!.isNotEmpty
                  ? '$label: ${value![0].toUpperCase()}${value!.length > 1 ? value!.substring(1) : ''}'
                  : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
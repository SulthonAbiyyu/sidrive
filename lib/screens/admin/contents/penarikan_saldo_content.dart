// lib/screens/admin/penarikan_saldo/penarikan_saldo_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:sidrive/screens/admin/contents/widgets/penarikkan_saldo/penarikan_header.dart';
import 'package:sidrive/screens/admin/contents/widgets/penarikkan_saldo/penarikan_card.dart';
import 'package:sidrive/screens/admin/contents/widgets/penarikkan_saldo/penarikan_empty_state.dart';
import 'package:sidrive/screens/admin/contents/widgets/penarikkan_saldo/approve_dialog.dart';
import 'package:sidrive/screens/admin/contents/widgets/penarikkan_saldo/reject_dialog.dart';


class PenarikanSaldoContent extends StatefulWidget {
  const PenarikanSaldoContent({super.key});

  @override
  State<PenarikanSaldoContent> createState() => _PenarikanSaldoContentState();
}

class _PenarikanSaldoContentState extends State<PenarikanSaldoContent> {

  @override
  void initState() {
    super.initState();
    // ✅ Load data saat pertama buka halaman.
    // Update realtime sudah dihandle AdminProvider.startRealtimeBadges()
    // yang subscribe 'withdrawal_requests' → loadPendingPenarikan() otomatis.
    // context.watch<AdminProvider>() di build() akan rebuild widget saat provider update.
    _loadData();
  }

  /// Load data penarikan pending dari database
  Future<void> _loadData() async {
    if (!mounted) return;
    print('🔄 PenarikanSaldoContent: Loading data...');
    
    try {
      await context.read<AdminProvider>().loadPendingPenarikan();
      print('✅ PenarikanSaldoContent: Data loaded successfully');
    } catch (e) {
      print('❌ PenarikanSaldoContent: Error loading data: $e');
      if (mounted) {
        _showSnackBar(
          '❌ Gagal memuat data penarikan',
          Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final pendingPenarikan = adminProvider.pendingPenarikan;
    final isLoading = adminProvider.isLoadingPenarikan;

    return Column(
      children: [
        // Header dengan total yang BENAR
        PenarikanHeader(
          pendingCount: pendingPenarikan.length,
          totalAmount: _calculateTotal(pendingPenarikan),
          onRefresh: _loadData,
        ),
        
        // List atau Empty State
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                  ),
                )
              : pendingPenarikan.isEmpty
                  ? const PenarikanEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF10B981),
                      child: ListView.separated(
                        padding: ResponsiveAdmin.pagePadding(context),
                        itemCount: pendingPenarikan.length,
                        separatorBuilder: (_, __) => SizedBox(
                          height: ResponsiveAdmin.spaceMD(),
                        ),
                        itemBuilder: (context, index) {
                          final penarikan = pendingPenarikan[index];
                          return PenarikanCard(
                            penarikan: penarikan,
                            onApprove: () => _handleApprove(penarikan),
                            onReject: () => _handleReject(penarikan),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  /// Calculate total amount dari semua penarikan pending
  double _calculateTotal(List pendingList) {
    if (pendingList.isEmpty) return 0;
    
    return pendingList.fold<double>(
      0,
      (sum, item) => sum + (item.jumlah ?? 0),
    );
  }

  /// Handle Approve - dengan upload bukti transfer
  Future<void> _handleApprove(dynamic penarikan) async {
    print('✅ Approve initiated for: ${penarikan.idPenarikan}');
    print('   User: ${penarikan.nama}');
    print('   Amount: Rp${(penarikan.jumlah ?? 0).toStringAsFixed(0)}');
    
    // Show approve dialog dengan upload bukti
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ApproveDialog(penarikan: penarikan),
    );

    // Handle result
    if (result == null || !mounted) {
      print('ℹ️ Approve dialog cancelled');
      return;
    }
    
    if (result['success'] == true) {
      print('✅ Approve successful!');
      _showSnackBar(
        '✅ Penarikan berhasil disetujui!',
        const Color(0xFF10B981),
      );
      await _loadData(); // Refresh data
    } else {
      print('❌ Approve failed: ${result['message']}');
      _showSnackBar(
        '❌ ${result['message'] ?? 'Gagal menyetujui penarikan'}',
        const Color(0xFFEF4444),
      );
    }
  }

  /// Handle Reject - dengan input alasan & auto refund
  Future<void> _handleReject(dynamic penarikan) async {
    print('🚫 Reject initiated for: ${penarikan.idPenarikan}');
    print('   User: ${penarikan.nama}');
    print('   Amount to refund: Rp${(penarikan.jumlah ?? 0).toStringAsFixed(0)}');
    
    // Show reject dialog dengan input alasan
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RejectDialog(penarikan: penarikan),
    );

    // Handle result
    if (result == null || !mounted) {
      print('ℹ️ Reject dialog cancelled');
      return;
    }
    
    if (result['success'] == true) {
      print('✅ Reject & refund successful!');
      _showSnackBar(
        '✅ Penarikan ditolak & saldo dikembalikan',
        const Color(0xFFF59E0B),
      );
      await _loadData(); // Refresh data
    } else {
      print('❌ Reject failed: ${result['message']}');
      _showSnackBar(
        '❌ ${result['message'] ?? 'Gagal menolak penarikan'}',
        const Color(0xFFEF4444),
      );
    }
  }

  /// Show SnackBar helper dengan styling konsisten
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF10B981) 
                  ? Icons.check_circle
                  : color == const Color(0xFFF59E0B)
                      ? Icons.info_outline
                      : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
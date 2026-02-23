// ============================================================================
// REFUND_MANAGEMENT_CONTENT.DART - REDESIGNED
// UI/UX CLEAN, MODERN, PROPORTIONAL - Inspired by KTM Verification style
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/providers/admin_provider.dart';

class RefundManagementContent extends StatefulWidget {
  const RefundManagementContent({Key? key}) : super(key: key);

  @override
  State<RefundManagementContent> createState() =>
      _RefundManagementContentState();
}

class _RefundManagementContentState extends State<RefundManagementContent> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingRefunds = [];
  String _filterType = 'Semua'; // 'Semua', 'Wallet', 'Transfer'
  Map<String, dynamic>? _selectedRefund;
  // ✅ DIHAPUS: _realtimeChannel tidak diperlukan lagi.
  // AdminProvider.startRealtimeBadges() sudah subscribe tabel 'pesanan' secara global.
  // Widget ini trigger reload via didChangeDependencies saat pendingRefundCount berubah.

  // Track nilai lama untuk detect perubahan
  int _lastRefundCount = -1;

  // ============================================================================
  // COLOR CONSTANTS
  // ============================================================================
  static const Color _white = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _walletColor = Color(0xFFEC4899);
  static const Color _transferColor = Color(0xFFF59E0B);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadPendingRefunds();
    // ✅ DIHAPUS: _startRealtime() - sudah dihandle oleh AdminProvider
  }

  @override
  void dispose() {
    // ✅ DIHAPUS: _stopRealtime() - tidak ada channel lokal
    super.dispose();
  }

  /// ✅ AUTO-RELOAD: Saat AdminProvider dapat update dari realtime (pesanan berubah),
  /// pendingRefundCount akan berubah → widget ini detect dan reload list-nya.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCount = context.read<AdminProvider>().pendingRefundCount;
    if (_lastRefundCount != -1 && currentCount != _lastRefundCount) {
      debugPrint('🔴 [Refund] Count berubah ($currentCount) → reload list');
      _loadPendingRefunds();
    }
    _lastRefundCount = currentCount;
  }

  // ============================================================================
  // DATA LOADING
  // ============================================================================
  Future<void> _loadPendingRefunds() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      var query = supabase
          .from('pesanan')
          .select('''
            id_pesanan,
            id_user,
            total_harga,
            refund_amount,
            payment_method,
            status_pesanan,
            refund_status,
            paid_with_wallet,
            wallet_deducted_amount,
            alasan_cancel,
            created_at,
            users!inner(nama, email, no_telp)
          ''')
          .inFilter('status_pesanan', ['dibatalkan', 'gagal'])
          .or('refund_status.is.null,refund_status.eq.pending_manual')
          .order('created_at', ascending: false);

      final response = await query;
      List<Map<String, dynamic>> allRefunds =
          List<Map<String, dynamic>>.from(response);

      allRefunds = allRefunds.where((refund) {
        final paidWithWallet = refund['paid_with_wallet'] == true;
        final refundStatus = refund['refund_status'];
        final walletAmount =
            (refund['wallet_deducted_amount'] ?? 0).toDouble();

        if (paidWithWallet) {
          return walletAmount > 0 &&
              (refundStatus == null || refundStatus == 'pending_manual');
        } else {
          return refundStatus == 'pending_manual';
        }
      }).toList();

      if (_filterType == 'Wallet') {
        allRefunds =
            allRefunds.where((r) => r['paid_with_wallet'] == true).toList();
      } else if (_filterType == 'Transfer') {
        allRefunds =
            allRefunds.where((r) => r['paid_with_wallet'] != true).toList();
      }

      setState(() {
        _pendingRefunds = allRefunds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading refunds: $e');
      setState(() => _isLoading = false);
    }
  }

  // ============================================================================
  // PROCESS REFUND
  // ============================================================================
  Future<void> _processRefund(Map<String, dynamic> refund) async {
    final paidWithWallet = refund['paid_with_wallet'] == true;
    final amount = paidWithWallet
        ? (refund['wallet_deducted_amount'] ?? 0).toDouble()
        : (refund['refund_amount'] ?? refund['total_harga'] ?? 0).toDouble();

    if (amount <= 0) {
      _showSnackBar('Jumlah refund tidak valid', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(refund, amount, paidWithWallet);
    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;

      if (paidWithWallet) {
        final user = await supabase
            .from('users')
            .select('saldo_wallet')
            .eq('id_user', refund['id_user'])
            .single();

        final oldBalance = (user['saldo_wallet'] ?? 0).toDouble();
        final newBalance = oldBalance + amount;

        await supabase.from('users').update({
          'saldo_wallet': newBalance,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_user', refund['id_user']);

        await supabase.from('pesanan').update({
          'refund_status': 'completed',
          'refund_amount': amount,
        }).eq('id_pesanan', refund['id_pesanan']);

        if (mounted) {
          _showSnackBar('Refund wallet berhasil · Rp${_formatCurrency(amount)} dikembalikan');
        }
      } else {
        await supabase.from('pesanan').update({
          'refund_status': 'completed',
        }).eq('id_pesanan', refund['id_pesanan']);

        if (mounted) {
          _showSnackBar('Refund transfer berhasil ditandai selesai');
        }
      }

      setState(() => _selectedRefund = null);
      _loadPendingRefunds();
      // ✅ Update badge di sidebar
      if (mounted) {
        context.read<AdminProvider>().loadPendingRefundCount();
      }
    } catch (e) {
      debugPrint('❌ Error processing refund: $e');
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number =
        value is num ? value : double.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: '', decimalDigits: 0)
        .format(number);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
      Map<String, dynamic> refund, double amount, bool paidWithWallet) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: paidWithWallet
                          ? _walletColor.withOpacity(0.1)
                          : _transferColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      paidWithWallet
                          ? Icons.account_balance_wallet_outlined
                          : Icons.payment_outlined,
                      color:
                          paidWithWallet ? _walletColor : _transferColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    paidWithWallet ? 'Refund ke Wallet' : 'Konfirmasi Refund Manual',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Info box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: paidWithWallet
                      ? _walletColor.withOpacity(0.05)
                      : _transferColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: paidWithWallet
                        ? _walletColor.withOpacity(0.2)
                        : _transferColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paidWithWallet
                          ? 'Saldo akan dikembalikan OTOMATIS ke wallet user.'
                          : 'Pastikan refund sudah diproses manual via Midtrans Dashboard!',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            paidWithWallet ? _walletColor : _transferColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Jumlah Refund',
                          style: TextStyle(
                              fontSize: 12, color: _textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          'Rp${_formatCurrency(amount)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: paidWithWallet
                                ? _walletColor
                                : _transferColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!paidWithWallet) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: _transferColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Klik "Sudah Diproses" hanya setelah refund berhasil di Midtrans.',
                        style: TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        paidWithWallet ? 'Refund Sekarang' : 'Sudah Diproses',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BUILD - MAIN
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: _border),
          Expanded(
            child: _selectedRefund == null
                ? _buildListView()
                : _buildDetailView(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_selectedRefund != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => setState(() => _selectedRefund = null),
                icon: const Icon(Icons.arrow_back, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ),
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.restore_outlined,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedRefund == null ? 'Refund Management' : 'Detail Refund',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  _selectedRefund == null
                      ? '${_pendingRefunds.length} pending refund'
                      : 'Order: ${(_selectedRefund!['id_pesanan'] as String).substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Filter dropdown (only on list view)
          if (_selectedRefund == null) ...[
            _buildFilterChip(),
            const SizedBox(width: 8),
          ],
          // Refresh
          IconButton(
            onPressed: _loadPendingRefunds,
            icon: const Icon(Icons.refresh, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: _textSecondary),
          items: ['Semua', 'Wallet', 'Transfer'].map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() => _filterType = value!);
            _loadPendingRefunds();
          },
        ),
      ),
    );
  }

  // ============================================================================
  // LIST VIEW
  // ============================================================================
  Widget _buildListView() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFF59E0B),
          ),
        ),
      );
    }

    if (_pendingRefunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 36,
                color: _successColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak Ada Refund Pending',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Semua refund sudah diproses',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRefunds,
      color: const Color(0xFFF59E0B),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _pendingRefunds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _buildRefundCard(_pendingRefunds[index]),
      ),
    );
  }

  // ============================================================================
  // REFUND CARD
  // ============================================================================
  Widget _buildRefundCard(Map<String, dynamic> refund) {
    final paidWithWallet = refund['paid_with_wallet'] == true;
    final userData = refund['users'] as Map<String, dynamic>;
    final amount = paidWithWallet
        ? (refund['wallet_deducted_amount'] ?? 0).toDouble()
        : (refund['refund_amount'] ?? refund['total_harga'] ?? 0).toDouble();
    final color = paidWithWallet ? _walletColor : _transferColor;
    final orderId = refund['id_pesanan'] as String;
    final shortId = '${orderId.substring(0, 8)}...';
    final date = DateFormat('dd MMM yyyy · HH:mm')
        .format(DateTime.parse(refund['created_at']));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedRefund = refund),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  paidWithWallet
                      ? Icons.account_balance_wallet_outlined
                      : Icons.payment_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userData['nama'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeBadge(paidWithWallet),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order: $shortId',
                      style: const TextStyle(
                          fontSize: 11, color: _textSecondary),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      date,
                      style: const TextStyle(
                          fontSize: 10, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Amount + Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp${_formatCurrency(amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _processRefund(refund),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _successColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            paidWithWallet ? 'Refund' : 'Proses',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool isWallet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isWallet
            ? _walletColor.withOpacity(0.1)
            : _transferColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isWallet ? 'WALLET' : 'TRANSFER',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isWallet ? _walletColor : _transferColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================================
  // DETAIL VIEW
  // ============================================================================
  Widget _buildDetailView() {
    if (_selectedRefund == null) return const SizedBox.shrink();

    final refund = _selectedRefund!;
    final paidWithWallet = refund['paid_with_wallet'] == true;
    final userData = refund['users'] as Map<String, dynamic>;
    final amount = paidWithWallet
        ? (refund['wallet_deducted_amount'] ?? 0).toDouble()
        : (refund['refund_amount'] ?? refund['total_harga'] ?? 0).toDouble();
    final color = paidWithWallet ? _walletColor : _transferColor;
    final date = DateFormat('dd MMMM yyyy, HH:mm')
        .format(DateTime.parse(refund['created_at']));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_outline, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['nama'] ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userData['email'] ?? '-',
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                      if (userData['no_telp'] != null)
                        Text(
                          userData['no_telp'],
                          style: const TextStyle(
                              fontSize: 11, color: _textSecondary),
                        ),
                    ],
                  ),
                ),
                _buildTypeBadge(paidWithWallet),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Amount highlight ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: color, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah Refund',
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp${_formatCurrency(amount)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Order details ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildInfoRow('Order ID', refund['id_pesanan'] ?? '-'),
                _buildInfoRow('Status', refund['status_pesanan'] ?? '-'),
                _buildInfoRow('Metode', refund['payment_method'] ?? '-'),
                _buildInfoRow('Tanggal', date),
                if (refund['alasan_cancel'] != null)
                  _buildInfoRow('Alasan', refund['alasan_cancel']),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info notice ──────────────────────────────────────
          if (!paidWithWallet)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _transferColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _transferColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      size: 16, color: _transferColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pastikan refund manual sudah diproses terlebih dahulu melalui Midtrans Dashboard sebelum menekan tombol di bawah.',
                      style: TextStyle(fontSize: 11, color: _transferColor),
                    ),
                  ),
                ],
              ),
            ),

          // ── Action button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _processRefund(refund),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: Text(
                paidWithWallet ? 'Proses Refund Wallet' : 'Tandai Sudah Diproses',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _successColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INFO ROW (for detail view)
  // ============================================================================
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
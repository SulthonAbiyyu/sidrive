// lib/screens/common/withdrawal_history_screen.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawalHistoryScreen> createState() => _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  final WalletService _walletService = WalletService();
  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final history = await _walletService.getWithdrawalHistory(userId);

      setState(() {
        _withdrawals = history;
      });
    } catch (e) {
      print('❌ Error load history: $e');
      _showSnackBar('Gagal memuat riwayat', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': // ✅ FIXED: bukan 'completed'
        return Colors.green;
      case 'pending':
      case 'diproses':
        return Colors.orange;
      case 'ditolak': // ✅ FIXED: bukan 'rejected'
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': // ✅ FIXED: bukan 'completed'
        return 'Selesai';
      case 'pending':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'ditolak': // ✅ FIXED: bukan 'rejected'
        return 'Ditolak';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': // ✅ FIXED: bukan 'completed'
        return Icons.check_circle;
      case 'pending':
      case 'diproses':
        return Icons.access_time;
      case 'ditolak': // ✅ FIXED: bukan 'rejected'
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penarikan'),
        elevation: 0,
        backgroundColor: const Color(0xFF00880F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _withdrawals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                    itemCount: _withdrawals.length,
                    itemBuilder: (context, index) {
                      return _buildWithdrawalCard(_withdrawals[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          ResponsiveMobile.vSpace(16),
          Text(
            'Belum ada riwayat penarikan',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(16),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    final status = withdrawal['status'] as String? ?? 'pending';
    final amount = (withdrawal['jumlah'] as num?)?.toDouble() ?? 0;
    final bankName = withdrawal['nama_bank'] as String? ?? '-';
    final accountNumber = withdrawal['nomor_rekening'] as String? ?? '-';
    final accountName = withdrawal['nama_rekening'] as String? ?? '-';
    
    final dateStr = withdrawal['tanggal_pengajuan'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    final completedDateStr = withdrawal['tanggal_selesai'] as String?;
    final completedDate = completedDateStr != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(completedDateStr))
        : null;

    final adminNote = withdrawal['catatan_admin'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(12)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(withdrawal),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(10),
                      vertical: ResponsiveMobile.scaledH(6),
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 14,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: ResponsiveMobile.scaledSP(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00880F),
                    ),
                  ),
                ],
              ),

              ResponsiveMobile.vSpace(12),
              Divider(color: Colors.grey.shade200),
              ResponsiveMobile.vSpace(12),

              // Bank Info
              _buildInfoRow(Icons.account_balance, bankName),
              ResponsiveMobile.vSpace(8),
              _buildInfoRow(Icons.credit_card, _maskAccountNumber(accountNumber)),
              ResponsiveMobile.vSpace(8),
              _buildInfoRow(Icons.person, accountName),
              
              ResponsiveMobile.vSpace(12),
              Divider(color: Colors.grey.shade200),
              ResponsiveMobile.vSpace(8),

              // Date
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (completedDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        completedDate,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledSP(12),
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Admin note (if rejected)
              if (adminNote != null && adminNote.isNotEmpty) ...[
                ResponsiveMobile.vSpace(8),
                Container(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledW(10)),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          adminNote,
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledSP(11),
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(13),
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final masked = '•' * (accountNumber.length - 4);
    return '$masked$lastFour';
  }

  void _showDetailDialog(Map<String, dynamic> withdrawal) {
    final status = withdrawal['status'] as String? ?? 'pending';
    final amount = (withdrawal['jumlah'] as num?)?.toDouble() ?? 0;
    final bankName = withdrawal['nama_bank'] as String? ?? '-';
    final accountNumber = withdrawal['nomor_rekening'] as String? ?? '-';
    final accountName = withdrawal['nama_rekening'] as String? ?? '-';
    final withdrawalId = withdrawal['id_penarikan'] as String? ?? '-';
    
    final dateStr = withdrawal['tanggal_pengajuan'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(date);

    final completedDateStr = withdrawal['tanggal_selesai'] as String?;
    final completedDate = completedDateStr != null 
        ? DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(completedDateStr))
        : null;

    final proofUrl = withdrawal['bukti_transfer'] as String?;
    final adminNote = withdrawal['catatan_admin'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Detail Penarikan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount
              Center(
                child: Column(
                  children: [
                    Text(
                      'Jumlah Penarikan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00880F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Details
              _buildDetailRow('ID Penarikan', withdrawalId.substring(0, 8)),
              const SizedBox(height: 12),
              _buildDetailRow('Status', _getStatusText(status)),
              const SizedBox(height: 12),
              _buildDetailRow('Bank', bankName),
              const SizedBox(height: 12),
              _buildDetailRow('Nomor Rekening', accountNumber),
              const SizedBox(height: 12),
              _buildDetailRow('Nama Pemilik', accountName),
              const SizedBox(height: 12),
              _buildDetailRow('Tanggal Pengajuan', formattedDate),
              
              if (completedDate != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Tanggal Selesai', completedDate),
              ],

              if (adminNote != null && adminNote.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Catatan Admin',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adminNote,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ],

              if (proofUrl != null && proofUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Open proof image
                    _showSnackBar('Fitur lihat bukti segera hadir', Colors.blue);
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Lihat Bukti Transfer'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
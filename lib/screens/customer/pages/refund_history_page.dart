import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:intl/intl.dart';

class RefundHistoryPage extends StatefulWidget {
  const RefundHistoryPage({Key? key}) : super(key: key);

  @override
  State<RefundHistoryPage> createState() => _RefundHistoryPageState();
}

class _RefundHistoryPageState extends State<RefundHistoryPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _refunds = [];

  @override
  void initState() {
    super.initState();
    _loadRefundHistory();
  }

  Future<void> _loadRefundHistory() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get pesanan yang ada refund
      final response = await _supabase
          .from('pesanan')
          .select('''
            id_pesanan,
            total_harga,
            refund_amount,
            refund_status,
            refund_processed_at,
            payment_method,
            paid_with_wallet,
            wallet_deducted_amount,
            status_pesanan,
            jenis_kendaraan,
            alamat_asal,
            alamat_tujuan,
            created_at
          ''')
          .eq('id_user', userId)
          .not('refund_status', 'is', null)
          .order('refund_processed_at', ascending: false);

      setState(() {
        _refunds = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('✅ Loaded ${_refunds.length} refunds');
    } catch (e) {
      print('❌ Error loading refunds: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'pending_manual':
        return 'Diproses';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending_manual':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Riwayat Refund'),
        backgroundColor: const Color(0xFFFF9EC5),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRefundHistory,
        color: const Color(0xFFFF9EC5),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _refunds.isEmpty
                ? _buildEmptyState()
                : _buildRefundList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: ResponsiveMobile.scaledW(80),
              color: Colors.grey.shade400,
            ),
            ResponsiveMobile.vSpace(16),
            Text(
              'Belum Ada Refund',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledSP(18),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            ResponsiveMobile.vSpace(8),
            Text(
              'Riwayat refund Anda akan muncul di sini',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledSP(14),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundList() {
    return ListView.builder(
      padding: ResponsiveMobile.allScaledPadding(16),
      itemCount: _refunds.length,
      itemBuilder: (context, index) {
        final refund = _refunds[index];
        final paidWithWallet = refund['paid_with_wallet'] == true;
        final amount = paidWithWallet
            ? (refund['wallet_deducted_amount'] ?? 0).toDouble()
            : (refund['refund_amount'] ?? refund['total_harga'] ?? 0).toDouble();
        final status = refund['refund_status'];
        final isCompleted = status == 'completed';

        return Container(
          margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status Badge + Amount
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
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.schedule,
                            size: ResponsiveMobile.scaledW(14),
                            color: _getStatusColor(status),
                          ),
                          ResponsiveMobile.hSpace(6),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledSP(12),
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF9EC5),
                      ),
                    ),
                  ],
                ),

                ResponsiveMobile.vSpace(12),
                Divider(height: 1, color: Colors.grey.shade200),
                ResponsiveMobile.vSpace(12),

                // Order Info
                _buildInfoRow(
                  Icons.confirmation_number_outlined,
                  'Order ID',
                  refund['id_pesanan'].toString().substring(0, 13) + '...',
                ),
                ResponsiveMobile.vSpace(8),
                _buildInfoRow(
                  paidWithWallet ? Icons.account_balance_wallet : Icons.payment,
                  'Metode',
                  paidWithWallet ? 'Wallet' : 'Transfer',
                ),
                ResponsiveMobile.vSpace(8),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal Refund',
                  refund['refund_processed_at'] != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(
                          DateTime.parse(refund['refund_processed_at']))
                      : 'Belum diproses',
                ),

                // Info Box untuk Transfer
                if (!paidWithWallet && status == 'completed') ...[
                  ResponsiveMobile.vSpace(12),
                  Container(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: ResponsiveMobile.scaledW(18),
                          color: Colors.blue.shade700,
                        ),
                        ResponsiveMobile.hSpace(8),
                        Expanded(
                          child: Text(
                            'Dana akan kembali ke rekening Anda dalam 3-5 hari kerja',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledSP(11),
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Info Box untuk Pending
                if (status == 'pending_manual') ...[
                  ResponsiveMobile.vSpace(12),
                  Container(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: ResponsiveMobile.scaledW(18),
                          color: Colors.orange.shade700,
                        ),
                        ResponsiveMobile.hSpace(8),
                        Expanded(
                          child: Text(
                            'Refund sedang diproses oleh admin',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledSP(11),
                              color: Colors.orange.shade700,
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
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveMobile.scaledW(16),
          color: Colors.grey.shade600,
        ),
        ResponsiveMobile.hSpace(8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledSP(13),
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(13),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
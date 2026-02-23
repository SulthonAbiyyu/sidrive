// lib/core/widgets/wallet_actions.dart
// ============================================================================
// WALLET ACTIONS - UPDATED VERSION
// ✅ WithdrawBottomSheet TANPA button Riwayat (sudah pindah ke wallet widget)
// ✅ Design lebih clean dan fokus
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/services/wallet_topup_service.dart';
import 'package:sidrive/screens/customer/pages/wallet_topup_payment_screen.dart';
import 'package:sidrive/screens/common/withdrawal_screen.dart';
import 'package:sidrive/services/wallet_settlement_service.dart';
import 'package:sidrive/screens/driver/pages/settlement_payment_screen.dart';

// ============================================================================
// 1. TOP UP BOTTOM SHEET (TIDAK BERUBAH)
// ============================================================================
class TopUpBottomSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final Function(double) onSuccess;
  final bool isCashSettlement;

  const TopUpBottomSheet({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.onSuccess,
    this.isCashSettlement = false,
  }) : super(key: key);

  @override
  State<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends State<TopUpBottomSheet> {
  final WalletTopUpService _topUpService = WalletTopUpService();
  int? _selectedAmount;
  bool _isProcessing = false;

  final List<int> _amounts = [
    10000, 25000, 50000, 100000, 250000, 500000,
  ];

  Future<void> _processTopUp() async {
    if (_selectedAmount == null) {
      _showSnackBar('Pilih nominal top up terlebih dahulu', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('🚀 Starting top up process...');

      final result = await _topUpService.createTopUpTransaction(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
        userPhone: widget.userPhone,
        amount: _selectedAmount!.toDouble(),
        userRole: widget.isCashSettlement ? 'driver_settlement' : 'customer',
      );

      if (!mounted) return;

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalletTopUpPaymentScreen(
            paymentUrl: result['redirect_url'],
            orderId: result['order_id'],
            amount: _selectedAmount!.toDouble(),
            userId: widget.userId,
            userRole: 'customer',
            onSuccess: widget.onSuccess,
          ),
        ),
      );

    } catch (e) {
      print('❌ Error top up: $e');
      if (mounted) {
        _showSnackBar('❌ Gagal membuat transaksi: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ResponsiveMobile.vSpace(20),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00880F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF00880F),
                    size: ResponsiveMobile.scaledW(24),
                  ),
                ),
                ResponsiveMobile.hSpace(12),
                Text(
                  'Top Up Wallet',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledSP(24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ResponsiveMobile.vSpace(24),

            Text(
              'Pilih Nominal',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledSP(16),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            ResponsiveMobile.vSpace(12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: ResponsiveMobile.scaledW(12),
                mainAxisSpacing: ResponsiveMobile.scaledH(12),
                childAspectRatio: 2.2,
              ),
              itemCount: _amounts.length,
              itemBuilder: (context, index) {
                final amount = _amounts[index];
                final isSelected = _selectedAmount == amount;
                return _buildAmountButton(amount, isSelected);
              },
            ),

            ResponsiveMobile.vSpace(24),

            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  ResponsiveMobile.hSpace(12),
                  Expanded(
                    child: Text(
                      'Pembayaran melalui Midtrans (QRIS, Bank Transfer, E-Wallet)',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(12),
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ResponsiveMobile.vSpace(24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00880F),
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveMobile.scaledH(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: ResponsiveMobile.scaledW(20)),
                          ResponsiveMobile.hSpace(8),
                          Text(
                            _selectedAmount != null
                                ? 'Bayar ${CurrencyFormatter.format(_selectedAmount!)}'
                                : 'Pilih Nominal',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledSP(16),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            ResponsiveMobile.vSpace(16),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButton(int amount, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedAmount = amount;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00880F).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF00880F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        ),
        child: Center(
          child: Text(
            CurrencyFormatter.formatCompact(amount.toDouble()),
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(14),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF00880F) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. DRIVER TOP UP CHOICE BOTTOM SHEET (KHUSUS DRIVER)
// ============================================================================
class DriverTopUpChoiceBottomSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String driverId;
  final Function(double) onSuccess;

  const DriverTopUpChoiceBottomSheet({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.driverId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
      ),
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ResponsiveMobile.vSpace(20),

          Text(
            'Pilih Jenis Top Up',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveMobile.vSpace(8),
          Text(
            'Pilih tujuan top up Anda',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(14),
              color: Colors.grey.shade600,
            ),
          ),
          ResponsiveMobile.vSpace(24),

          // Option 1: Top Up untuk Diri Sendiri
          _buildChoiceCard(
            context: context,
            icon: Icons.account_balance_wallet,
            title: 'Top Up Wallet',
            subtitle: 'Isi saldo untuk bertransaksi',
            color: const Color(0xFF00880F),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TopUpBottomSheet(
                  userId: userId,
                  userName: userName,
                  userEmail: userEmail,
                  userPhone: userPhone,
                  onSuccess: onSuccess,
                  isCashSettlement: false,
                ),
              );
            },
          ),

          ResponsiveMobile.vSpace(12),

          // Option 2: Setor Cash ke Admin
          _buildChoiceCard(
            context: context,
            icon: Icons.payment,
            title: 'Setor Cash ke Admin',
            subtitle: 'Setor hasil order pembayaran cash',
            color: Colors.orange,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CashSettlementBottomSheet(
                  userId: userId,
                  userName: userName,
                  userEmail: userEmail,
                  userPhone: userPhone,
                  driverId: driverId,
                  onSuccess: onSuccess,
                ),
              );
            },
          ),

          ResponsiveMobile.vSpace(16),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            ResponsiveMobile.hSpace(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ResponsiveMobile.vSpace(4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(13),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. CASH SETTLEMENT BOTTOM SHEET (KHUSUS DRIVER - NOMINAL AUTO-FILL)
// ============================================================================
class CashSettlementBottomSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String driverId;
  final Function(double) onSuccess;

  const CashSettlementBottomSheet({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.driverId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<CashSettlementBottomSheet> createState() => _CashSettlementBottomSheetState();
}

class _CashSettlementBottomSheetState extends State<CashSettlementBottomSheet> {
  final WalletSettlementService _settlementService = WalletSettlementService();
  bool _isProcessing = false;
  bool _isLoading = true;
  
  double _cashPending = 0;
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettlementData();
  }

  Future<void> _loadSettlementData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _settlementService.getDriverCashPending(widget.driverId);

      setState(() {
        _cashPending = data['cash_pending'];
        _orderCount = data['order_count'];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error load settlement data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Gagal memuat data settlement', Colors.red);
      }
    }
  }

  Future<void> _processSettlement() async {
    if (_cashPending <= 0) {
      _showSnackBar('Tidak ada cash yang perlu disetor', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('🚀 Starting cash settlement process...');
      print('💰 Cash Pending: Rp${_cashPending.toStringAsFixed(0)}');

      // ✅ PAKAI SETTLEMENT SERVICE (BUKAN TOP-UP SERVICE)
      final result = await _settlementService.createSettlementTransaction(
        driverId: widget.driverId,
        driverName: widget.userName,
        driverEmail: widget.userEmail,
        driverPhone: widget.userPhone,
        amount: _cashPending,
      );

      if (!mounted) return;

      Navigator.pop(context);

      // ✅ Redirect ke payment screen (sama seperti top-up biasa)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettlementPaymentScreen(
            paymentUrl: result['redirect_url'],
            orderId: result['order_id'],
            amount: _cashPending,
            driverId: widget.driverId,
            onSuccess: () {
              widget.onSuccess(_cashPending);
            },
          ),
        ),
      );

    } catch (e) {
      print('❌ Error settlement: $e');
      if (mounted) {
        _showSnackBar('❌ Gagal membuat transaksi: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ResponsiveMobile.vSpace(20),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Colors.orange,
                    size: ResponsiveMobile.scaledW(24),
                  ),
                ),
                ResponsiveMobile.hSpace(12),
                Text(
                  'Setor Cash ke Admin',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledSP(24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ResponsiveMobile.vSpace(24),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledH(40)),
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                ),
              )
            else ...[
              // Info Order Count
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.orange.shade700, size: 24),
                    ResponsiveMobile.hSpace(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Belum Disetor',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledSP(12),
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$_orderCount Order',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledSP(18),
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              ResponsiveMobile.vSpace(16),

              // Nominal Settlement (Auto-fill & Readonly)
              Text(
                'Total Cash yang Harus Disetor',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledSP(14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              ResponsiveMobile.vSpace(12),

              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
                        ResponsiveMobile.hSpace(8),
                        Text(
                          'Nominal Otomatis',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledSP(13),
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(_cashPending),
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(20),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              ResponsiveMobile.vSpace(20),

              // Info Box
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        ResponsiveMobile.hSpace(8),
                        Text(
                          'Informasi Penting',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledSP(13),
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ResponsiveMobile.vSpace(8),
                    Text(
                      '• Nominal sudah otomatis sesuai total cash order\n'
                      '• Pembayaran via Midtrans (QRIS, Transfer, E-Wallet)\n'
                      '• Setelah bayar, menunggu approval admin\n'
                      '• Counter akan direset setelah admin approve\n'
                      '• Fee platform 20% (otomatis dipotong)',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(12),
                        color: Colors.blue.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              ResponsiveMobile.vSpace(24),

              // Button Setor
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isProcessing || _cashPending <= 0) ? null : _processSettlement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: ResponsiveMobile.scaledW(20)),
                            ResponsiveMobile.hSpace(8),
                            Text(
                              _cashPending > 0
                                  ? 'Bayar ${CurrencyFormatter.format(_cashPending)}'
                                  : 'Tidak Ada Cash',
                              style: TextStyle(
                                fontSize: ResponsiveMobile.scaledSP(16),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
            
            ResponsiveMobile.vSpace(16),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. WITHDRAW BOTTOM SHEET - UPDATED (TANPA BUTTON RIWAYAT)
// ============================================================================
class WithdrawBottomSheet extends StatelessWidget {
  final String userId;
  final double currentBalance;

  const WithdrawBottomSheet({
    Key? key,
    required this.userId,
    required this.currentBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveMobile.scaledR(24)),
        ),
      ),
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ResponsiveMobile.vSpace(20),

          Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
            decoration: BoxDecoration(
              color: const Color(0xFF00880F).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: const Color(0xFF00880F),
              size: ResponsiveMobile.scaledW(40),
            ),
          ),
          ResponsiveMobile.vSpace(16),

          Text(
            'Tarik Saldo',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveMobile.vSpace(8),

          Text(
            'Saldo Tersedia: ${CurrencyFormatter.format(currentBalance)}',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledSP(14),
              color: const Color(0xFF00880F),
              fontWeight: FontWeight.w600,
            ),
          ),
          ResponsiveMobile.vSpace(24),

          Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    ResponsiveMobile.hSpace(8),
                    Expanded(
                      child: Text(
                        'Minimal penarikan Rp 50.000\nMaksimal Rp 5.000.000 per transaksi\nProses 1-3 hari kerja',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledSP(12),
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ResponsiveMobile.vSpace(24),

          // ✅ HANYA 1 BUTTON: Tarik Saldo (Riwayat sudah pindah ke wallet widget)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WithdrawalScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Tarik Saldo'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveMobile.scaledH(16),
                ),
                backgroundColor: const Color(0xFF00880F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                elevation: 2,
              ),
            ),
          ),
          ResponsiveMobile.vSpace(16),
        ],
      ),
    );
  }
}
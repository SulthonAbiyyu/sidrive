import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  
import 'package:sidrive/screens/customer/pages/customer_live_tracking.dart';
import 'package:sidrive/screens/customer/pages/riwayat_customer.dart';
import 'package:sidrive/services/order_timer_service.dart';
import 'package:sidrive/services/wallet_service.dart';

class OrderSearchingDialog extends StatefulWidget {
  final Map<String, dynamic> pesananData;
  final VoidCallback onCancel;

  const OrderSearchingDialog({
    super.key,
    required this.pesananData,
    required this.onCancel,
  });

  @override
  State<OrderSearchingDialog> createState() => _OrderSearchingDialogState();
}

class _OrderSearchingDialogState extends State<OrderSearchingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  final _timerService = OrderTimerService();
  StreamSubscription? _orderStream;
  bool _isNavigating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _updateStatusToSearching();
    _initializeTimer(); 
    _listenToOrderStatus();
    _listenToTimerService();
  }

  Future<void> _updateStatusToSearching() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 [OrderSearching] Checking current order status...');
      
      final supabase = Supabase.instance.client;
      
      final currentOrder = await supabase
          .from('pesanan')
          .select('status_pesanan, search_start_time')
          .eq('id_pesanan', widget.pesananData['id_pesanan'])
          .single();
      
      final currentStatus = currentOrder['status_pesanan'];
      print('📊 [OrderSearching] Current status: $currentStatus');
      
      if (currentStatus == 'diterima') {
        print('⚠️ [OrderSearching] Order already accepted, skipping');
        return;
      }
      
      // ✅ JIKA STATUS SUDAH mencari_driver DAN ADA search_start_time
      if (currentStatus == 'mencari_driver' && currentOrder['search_start_time'] != null) {
        print('✅ [OrderSearching] Already searching, timer should be active');
        return;
      }
      
      // ✅ JIKA STATUS mencari_driver TAPI TIDAK ADA search_start_time
      if (currentStatus == 'mencari_driver' && currentOrder['search_start_time'] == null) {
        print('🔧 [OrderSearching] Setting search_start_time...');
        
        await supabase.from('pesanan').update({
          'search_start_time': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', widget.pesananData['id_pesanan']);
        
        print('✅ [OrderSearching] search_start_time set');
        return;
      }
      
      // ✅ JIKA STATUS menunggu_pembayaran ATAU paid, UPDATE KE mencari_driver
      if (currentStatus == 'menunggu_pembayaran' || currentStatus == 'paid') {
        print('🔄 [OrderSearching] Updating status to mencari_driver...');
        
        await supabase.from('pesanan').update({
          'status_pesanan': 'mencari_driver',
          'payment_status': 'paid',
          'search_start_time': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', widget.pesananData['id_pesanan']);
        
        print('✅ [OrderSearching] Status updated to mencari_driver');
      }
    } catch (e) {
      print('❌ [OrderSearching] Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeTimer() async {
    print('🕐 [OrderSearching] Initializing timer...');
    
    try {
      final supabase = Supabase.instance.client;
      
      // ✅ CEK APAKAH TIMER SUDAH AKTIF
      if (_timerService.hasActiveTimer && 
          _timerService.activeOrderId == widget.pesananData['id_pesanan']) {
        print('✅ [OrderSearching] Timer already active, skipping...');
        return;
      }
      
      // ✅ CEK search_start_time DARI DATABASE
      final order = await supabase
          .from('pesanan')
          .select('search_start_time, created_at')
          .eq('id_pesanan', widget.pesananData['id_pesanan'])
          .single();
      
      final searchStartTime = order['search_start_time'];
      
      // ✅ JIKA SUDAH ADA search_start_time → RESTORE
      if (searchStartTime != null) {
        final startTime = DateTime.parse(searchStartTime);
        final now = DateTime.now();
        final elapsed = now.difference(startTime).inSeconds;
        
        print('📊 [OrderSearching] Found search_start_time, elapsed: $elapsed sec');
        
        if (elapsed >= 120) {
          print('⏰ [OrderSearching] Timer already expired');
          return;
        }
        
        _timerService.restoreTimer(widget.pesananData['id_pesanan'], startTime);
        print('✅ [OrderSearching] Timer restored from database');
      } 
      // ✅ JIKA BELUM ADA search_start_time → START BARU
      else {
        print('🆕 [OrderSearching] No search_start_time, starting new timer');
        _timerService.startTimer(widget.pesananData['id_pesanan']);
        print('✅ [OrderSearching] New timer started');
      }
      
    } catch (e) {
      print('❌ [OrderSearching] Error initializing timer: $e');
      // Fallback: start timer baru jika error
      _timerService.startTimer(widget.pesananData['id_pesanan']);
    }
  }

  void _listenToTimerService() {
    _timerService.addListener(() {
      if (!mounted) return;
      
      if (_timerService.remainingSeconds == 0 && 
          _timerService.activeOrderId == widget.pesananData['id_pesanan']) {
        print('⏰ [OrderSearching] Timer finished, processing timeout with refund...');
        _processTimeoutWithRefund();
      }
      
      setState(() {});
    });
  }

  // ✅ METHOD BARU DENGAN NAMA BERBEDA
  Future<void> _processTimeoutWithRefund() async {
    try {
      print('⏰ [OrderSearching] Processing timeout with auto refund...');
      
      final supabase = Supabase.instance.client;
      
      // 1. Get order data
      final pesanan = await supabase
          .from('pesanan')
          .select('id_user, paid_with_wallet, wallet_deducted_amount, status_pesanan')
          .eq('id_pesanan', widget.pesananData['id_pesanan'])
          .single();
      
      final currentStatus = pesanan['status_pesanan'];
      
      // Jika sudah diterima, skip refund
      if (currentStatus == 'diterima') {
        print('✅ [OrderSearching] Order already accepted, no refund needed');
        widget.onCancel();
        return;
      }
      
      final paidWithWallet = pesanan['paid_with_wallet'] == true;
      final walletAmount = (pesanan['wallet_deducted_amount'] ?? 0).toDouble();
      final userId = pesanan['id_user'];
      
      // 2. Update status ke gagal
      await supabase.from('pesanan').update({
        'status_pesanan': 'gagal',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', widget.pesananData['id_pesanan']);
      
      // 3. Refund jika pakai wallet
      if (paidWithWallet && walletAmount > 0) {
        print('💸 [OrderSearching] Processing refund: Rp${walletAmount.toStringAsFixed(0)}');
        
        final walletService = WalletService();
        final refunded = await walletService.refundWalletForFailedOrder(
          userId: userId,
          orderId: widget.pesananData['id_pesanan'],
          amount: walletAmount,
          reason: 'Driver tidak ditemukan (timeout)',
        );
        
        if (refunded) {
          print('✅ [OrderSearching] Refund successful');
        }
      }
      
      // 4. Call onCancel callback
      widget.onCancel();
      
    } catch (e) {
      print('❌ [OrderSearching] Error handling timeout: $e');
      widget.onCancel();
    }
  }

  void _listenToOrderStatus() {
    final supabase = Supabase.instance.client;
    
    _orderStream = supabase
        .from('pesanan')
        .stream(primaryKey: ['id_pesanan'])
        .eq('id_pesanan', widget.pesananData['id_pesanan'])
        .listen((data) {
          if (data.isEmpty || !mounted || _isNavigating) return;
          
          final order = data.first;
          final status = order['status_pesanan'];
          
          print('📡 [OrderSearching] Status update: $status');
          
          if (status == 'diterima') {
            print('✅ [OrderSearching] Driver accepted! Navigating to tracking...');
            
            _isNavigating = true;
            _timerService.cancelTimer();
            _orderStream?.cancel();
            
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => CustomerLiveTracking(
                    idPesanan: widget.pesananData['id_pesanan'],
                    pesananData: order,
                  ),
                ),
                (route) => route.isFirst,
              );
            }
          }
          
          if (status == 'dibatalkan') {
            print('⚠️ [OrderSearching] Order cancelled');
            
            if (!_isNavigating && mounted) {
              _isNavigating = true;
              _timerService.cancelTimer();
              _orderStream?.cancel();
              Navigator.pop(context);
            }
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _orderStream?.cancel();
    super.dispose();
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final number = value is num ? value : double.tryParse(value.toString()) ?? 0;
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _navigateToRiwayatOjek() {
    final userId = widget.pesananData['id_user'];
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => RiwayatCustomer(
          userId: userId,
          initialTab: 0, // Tab Ojek Online
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToRiwayatOjek();
        return false; // Cegah pop default, kita handle sendiri
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.wp(context, 5),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveMobile.isTablet(context) ? 420 : double.infinity,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎯 HEADER SECTION
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFB6C1),
                      Color(0xFFFF6B9D),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // ✅ BACK BUTTON
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _navigateToRiwayatOjek,
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                    
                    // Animated Icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.search_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 12),
                    
                    Text(
                      'Mencari Driver',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      'Tunggu sebentar...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Timer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _timerService.getFormattedTime(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 📋 DETAIL SECTION
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactInfo(
                              icon: Icons.motorcycle,
                              label: widget.pesananData['jenis_kendaraan']
                                      ?.toString()
                                      .toUpperCase() ??
                                  'MOTOR',
                              color: Color(0xFFFF6B9D),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildCompactInfo(
                              icon: Icons.straighten,
                              label: '${widget.pesananData['jarak_km']} km',
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Total harga
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF6B9D).withOpacity(0.1),
                              Color(0xFFFFB6C1).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFFF6B9D).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Rp ${_formatCurrency(widget.pesananData['total_harga'])}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B9D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Buttons
                      Row(
                        children: [                    
                          // Cancel button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onCancel,
                              icon: Icon(Icons.close, size: 18),
                              label: Text('Batalkan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
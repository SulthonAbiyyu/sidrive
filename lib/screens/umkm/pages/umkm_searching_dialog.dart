import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/screens/customer/pages/customer_umkm_tracking.dart';
import 'package:sidrive/services/order_timer_service.dart';
import 'package:sidrive/services/wallet_service.dart';

class UmkmSearchingDialog extends StatefulWidget {
  final Map<String, dynamic> pesananData;
  final VoidCallback onCancel;

  const UmkmSearchingDialog({
    super.key,
    required this.pesananData,
    required this.onCancel,
  });

  @override
  State<UmkmSearchingDialog> createState() => _UmkmSearchingDialogState();
}

class _UmkmSearchingDialogState extends State<UmkmSearchingDialog>
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
      print('🔄 [UmkmSearching] Checking current order status...');
      
      final supabase = Supabase.instance.client;
      
      final currentOrder = await supabase
          .from('pesanan')
          .select('status_pesanan, search_start_time')
          .eq('id_pesanan', widget.pesananData['id_pesanan'])
          .single();
      
      final currentStatus = currentOrder['status_pesanan'];
      print('📊 [UmkmSearching] Current status: $currentStatus');
      
      if (currentStatus == 'diterima') {
        print('⚠️ [UmkmSearching] Order already accepted');
        return;
      }
      
      if (currentStatus == 'mencari_driver' && currentOrder['search_start_time'] != null) {
        print('✅ [UmkmSearching] Already searching');
        return;
      }
      
      if (currentStatus == 'mencari_driver' && currentOrder['search_start_time'] == null) {
        print('🔧 [UmkmSearching] Setting search_start_time...');
        
        await supabase.from('pesanan').update({
          'search_start_time': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', widget.pesananData['id_pesanan']);
        
        print('✅ [UmkmSearching] search_start_time set');
        return;
      }
      
      if (currentStatus == 'menunggu_pembayaran' || currentStatus == 'paid') {
        print('🔄 [UmkmSearching] Updating to mencari_driver...');
        
        await supabase.from('pesanan').update({
          'status_pesanan': 'mencari_driver',
          'payment_status': 'paid',
          'search_start_time': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', widget.pesananData['id_pesanan']);
        
        print('✅ [UmkmSearching] Status updated');
      }
    } catch (e) {
      print('❌ [UmkmSearching] Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeTimer() async {
    print('🕐 [UmkmSearching] Initializing timer...');
    
    try {
      final supabase = Supabase.instance.client;
      
      if (_timerService.hasActiveTimer && 
          _timerService.activeOrderId == widget.pesananData['id_pesanan']) {
        print('✅ [UmkmSearching] Timer already active');
        return;
      }
      
      final order = await supabase
          .from('pesanan')
          .select('search_start_time, created_at')
          .eq('id_pesanan', widget.pesananData['id_pesanan'])
          .single();
      
      final searchStartTime = order['search_start_time'];
      
      if (searchStartTime != null) {
        final startTime = DateTime.parse(searchStartTime);
        final now = DateTime.now();
        final elapsed = now.difference(startTime).inSeconds;
        
        print('📊 [UmkmSearching] Elapsed: $elapsed sec');
        
        if (elapsed >= 120) {
          print('⏰ [UmkmSearching] Timer already expired');
          return;
        }
        
        _timerService.restoreTimer(widget.pesananData['id_pesanan'], startTime);
        print('✅ [UmkmSearching] Timer restored');
      } else {
        print('🆕 [UmkmSearching] Starting new timer');
        _timerService.startTimer(widget.pesananData['id_pesanan']);
        print('✅ [UmkmSearching] Timer started');
      }
      
    } catch (e) {
      print('❌ [UmkmSearching] Error: $e');
      _timerService.startTimer(widget.pesananData['id_pesanan']);
    }
  }

  void _listenToTimerService() {
    _timerService.addListener(() {
      if (!mounted) return;
      
      if (_timerService.remainingSeconds == 0 && 
          _timerService.activeOrderId == widget.pesananData['id_pesanan']) {
        print('⏰ [UmkmSearching] Timer finished');
        _processTimeout();  // ← GANTI dari _processTimeoutWithRefund ke _processTimeout
      }
      
      setState(() {});
    });
  }

  Future<void> _processTimeout() async {
    try {
      print('⏰ [UmkmSearching] Timer expired, checking status...');
      
      final supabase = Supabase.instance.client;
      
      // 1. Cek status terkini
      final pesanan = await supabase
          .from('pesanan')
          .select('status_pesanan, id_user, paid_with_wallet, wallet_deducted_amount, id_umkm, jenis_kendaraan, alamat_asal, alamat_tujuan, lokasi_asal, lokasi_tujuan, ongkir')
          .eq('id_pesanan', widget.pesananData['id_pesanan'])
          .single();
      
      final currentStatus = pesanan['status_pesanan'];
      print('📊 Current status: $currentStatus');
      
      // 2. Jika sudah diterima driver, tutup dialog
      if (currentStatus == 'dalam_pengiriman' || currentStatus == 'diterima') {
        print('✅ [UmkmSearching] Order already accepted by driver');
        if (mounted) widget.onCancel();
        return;
      }
      
      // 3. Belum ada driver? Show retry dialog
      if (mounted) {
        final shouldRetry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.timer_off, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('⏰ Waktu Habis'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Belum ada driver yang merespons dalam 2 menit.'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sistem akan mencoba mencari driver lagi',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Batalkan Pesanan', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Ya, Cari Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        );
        
        if (shouldRetry == true) {
          // 4. User mau retry - reset timer dan broadcast lagi
          print('🔄 [UmkmSearching] Retrying search...');
          
          setState(() => _isLoading = true);
          await _retrySearch(pesanan);
          setState(() => _isLoading = false);
          
        } else {
          // 5. User cancel - update status ke gagal dan refund
          print('❌ [UmkmSearching] User cancelled after timeout');
          
          await _cancelOrderWithRefund(pesanan);
        }
      }
      
    } catch (e) {
      print('❌ [UmkmSearching] Error processing timeout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onCancel();
      }
    }
  }

// ==================== STEP 2: TAMBAH METHOD _retrySearch ====================
// Tambahkan method baru ini setelah _processTimeout:

  Future<void> _retrySearch(Map<String, dynamic> pesanan) async {
    try {
      print('🔄 [UmkmSearching] Starting retry...');
      
      final supabase = Supabase.instance.client;
      
      // 1. Reset search_start_time
      await supabase.from('pesanan').update({
        'search_start_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', widget.pesananData['id_pesanan']);
      
      print('✅ search_start_time reset');
      
      // 2. Get customer name
      final userData = await supabase
          .from('users')
          .select('nama')
          .eq('id_user', pesanan['id_user'])
          .single();
      
      // 3. Get UMKM location
      final umkmData = await supabase
          .from('umkm')
          .select('lokasi_toko, alamat_toko')
          .eq('id_umkm', pesanan['id_umkm'])
          .single();
      
      // Parse locations
      String parseLat(String point) => point.replaceAll('POINT(', '').replaceAll(')', '').split(' ')[1];
      String parseLng(String point) => point.replaceAll('POINT(', '').replaceAll(')', '').split(' ')[0];
      
      final tokoLat = double.parse(parseLat(umkmData['lokasi_toko']));
      final tokoLng = double.parse(parseLng(umkmData['lokasi_toko']));
      final tujuanLat = double.parse(parseLat(pesanan['lokasi_tujuan']));
      final tujuanLng = double.parse(parseLng(pesanan['lokasi_tujuan']));
      
      // 4. Broadcast notif driver lagi
      print('📡 Broadcasting notification to drivers...');
      
      await supabase.functions.invoke(
        'send-new-order-notification',
        body: {
          'orderId': widget.pesananData['id_pesanan'],
          'customerId': pesanan['id_user'],
          'customerName': userData['nama'],
          'jenisPesanan': 'umkm',
          'jenisKendaraan': pesanan['jenis_kendaraan'],
          'lokasiJemput': umkmData['alamat_toko'],
          'lokasiTujuan': pesanan['alamat_tujuan'],
          'lokasiJemputLat': tokoLat,
          'lokasiJemputLng': tokoLng,
          'lokasiTujuanLat': tujuanLat,
          'lokasiTujuanLng': tujuanLng,
          'lokasiTokoLat': tokoLat,
          'lokasiTokoLng': tokoLng,
          'jarak': 0,
          'ongkir': pesanan['ongkir'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      print('✅ Notification sent');
      
      // 5. Restart timer
      _timerService.startTimer(widget.pesananData['id_pesanan']);
      
      print('✅ Timer restarted');
      print('✅ [UmkmSearching] Search retry complete');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 Mencari driver lagi...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('❌ [UmkmSearching] Error retry search: $e');
      rethrow;
    }
  }

// ==================== STEP 3: TAMBAH METHOD _cancelOrderWithRefund ====================
// Tambahkan method baru ini setelah _retrySearch:

  Future<void> _cancelOrderWithRefund(Map<String, dynamic> pesanan) async {
    try {
      print('❌ [UmkmSearching] Cancelling order with refund...');
      
      final supabase = Supabase.instance.client;
      
      // 1. Update to gagal
      await supabase.from('pesanan').update({
        'status_pesanan': 'gagal',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', widget.pesananData['id_pesanan']);
      
      print('✅ Status updated to gagal');
      
      // 2. Refund if wallet
      final paidWithWallet = pesanan['paid_with_wallet'] == true;
      final walletAmount = (pesanan['wallet_deducted_amount'] ?? 0).toDouble();
      
      if (paidWithWallet && walletAmount > 0) {
        print('💸 [UmkmSearching] Refunding Rp${walletAmount.toStringAsFixed(0)}');
        
        final walletService = WalletService();
        await walletService.refundWalletForFailedOrder(
          userId: pesanan['id_user'],
          orderId: widget.pesananData['id_pesanan'],
          amount: walletAmount,
          reason: 'Driver tidak ditemukan (timeout)',
        );
        
        print('✅ [UmkmSearching] Refund successful');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💰 Saldo wallet telah dikembalikan'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      // 3. Send notification to customer
      await supabase.from('notifikasi').insert({
        'id_user': pesanan['id_user'],
        'judul': 'Pesanan Gagal',
        'pesan': 'Maaf, driver tidak ditemukan. Saldo Anda telah dikembalikan.',
        'jenis': 'pesanan',
        'status': 'unread',
        'data_tambahan': {'id_pesanan': widget.pesananData['id_pesanan']},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ [UmkmSearching] Cancel complete');
      
      if (mounted) {
        widget.onCancel();
      }
      
    } catch (e) {
      print('❌ [UmkmSearching] Error cancel with refund: $e');
      rethrow;
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
          
          print('📡 [UmkmSearching] Status: $status');
          
          if (status == 'diterima') {
            print('✅ [UmkmSearching] Driver accepted!');
            
            _isNavigating = true;
            _timerService.cancelTimer();
            _orderStream?.cancel();
            
            if (mounted) {
              Navigator.pop(context); // Tutup dialog
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerUmkmTracking(
                    idPesanan: widget.pesananData['id_pesanan'],
                    pesananData: order,
                  ),
                ),
              );
            }
          }
          
          if (status == 'dibatalkan') {
            print('⚠️ [UmkmSearching] Order cancelled');
            
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
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
              // HEADER
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                    
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
                                : Icon(Icons.search_rounded, size: 30, color: Colors.white),
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
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                    SizedBox(height: 12),
                    
                    // Timer
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, color: Colors.white, size: 16),
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
              
              // DETAIL
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfo(
                              icon: Icons.store,
                              label: 'Pesanan UMKM',
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Total
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade50,
                              Colors.orange.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
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
                              CurrencyFormatter.formatRupiahWithPrefix(
                                widget.pesananData['total_harga'] ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo({
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
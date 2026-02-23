import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/screens/customer/pages/order_searching_dialog.dart';
import 'package:sidrive/screens/customer/pages/customer_live_tracking.dart';
import 'package:sidrive/screens/customer/pages/riwayat_customer.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> pesananData;

  const PaymentStatusScreen({
    Key? key,
    required this.orderId,
    required this.pesananData,
  }) : super(key: key);

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final _supabase = Supabase.instance.client;
  
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  String _status = 'checking';
  String _message = 'Memeriksa status pembayaran...';
  int _remainingSeconds = 300;

  @override
  void initState() {
    super.initState();
    _startPollingPaymentStatus();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  Future<void> _handleTimeout() async {
    print('⏰ Payment timeout!');
    _pollingTimer?.cancel();
    
    await _supabase.from('pesanan').update({
      'payment_status': 'timeout',
      'status_pesanan': 'dibatalkan',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id_pesanan', widget.orderId);

    if (mounted) {
      setState(() {
        _status = 'timeout';
        _message = 'Waktu pembayaran habis. Pesanan dibatalkan.';
      });
      
      await Future.delayed(Duration(seconds: 3));
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _startPollingPaymentStatus() {
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _checkPaymentStatus();
    });
    
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    try {
      print('🔍 Checking payment status for: ${widget.orderId}');
      
      final response = await _supabase.functions.invoke(
        'check-payment-status',
        body: {'orderId': widget.orderId},
      );

      if (response.status != 200 || response.data == null) {
        print('⚠️ Failed to check status, retrying...');
        return;
      }

      final data = response.data as Map<String, dynamic>;
      final transactionStatus = data['transaction_status'];
      
      print('💳 Transaction status: $transactionStatus');

      if (transactionStatus == 'capture' || transactionStatus == 'settlement') {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        
        // ✅ CEK JENIS PESANAN
        final pesanan = await _supabase
            .from('pesanan')
            .select('jenis, metode_pengiriman')
            .eq('id_pesanan', widget.orderId)
            .single();
        
        final jenis = pesanan['jenis'] ?? 'ojek';
        final metodePengiriman = pesanan['metode_pengiriman'];
        
        print('📦 Jenis: $jenis, Metode: $metodePengiriman');
        
        // ✅ TENTUKAN STATUS BERDASARKAN JENIS
        String newStatus;
        if (jenis == 'ojek') {
          // OJEK: Langsung mencari driver
          newStatus = 'mencari_driver';
        } else if (jenis == 'umkm') {
          // UMKM: Menunggu konfirmasi toko (TIDAK mencari driver dulu!)
          newStatus = 'menunggu_konfirmasi';
        } else {
          newStatus = 'mencari_driver';
        }
        
        print('✅ New status: $newStatus');
        
        // ✅ UPDATE PESANAN
        await _supabase.from('pesanan').update({
          'payment_status': 'paid',
          'status_pesanan': newStatus,
          'search_start_time': newStatus == 'mencari_driver' 
              ? DateTime.now().toIso8601String() 
              : null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', widget.orderId);

        if (!mounted) return;
        
        setState(() {
          _status = 'success';
          _message = jenis == 'ojek'
              ? 'Pembayaran berhasil! Mencari driver...'
              : 'Pembayaran berhasil! Menunggu konfirmasi toko...';
        });

        await Future.delayed(Duration(seconds: 1));
        
        if (!mounted) return;
        
        final updatedPesanan = await _supabase
            .from('pesanan')
            .select()
            .eq('id_pesanan', widget.orderId)
            .single();
        
        // ✅ ROUTING BERDASARKAN JENIS
        if (jenis == 'ojek') {
          // OJEK: Tampilkan dialog mencari driver
          _showOjekSearchingDialog(updatedPesanan);
        } else if (jenis == 'umkm') {
          // UMKM: Langsung ke riwayat (TIDAK ada dialog mencari driver!)
          _redirectToRiwayatUmkm();
        }

      } else if (transactionStatus == 'pending') {
        if (!mounted) return;
        
        setState(() {
          _status = 'pending';
          _message = 'Menunggu pembayaran...\n${_formatTime(_remainingSeconds)}';
        });
        
      } else if (transactionStatus == 'cancel' || transactionStatus == 'deny' || transactionStatus == 'expire') {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        
        await _supabase.from('pesanan').update({
          'payment_status': 'failed',
          'status_pesanan': 'dibatalkan',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', widget.orderId);

        if (!mounted) return;
        
        setState(() {
          _status = 'failed';
          _message = 'Pembayaran gagal atau dibatalkan';
        });
        
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
      
    } catch (e) {
      print('❌ Error checking payment: $e');
    }
  }

  // ✅ DIALOG UNTUK OJEK (YANG LAMA)
  void _showOjekSearchingDialog(Map<String, dynamic> pesananData) {
    StreamSubscription? orderStream;
    Timer? searchTimeoutTimer;
    
    print('🔍 [Ojek] Starting search...');
    
    searchTimeoutTimer = Timer(Duration(minutes: 2), () async {
      print('⏰ Search timeout!');
      orderStream?.cancel();
      
      await _supabase.from('pesanan').update({
        'status_pesanan': 'gagal',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', pesananData['id_pesanan']);
      
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      await Future.delayed(Duration(milliseconds: 300));
      
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Pencarian Driver Gagal'),
            content: Text('Tidak ada driver yang tersedia saat ini. Silakan coba lagi.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
            ],
          ),
        );
      }
    });
    
    orderStream = _supabase
        .from('pesanan')
        .stream(primaryKey: ['id_pesanan'])
        .eq('id_pesanan', pesananData['id_pesanan'])
        .listen((data) async {
          if (data.isEmpty || !mounted) return;
          
          final order = data.first;
          final status = order['status_pesanan'];
          
          print('📢 [Ojek] Status: $status');
          
          if (status == 'diterima') {
            searchTimeoutTimer?.cancel();
            orderStream?.cancel();
            
            if (!mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            
            await Future.delayed(Duration(milliseconds: 300));
            if (!mounted) return;
            
            Navigator.popUntil(context, (route) => route.isFirst);
            await Future.delayed(Duration(milliseconds: 100));
            
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerLiveTracking(
                  idPesanan: pesananData['id_pesanan'],
                  pesananData: order,
                ),
              ),
            );
          } else if (status == 'dibatalkan' || status == 'gagal') {
            searchTimeoutTimer?.cancel();
            orderStream?.cancel();
            
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            await Future.delayed(Duration(milliseconds: 300));
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          }
        });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OrderSearchingDialog(
        pesananData: pesananData,
        onCancel: () async {
          searchTimeoutTimer?.cancel();
          orderStream?.cancel();
          
          await _supabase.from('pesanan').update({
            'status_pesanan': 'dibatalkan',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id_pesanan', pesananData['id_pesanan']);
          
          if (mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            await Future.delayed(Duration(milliseconds: 300));
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          }
        },
      ),
    ).then((_) {
      searchTimeoutTimer?.cancel();
      orderStream?.cancel();
    });
  }

  // ✅ REDIRECT KE RIWAYAT UMKM (BARU!)
  void _redirectToRiwayatUmkm() {
    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          // Ambil userId dari pesananData
          final userId = widget.pesananData['id_user'];
          
          return RiwayatCustomer(
            userId: userId,
            initialTab: 1, // Tab UMKM (index 1)
          );
        },
      ),
      (route) => route.isFirst,
    );
    
    // Show success message
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Pesanan berhasil! Menunggu konfirmasi toko.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    });
  }


  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return 'Sisa waktu: ${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_status == 'checking' || _status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Harap tunggu hingga pembayaran selesai atau timeout'),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusIcon(),
                  
                  SizedBox(height: 32),
                  
                  Text(
                    _message,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 16),
                  
                  if (_status == 'checking' || _status == 'pending')
                    CircularProgressIndicator(),
                  
                  if (_status == 'failed' || _status == 'timeout')
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: Text('Kembali'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_status == 'success') {
      return Icon(Icons.check_circle, color: Colors.green, size: 100);
    } else if (_status == 'failed' || _status == 'timeout') {
      return Icon(Icons.cancel, color: Colors.red, size: 100);
    } else {
      return Icon(Icons.payment, color: Colors.blue, size: 100);
    }
  }
} 
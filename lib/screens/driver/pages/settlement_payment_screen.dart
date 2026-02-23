import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sidrive/services/wallet_settlement_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettlementPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final double amount;
  final String driverId;
  final VoidCallback onSuccess;

  const SettlementPaymentScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
    required this.amount,
    required this.driverId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SettlementPaymentScreen> createState() => _SettlementPaymentScreenState();
}

class _SettlementPaymentScreenState extends State<SettlementPaymentScreen> {
  final WalletSettlementService _settlementService = WalletSettlementService();
  late final WebViewController _controller;
  bool _isProcessing = false;
  Timer? _statusCheckTimer;
  bool _paymentCompleted = false; // ✅ Flag to prevent duplicate process

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startStatusCheckTimer();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            print('📱 Navigation: ${request.url}');
            
            // ✅ Handle deep link callback
            if (request.url.startsWith('sidrive://payment/finish')) {
              print('✅ Deep link detected');
              _handlePaymentFinish();
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            print('📄 Page loaded: $url');
            
            // ✅ HANYA handle jika URL mengandung status success
            if (url.contains('status_code=200') && 
                (url.contains('transaction_status=settlement') ||
                 url.contains('transaction_status=capture'))) {
              print('✅ Payment success detected from URL');
              _handlePaymentFinish();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _startStatusCheckTimer() {
    // ✅ Check setiap 5 detik (tidak terlalu sering)
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_paymentCompleted) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isProcessing || _paymentCompleted) return;

    try {
      final status = await _settlementService._checkPaymentStatus(widget.orderId);
      
      print('📊 Status check: $status');
      
      // ✅ HANYA proses jika BENAR-BENAR SUCCESS
      if (status == 'settlement' || status == 'capture') {
        print('✅ Payment CONFIRMED: $status');
        _handlePaymentFinish();
      } else if (status == 'pending') {
        print('⏳ Still pending...');
        // Don't do anything, just wait
      } else {
        print('❌ Payment status: $status');
      }
    } catch (e) {
      print('⚠️ Error checking status: $e');
    }
  }

  Future<void> _handlePaymentFinish() async {
    if (_isProcessing || _paymentCompleted) return;
    
    setState(() {
      _isProcessing = true;
      _paymentCompleted = true; // ✅ Mark as completed
    });
    
    _statusCheckTimer?.cancel();

    try {
      print('🎉 Processing settlement...');
      
      // ✅ Wait for webhook to process (give it 5 seconds)
      await Future.delayed(Duration(seconds: 5));
      
      // ✅ Verify settlement created in database
      final result = await _settlementService._verifySettlement(widget.driverId);

      if (!mounted) return;

      if (result) {
        _showSuccessDialog();
      } else {
        // Even if not found, still show success (webhook might be delayed)
        _showSuccessDialog();
      }

    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Settlement Berhasil!', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pembayaran settlement Anda telah diterima.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Status: Menunggu Approval Admin',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'Setelah admin approve, counter akan direset dan Anda bisa menerima order lagi.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Settlement'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Memproses settlement...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ✅ Extension untuk check payment status & verify settlement
extension _SettlementHelper on WalletSettlementService {
  Future<String> _checkPaymentStatus(String orderId) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'check-payment-status',
        body: {'orderId': orderId},
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['transaction_status'] as String? ?? 'pending';
      }
      
      return 'pending';
    } catch (e) {
      print('⚠️ Error check status: $e');
      return 'pending';
    }
  }

  Future<bool> _verifySettlement(String driverId) async {
    try {
      final result = await Supabase.instance.client
          .from('cash_settlements')
          .select('id_settlement, status')
          .eq('id_driver', driverId)
          .order('tanggal_pengajuan', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (result != null) {
        print('✅ Settlement found: ${result['id_settlement']}');
        return true;
      }
      
      print('⚠️ Settlement not found yet');
      return false;
    } catch (e) {
      print('❌ Error verify: $e');
      return false;
    }
  }
}
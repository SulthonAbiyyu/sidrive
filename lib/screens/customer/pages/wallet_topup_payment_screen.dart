import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sidrive/services/wallet_topup_service.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';

class WalletTopUpPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final double amount;
  final String userId;
  final String userRole; // 'customer', 'driver', 'umkm'
  final Function(double) onSuccess;

  const WalletTopUpPaymentScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
    required this.amount,
    required this.userId,
    required this.userRole,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<WalletTopUpPaymentScreen> createState() => _WalletTopUpPaymentScreenState();
}

class _WalletTopUpPaymentScreenState extends State<WalletTopUpPaymentScreen> {
  late final WebViewController _controller;
  final WalletTopUpService _topUpService = WalletTopUpService();
  
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  int _remainingSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _initWebView();
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
    
    if (mounted) {
      _showSnackBar('⏰ Waktu pembayaran habis', Colors.red);
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('🌐 Page started: $url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            print('✅ Page finished: $url');
            if (mounted) setState(() => _isLoading = false);
            
            if (url.contains('sidrive://payment/finish') || 
                url.contains('status_code=200') ||
                url.contains('transaction_status=settlement')) {
              _handlePaymentFinish();
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            
            if (url.startsWith('sidrive://')) {
              _handlePaymentFinish();
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentFinish() {
    print('💰 Payment finished, checking status...');
    
    if (_isCheckingStatus) return;
    
    setState(() => _isCheckingStatus = true);
    _showStatusCheckingDialog();
    _startPollingPaymentStatus();
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
      
      final status = await _topUpService.checkPaymentStatus(widget.orderId);
      
      print('💳 Transaction status: $status');

      if (status == 'capture' || status == 'settlement') {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        
        // Process top up
        final success = await _topUpService.processTopUpSuccess(
          orderId: widget.orderId,
          userId: widget.userId,
          amount: widget.amount,
          userRole: widget.userRole,
        );

        if (!mounted) return;
        
        if (success) {
          Navigator.of(context, rootNavigator: true).pop(); // Close dialog
          
          _showSnackBar(
            '✅ Top up berhasil! Saldo bertambah ${CurrencyFormatter.format(widget.amount)}',
            Colors.green,
          );
          
          widget.onSuccess(widget.amount);
          
          await Future.delayed(Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context); // Back to previous screen
          }
        } else {
          Navigator.of(context, rootNavigator: true).pop();
          _showSnackBar('❌ Gagal memproses top up', Colors.red);
        }
        
      } else if (status == 'cancel' || status == 'deny' || status == 'expire') {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        
        if (!mounted) return;
        
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('❌ Pembayaran gagal atau dibatalkan', Colors.red);
        
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      }
      
    } catch (e) {
      print('❌ Error checking payment: $e');
    }
  }

  void _showStatusCheckingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Memeriksa Status Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Pembayaran?'),
        content: Text('Top up akan dibatalkan jika pembayaran tidak diselesaikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Lanjut Bayar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      _pollingTimer?.cancel();
      _timeoutTimer?.cancel();
      Navigator.pop(context);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleCancel();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pembayaran Top Up', style: TextStyle(fontSize: 16)),
              Text(
                CurrencyFormatter.format(widget.amount),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: _handleCancel,
          ),
          actions: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _remainingSeconds < 60 ? Colors.red : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
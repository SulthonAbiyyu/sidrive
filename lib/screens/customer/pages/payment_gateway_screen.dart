import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sidrive/screens/customer/pages/payment_status_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final Map<String, dynamic> pesananData;

  const PaymentGatewayScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
    required this.pesananData,
  }) : super(key: key);

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('🌐 Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            print('✅ Page finished loading: $url');
            setState(() => _isLoading = false);
            
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
    print('💰 Payment finished, navigating to status screen...');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStatusScreen(
          orderId: widget.orderId,
          pesananData: widget.pesananData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldCancel = await _showCancelDialog();
        if (shouldCancel == true) {
          await _cancelOrder();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pembayaran'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              final shouldCancel = await _showCancelDialog();
              if (shouldCancel == true) {
                await _cancelOrder();
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
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

  Future<bool?> _showCancelDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Pembayaran?'),
        content: Text('Pesanan akan dibatalkan jika pembayaran tidak diselesaikan.'),
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
  }

  Future<void> _cancelOrder() async {
    try {
      print('🚫 Cancelling order: ${widget.orderId}');
      
      await Supabase.instance.client.from('pesanan').update({
        'status_pesanan': 'dibatalkan',
        'payment_status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', widget.orderId);
      
      print('✅ Order cancelled');
    } catch (e) {
      print('❌ Error cancelling order: $e');
    }
  }
}
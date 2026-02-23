import 'package:flutter/material.dart';
import 'package:sidrive/services/cancel_order_service.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CancelOrderDialog {
  /// Show customer cancel dialog with compensation info
  static Future<bool?> showCustomerCancelDialog({
    required BuildContext context,
    required String idPesanan,
    required String customerId,
  }) async {
    final cancelService = CancelOrderService();

    // 1. Check if can cancel
    final canCancelData = await cancelService.canCustomerCancel(idPesanan);
    final canCancel = canCancelData['canCancel'] as bool;

    if (!canCancel) {
      final waitTime = canCancelData['waitTime'] as int?;
      return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(child: Text('Tidak Dapat Membatalkan')),
            ],
          ),
          content: Text(
            'Driver sedang menuju lokasi Anda. Tunggu ${waitTime ?? 5} menit atau hubungi driver.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    // 2. Calculate compensation
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => FutureBuilder<Map<String, dynamic>>(
        future: _fetchCompensationData(idPesanan, cancelService),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menghitung kompensasi...'),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final kompensasi = (data['kompensasi'] ?? 0.0) as double;
          final jarakTempuh = (data['jarak_tempuh'] ?? 0.0) as double;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text('Batalkan Pesanan?')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kompensasi > 0) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Kompensasi untuk Driver',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Driver sudah menempuh ${jarakTempuh.toStringAsFixed(2)} km',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kompensasi: ${CurrencyFormatter.format(kompensasi)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ] else ...[
                  Text(
                    'Driver belum bergerak, tidak ada kompensasi.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                ],
                Text(
                  'Apakah Anda yakin ingin membatalkan pesanan ini?',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext, null); // Close confirmation dialog
                  
                  // ✅ FIX: Show loading dengan proper error handling
                  if (!context.mounted) return;
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => WillPopScope(
                      onWillPop: () async => false,
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Memproses pembatalan...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  try {
                    final result = await cancelService.customerCancelOrder(
                      idPesanan: idPesanan,
                      customerId: customerId,
                    );

                    // ✅ FIX: Tutup loading dialog dulu
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                    }

                    // Baru show result
                    if (context.mounted) {
                      if (result['success'] == true) {
                        _showSuccessDialog(context, result['message']);
                      } else {
                        _showErrorDialog(context, result['message']);
                      }
                    }
                  } catch (e) {
                    // ✅ FIX: Handle error dengan benar
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      _showErrorDialog(context, 'Terjadi kesalahan: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Ya, Batalkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show driver cancel dialog
  static Future<bool?> showDriverCancelDialog({
    required BuildContext context,
    required String idPesanan,
    required String driverId,
  }) async {
    final cancelService = CancelOrderService();

    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => FutureBuilder<double>(
        future: _calculateDriverCancelFee(idPesanan),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menghitung biaya...'),
                ],
              ),
            );
          }

          final biayaAdmin = snapshot.data ?? 0.0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red),
                SizedBox(width: 12),
                Expanded(child: Text('Batalkan Pesanan?')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Biaya Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Biaya admin 20%',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(biayaAdmin),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Biaya ini akan dipotong dari saldo Anda. Lanjutkan?',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext, null);
                  _showLoadingDialog(context);

                  final result = await cancelService.driverCancelOrder(
                    idPesanan: idPesanan,
                    driverId: driverId,
                    cancelReason: 'Driver membatalkan pesanan',
                  );

                  Navigator.pop(context);

                  if (result['success'] == true) {
                    _showSuccessDialog(context, result['message']);
                  } else {
                    _showErrorDialog(context, result['message']);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Ya, Batalkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> _fetchCompensationData(
    String idPesanan,
    CancelOrderService service,
  ) async {
    // Get driver ID first
    final supabase = Supabase.instance.client;
    final pengiriman = await supabase
        .from('pengiriman')
        .select('id_driver')
        .eq('id_pesanan', idPesanan)
        .maybeSingle();

    if (pengiriman == null) {
      return {'kompensasi': 0.0, 'jarak_tempuh': 0.0};
    }

    return await service.calculateCustomerCancelCompensation(
      idPesanan: idPesanan,
      idDriver: pengiriman['id_driver'],
    );
  }

  static Future<double> _calculateDriverCancelFee(String idPesanan) async {
    final supabase = Supabase.instance.client;
    final pesanan = await supabase
        .from('pesanan')
        .select('total_harga')
        .eq('id_pesanan', idPesanan)
        .single();

    final totalHarga = (pesanan['total_harga'] ?? 0).toDouble();
    return ((totalHarga * 0.20) / 500).round() * 500.0;
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memproses...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Berhasil'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
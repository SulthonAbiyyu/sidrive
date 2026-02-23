import 'package:supabase_flutter/supabase_flutter.dart';

class WalletTopUpService {
  final _supabase = Supabase.instance.client;

  /// Create Midtrans transaction untuk top up wallet (CUSTOMER, DRIVER, UMKM)
  Future<Map<String, dynamic>> createTopUpTransaction({
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required double amount,
    required String userRole, // 'customer', 'driver', 'umkm'
  }) async {
    try {
      // ✅ FIX: Order ID lebih pendek (max 50 char untuk Midtrans)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userHash = userId.hashCode.abs().toString().substring(0, 6);
      final orderId = 'TOP${userRole[0].toUpperCase()}$timestamp$userHash';
      
      print('💰 Creating top up transaction: $orderId - Rp${amount.toStringAsFixed(0)}');

      // ✅ FIX: Call edge function KHUSUS TOP UP
      final response = await _supabase.functions.invoke(
        'create-topup-payment',
        body: {
          'orderId': orderId,
          'grossAmount': amount.toInt(),
          'customerDetails': {
            'first_name': userName,
            'email': userEmail,
            'phone': userPhone,
          },
          'itemDetails': [
            {
              'id': 'WALLET_TOPUP_${userRole.toUpperCase()}',
              'price': amount.toInt(),
              'quantity': 1,
              'name': 'Top Up Wallet SiDrive ($userRole)',
            }
          ],
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create transaction: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      
      print('✅ Midtrans token created: ${data['token']}');

      // ✅ FIX: Save ke database - SESUAI STRUKTUR TABEL
      await _supabase.from('transaksi_keuangan').insert({
        'id_user': userId,
        'jenis_transaksi': 'topup_pending', // ✅ Gabung kategori ke jenis_transaksi
        'jumlah': amount,
        'deskripsi': 'Top up wallet ($userRole) - Order ID: $orderId', // ✅ Pakai 'deskripsi' bukan 'keterangan'
        'metadata': {
          'order_id': orderId,
          'midtrans_token': data['token'],
          'status': 'pending',
          'role': userRole,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Transaction saved to database');

      return {
        'order_id': orderId,
        'token': data['token'],
        'redirect_url': data['redirect_url'],
      };

    } catch (e) {
      print('❌ Error create top up transaction: $e');
      throw Exception('Gagal membuat transaksi: ${e.toString()}');
    }
  }

  /// Process top up after payment success (UNIFIED - ALL ROLES)
  Future<bool> processTopUpSuccess({
    required String orderId,
    required String userId,
    required double amount,
    required String userRole, // 'customer', 'driver', 'umkm'
  }) async {
    try {
      print('✅ Processing top up success: $orderId for $userRole');

      // ✅ UNIFIED: Semua role pakai users.saldo_wallet
      final user = await _supabase
          .from('users')
          .select('saldo_wallet, total_topup')
          .eq('id_user', userId)
          .single();

      final oldBalance = (user['saldo_wallet'] ?? 0).toDouble();
      final oldTotalTopup = (user['total_topup'] ?? 0).toDouble();
      final newBalance = oldBalance + amount;
      final newTotalTopup = oldTotalTopup + amount;

      await _supabase.from('users').update({
        'saldo_wallet': newBalance,
        'total_topup': newTotalTopup,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_user', userId);

      // Record transaction
      await _supabase.from('transaksi_keuangan').insert({
        'id_user': userId,
        'jenis_transaksi': 'topup',
        'jumlah': amount,
        'saldo_sebelum': oldBalance,
        'saldo_sesudah': newBalance,
        'deskripsi': 'Top up wallet berhasil ($userRole) - Order ID: $orderId',
        'metadata': {
          'order_id': orderId,
          'status': 'success',
          'role': userRole,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Top up processed: Rp${amount.toStringAsFixed(0)}');
      print('📊 Old balance: Rp${oldBalance.toStringAsFixed(0)}');
      print('📊 New balance: Rp${newBalance.toStringAsFixed(0)}');
      return true;

    } catch (e) {
      print('❌ Error process top up: $e');
      return false;
    }
  }

  /// Check payment status
  Future<String> checkPaymentStatus(String orderId) async {
    try {
      final response = await _supabase.functions.invoke(
        'check-payment-status',
        body: {'orderId': orderId},
      );

      if (response.status != 200) {
        return 'pending';
      }

      final data = response.data as Map<String, dynamic>;
      final status = data['transaction_status'] as String;

      return status;
    } catch (e) {
      print('❌ Error check payment status: $e');
      return 'pending';
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service khusus untuk Driver Settlement ke Admin Wallet
class WalletSettlementService {
  final _supabase = Supabase.instance.client;

  /// Create Midtrans transaction untuk settlement (Driver → Admin Wallet)
  Future<Map<String, dynamic>> createSettlementTransaction({
    required String driverId,
    required String driverName,
    required String driverEmail,
    required String driverPhone,
    required double amount,
  }) async {
    try {
      // ✅ Order ID khusus settlement (awalan SETL bukan TOP)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final driverHash = driverId.hashCode.abs().toString().substring(0, 6);
      final orderId = 'SETL$timestamp$driverHash';
      
      print('💰 Creating SETTLEMENT transaction: $orderId - Rp${amount.toStringAsFixed(0)}');
      print('   Driver: $driverId → Admin Wallet');

      // ✅ Call edge function KHUSUS SETTLEMENT
      final response = await _supabase.functions.invoke(
        'create-settlement-payment',
        body: {
          'orderId': orderId,
          'grossAmount': amount.toInt(),
          'driverId': driverId,
          'customerDetails': {
            'first_name': driverName,
            'email': driverEmail,
            'phone': driverPhone,
          },
          'itemDetails': [
            {
              'id': 'DRIVER_SETTLEMENT',
              'price': amount.toInt(),
              'quantity': 1,
              'name': 'Settlement Cash Driver ke Admin',
            }
          ],
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create settlement transaction: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      
      print('✅ Midtrans settlement token created: ${data['token']}');

      return {
        'order_id': orderId,
        'token': data['token'],
        'redirect_url': data['redirect_url'],
      };

    } catch (e) {
      print('❌ Error create settlement transaction: $e');
      throw Exception('Gagal membuat transaksi settlement: ${e.toString()}');
    }
  }

  

  /// Get driver cash pending info
  Future<Map<String, dynamic>> getDriverCashPending(String driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('total_cash_pending, jumlah_order_belum_setor')
          .eq('id_driver', driverId)
          .single();

      return {
        'cash_pending': (response['total_cash_pending'] ?? 0).toDouble(),
        'order_count': response['jumlah_order_belum_setor'] ?? 0,
      };
    } catch (e) {
      print('❌ Error get driver cash pending: $e');
      return {
        'cash_pending': 0.0,
        'order_count': 0,
      };
    }
  }

  /// Get admin wallet balance (shared wallet untuk semua admin)
  Future<double> getAdminWalletBalance() async {
    try {
      final response = await _supabase.rpc('get_admin_wallet');
      
      if (response == null || response.isEmpty) {
        return 0.0;
      }

      final data = response[0] as Map<String, dynamic>;
      return (data['saldo_wallet'] ?? 0).toDouble();
    } catch (e) {
      print('❌ Error get admin wallet: $e');
      return 0.0;
    }
  }

  /// Get pending settlements for admin page
  Future<List<Map<String, dynamic>>> getPendingSettlements() async {
    try {
      final response = await _supabase
          .from('view_pending_settlements_with_driver')
          .select()
          .order('tanggal_pengajuan', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error get pending settlements: $e');
      return [];
    }
  }

  /// Admin approve settlement
  Future<Map<String, dynamic>> approveSettlement({
    required String settlementId,
    required String adminId,
    String? notes,
  }) async {
    try {
      print('✅ Admin approving settlement: $settlementId');
      
      final result = await _supabase.rpc('approve_cash_settlement', params: {
        'p_settlement_id': settlementId,
        'p_admin_id': adminId,
        'p_catatan': notes,
      });

      if (result == null) {
        return {'success': false, 'message': 'RPC returned null'};
      }

      return result as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error approve settlement: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Admin reject settlement
  Future<Map<String, dynamic>> rejectSettlement({
    required String settlementId,
    required String adminId,
    required String reason,
  }) async {
    try {
      print('🚫 Admin rejecting settlement: $settlementId');
      
      final result = await _supabase.rpc('reject_cash_settlement', params: {
        'p_settlement_id': settlementId,
        'p_admin_id': adminId,
        'p_catatan': reason,
      });

      if (result == null) {
        return {'success': false, 'message': 'RPC returned null'};
      }

      return result as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error reject settlement: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
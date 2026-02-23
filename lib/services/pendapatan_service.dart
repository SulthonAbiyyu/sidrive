// ============================================================================
// PENDAPATAN SERVICE - Handle semua logic pendapatan driver
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class PendapatanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getPendapatanByPeriode({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('📊 Fetching pendapatan untuk driver: $driverId');
      print('📊 Periode: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}');

      final response = await _supabase
          .from('pengiriman')
          .select('*, pesanan(*)')
          .eq('id_driver', driverId)
          .eq('status_pengiriman', 'selesai')
          .gte('waktu_selesai', startDate.toIso8601String())
          .lt('waktu_selesai', endDate.toIso8601String());

      print('📊 Response: ${response.length} pesanan ditemukan');

      if (response.isEmpty) {
        return {
          'total_pendapatan': 0.0,
          'total_pesanan': 0,
          'total_jarak': 0.0,
          'total_fee_admin': 0.0,
          'list_pesanan': [],
        };
      }

      double totalPendapatan = 0;
      double totalJarak = 0;
      double totalFeeAdmin = 0;
      int totalPesanan = response.length;

      for (var item in response) {
        final pesanan = item['pesanan'];
        if (pesanan != null) {
          final ongkir = (pesanan['ongkir'] ?? 0);
          final jarak = (pesanan['jarak_km'] ?? 0);
          final feeAdmin = (pesanan['fee_admin'] ?? 0);
          
          totalPendapatan += ongkir is int ? ongkir.toDouble() : (ongkir as double);
          totalJarak += jarak is int ? jarak.toDouble() : (jarak as double);
          totalFeeAdmin += feeAdmin is int ? feeAdmin.toDouble() : (feeAdmin as double);
        }
      }

      print('✅ Total Pendapatan: Rp ${totalPendapatan.toStringAsFixed(0)}');
      print('✅ Total Pesanan: $totalPesanan');
      print('✅ Total Jarak: ${totalJarak.toStringAsFixed(1)} km');

      return {
        'total_pendapatan': totalPendapatan,
        'total_pesanan': totalPesanan,
        'total_jarak': totalJarak,
        'total_fee_admin': totalFeeAdmin,
        'list_pesanan': response,
      };
    } catch (e, stackTrace) {
      print('❌ Error get pendapatan: $e');
      print('Stack: $stackTrace');
      throw Exception('Gagal mengambil data pendapatan: $e');
    }
  }

  Future<Map<String, dynamic>> getPendapatanHariIni(String driverId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getPendapatanByPeriode(
      driverId: driverId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  Future<Map<String, dynamic>> getPendapatanMingguIni(String driverId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getPendapatanByPeriode(
      driverId: driverId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, dynamic>> getPendapatanBulanIni(String driverId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getPendapatanByPeriode(
      driverId: driverId,
      startDate: startOfMonth,
      endDate: endDate,
    );
  }

  Future<List<Map<String, dynamic>>> getRiwayatPesananSelesai({
    required String driverId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('pengiriman')
          .select('*, pesanan(*)')
          .eq('id_driver', driverId)
          .eq('status_pengiriman', 'selesai')
          .order('waktu_selesai', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error get riwayat: $e');
      return [];
    }
  }

  // ==================== CREDIT EARNINGS TO WALLET ====================

  /// Otomatis credit pendapatan ke wallet driver saat order selesai
  Future<bool> creditEarningsToWallet({
    required String driverId,
    required String orderId,
    required double ongkirAmount,
    required String paymentMethod,
  }) async {
    try {
      // ✅ HANYA untuk transfer/wallet payment
      // Cash payment tidak langsung masuk wallet
      if (paymentMethod == 'cash') {
        print('ℹ️ Cash payment - earnings tidak langsung masuk wallet');
        return true; // Not an error, just skip
      }

      print('💰 ========== CREDIT EARNINGS TO WALLET ==========');
      print('💰 Driver: $driverId');
      print('💰 Order: $orderId');
      print('💰 Amount: Rp${ongkirAmount.toStringAsFixed(0)}');
      print('💰 Payment: $paymentMethod');

      // Call RPC function
      final result = await _supabase.rpc('credit_driver_earnings', params: {
        'p_driver_id': driverId,
        'p_order_id': orderId,
        'p_amount': ongkirAmount,
        'p_description': 'Pendapatan dari order #${orderId.substring(0, 8)}',
      });

      if (result == null) {
        print('❌ RPC returned null');
        return false;
      }

      final resultMap = result as Map<String, dynamic>;

      if (resultMap['success'] == true) {
        print('✅ Earnings credited successfully!');
        print('📊 Old balance: Rp${resultMap['old_balance']}');
        print('📊 New balance: Rp${resultMap['new_balance']}');
        return true;
      } else {
        print('⚠️ Failed: ${resultMap['message']}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error credit earnings: $e');
      print('Stack: $stackTrace');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDriverSettlementInfo(String driverId) async {
    try {
      print('📊 Fetching settlement info for driver: $driverId');
      
      // 1. Get driver cash info
      final driver = await _supabase
          .from('drivers')
          .select('jumlah_order_belum_setor, total_cash_pending')
          .eq('id_driver', driverId)
          .single();
      
      print('   Order count: ${driver['jumlah_order_belum_setor']}');
      print('   Cash pending: ${driver['total_cash_pending']}');
      
      // 2. Get settlement history
      final settlements = await _supabase
          .from('cash_settlements')
          .select()
          .eq('id_driver', driverId)
          .order('tanggal_pengajuan', ascending: false)
          .limit(5);
      
      print('   Settlements found: ${settlements.length}');
      
      final orderCount = driver['jumlah_order_belum_setor'] ?? 0;
      
      return {
        'cash_pending': (driver['total_cash_pending'] ?? 0).toDouble(),
        'order_count': orderCount,
        'can_withdraw': orderCount < 5,
        'settlements': List<Map<String, dynamic>>.from(settlements),
      };
      
    } catch (e) {
      print('❌ Error get settlement info: $e');
      // Return default values jika error
      return {
        'cash_pending': 0.0,
        'order_count': 0,
        'can_withdraw': true,
        'settlements': [],
      };
    }
  }
}
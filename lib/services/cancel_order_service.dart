import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show cos, sqrt, asin, sin;

class CancelOrderService {
  final _supabase = Supabase.instance.client;
  final _walletService = WalletService();

  // ==================== CUSTOMER CANCEL (POIN 3 & 4) ====================

  /// Calculate compensation based on driver distance traveled
  Future<Map<String, dynamic>> calculateCustomerCancelCompensation({
    required String idPesanan,
    required String idDriver,
  }) async {
    try {
      // 1. Get order details
      final pesanan = await _supabase
          .from('pesanan')
          .select('*, pengiriman!inner(id_driver, last_driver_location)')
          .eq('id_pesanan', idPesanan)
          .single();

      // 2. Get driver's current location from pengiriman
      final pengiriman = pesanan['pengiriman'];
      final lastLocationWKT = pengiriman['last_driver_location'] as String?;

      if (lastLocationWKT == null) {
        return {
          'kompensasi': 0.0,
          'jarak_tempuh': 0.0,
          'alasan': 'Driver belum bergerak',
        };
      }

      // 3. Parse driver location
      final coords = _parsePointWKT(lastLocationWKT);
      if (coords == null) {
        return {
          'kompensasi': 0.0,
          'jarak_tempuh': 0.0,
          'alasan': 'Gagal parse lokasi driver',
        };
      }

      // 4. Get pickup location
      final lokasiJemputWKT = pesanan['lokasi_asal'] as String?;
      if (lokasiJemputWKT == null) {
        return {
          'kompensasi': 0.0,
          'jarak_tempuh': 0.0,
          'alasan': 'Lokasi jemput tidak ditemukan',
        };
      }

      final pickupCoords = _parsePointWKT(lokasiJemputWKT);
      if (pickupCoords == null) {
        return {
          'kompensasi': 0.0,
          'jarak_tempuh': 0.0,
          'alasan': 'Gagal parse lokasi jemput',
        };
      }

      // 5. Calculate distance
      final jarakKm = _calculateDistance(
        coords['lat']!,
        coords['lng']!,
        pickupCoords['lat']!,
        pickupCoords['lng']!,
      );

      print('📍 Jarak driver tempuh: ${jarakKm.toStringAsFixed(2)} km');

      // ✅ 6. PERUBAHAN: Kompensasi mulai dari 2km
      if (jarakKm < 2.0) {
        print('✅ Jarak < 2km, tidak ada kompensasi');
        return {
          'kompensasi': 0.0,
          'jarak_tempuh': jarakKm,
          'alasan': 'Driver baru menempuh ${jarakKm.toStringAsFixed(2)} km (< 2km)',
        };
      }

      // 7. ✅ FIX: Calculate compensation dari ONGKIR, bukan total_harga
      final ongkir = (pesanan['ongkir'] ?? 0).toDouble();
      final feeAdmin = _roundToNearest500(ongkir * 0.20); // 20% dari ongkir
      final totalKompensasi = _roundToNearest500(ongkir + feeAdmin); // ongkir + fee admin

      return {
        'kompensasi_driver': ongkir, // ✅ Driver dapat ongkir penuh
        'kompensasi_admin': feeAdmin, // ✅ Admin dapat fee 20%
        'total_kompensasi': totalKompensasi, // ✅ Total yang dipotong dari customer
        'jarak_tempuh': jarakKm,
        'alasan': 'Driver sudah menempuh ${jarakKm.toStringAsFixed(2)} km (≥ 2km)',
      };
    } catch (e) {
      print('❌ Error calculate compensation: $e');
      return {
        'kompensasi': 0.0,
        'jarak_tempuh': 0.0,
        'alasan': 'Error: $e',
      };
    }
  }

  /// Customer cancel order with compensation
  Future<Map<String, dynamic>> customerCancelOrder({
    required String idPesanan,
    required String customerId,
  }) async {
    try {
      print('🚫 ========== CUSTOMER CANCEL ORDER ==========');

      // 1. Get pengiriman data
      final pengiriman = await _supabase
          .from('pengiriman')
          .select('id_driver, status_pengiriman, last_movement_time')
          .eq('id_pesanan', idPesanan)
          .maybeSingle();

      if (pengiriman == null) {
        // Belum ada driver, cancel tanpa kompensasi
        await _supabase.from('pesanan').update({
          'status_pesanan': 'dibatalkan',
          'alasan_cancel': 'Customer cancel (belum ada driver)',
          'waktu_cancel': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_pesanan', idPesanan);

        return {
          'success': true,
          'kompensasi': 0.0,
          'message': 'Pesanan dibatalkan tanpa kompensasi',
        };
      }

      final idDriver = pengiriman['id_driver'] as String?;
      if (idDriver == null) {
        return {
          'success': false,
          'message': 'Driver tidak ditemukan',
        };
      }

      // 2. Check driver movement (POIN 4)
      final lastMovementTime = pengiriman['last_movement_time'] != null
          ? DateTime.parse(pengiriman['last_movement_time'])
          : null;

      if (lastMovementTime != null) {
        final minutesSinceLastMove = DateTime.now().difference(lastMovementTime).inMinutes;
        
        if (minutesSinceLastMove < 5) {
          // Driver masih bergerak dalam 5 menit terakhir, tidak bisa cancel
          return {
            'success': false,
            'canCancel': false,
            'message': 'Tidak dapat membatalkan. Driver sedang menuju lokasi Anda.',
            'waitTime': 5 - minutesSinceLastMove,
          };
        }
      }

      // 3. Calculate compensation
      final compensationData = await calculateCustomerCancelCompensation(
        idPesanan: idPesanan,
        idDriver: idDriver,
      );

      final kompensasi = compensationData['kompensasi'] as double;
      final jarakTempuh = compensationData['jarak_tempuh'] as double;


      // ✅ FIX: Pakai kompensasi_driver dan kompensasi_admin yang terpisah
      final kompensasiDriver = compensationData['kompensasi_driver'] as double? ?? 0.0;
      final kompensasiAdmin = compensationData['kompensasi_admin'] as double? ?? 0.0;
      final totalKompensasi = compensationData['total_kompensasi'] as double? ?? 0.0;

      if (totalKompensasi > 0) {
        print('💰 Processing compensation:');
        print('   Driver: Rp${kompensasiDriver.toStringAsFixed(0)}');
        print('   Admin: Rp${kompensasiAdmin.toStringAsFixed(0)}');
        print('   Total: Rp${totalKompensasi.toStringAsFixed(0)}');
        
        final result = await _supabase.rpc('process_customer_cancel_compensation', params: {
          'p_customer_id': customerId,
          'p_driver_id': idDriver,
          'p_ongkir': kompensasiDriver,
          'p_fee_admin': kompensasiAdmin,
          'p_order_id': idPesanan,
        });

        if (result == null || result['success'] != true) {
          return {
            'success': false,
            'message': result?['message'] ?? 'Gagal transfer kompensasi',
          };
        }
        
        print('✅ Compensation processed successfully');
      }

      // 6. Update pesanan & pengiriman
      await _supabase.from('pesanan').update({
        'status_pesanan': 'dibatalkan',
        'alasan_cancel': 'Customer cancel - ${compensationData['alasan']}',
        'kompensasi_driver': kompensasi,
        'jarak_driver_tempuh_km': jarakTempuh,
        'waktu_cancel': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);

      await _supabase.from('pengiriman').update({
        'status_pengiriman': 'dibatalkan',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);

      print('✅ Customer cancel success, kompensasi: Rp${kompensasi.toStringAsFixed(0)}');

      return {
        'success': true,
        'kompensasi_driver': kompensasiDriver,
        'kompensasi_admin': kompensasiAdmin,
        'total_kompensasi': totalKompensasi,
        'jarak_tempuh': jarakTempuh,
        'message': totalKompensasi > 0
            ? 'Pesanan dibatalkan. Kompensasi Rp${totalKompensasi.toStringAsFixed(0)} dipotong dari saldo'
            : 'Pesanan dibatalkan tanpa kompensasi',
      };
    } catch (e) {
      print('❌ Error customer cancel: $e');
      return {
        'success': false,
        'message': 'Gagal membatalkan: $e',
      };
    }
  }

  /// Check if customer can cancel (POIN 4) - FIXED VERSION
  Future<Map<String, dynamic>> canCustomerCancel(String idPesanan) async {
    try {
      final pengiriman = await _supabase
          .from('pengiriman')
          .select('last_movement_time, status_pengiriman')
          .eq('id_pesanan', idPesanan)
          .maybeSingle();

      if (pengiriman == null) {
        return {'canCancel': true, 'reason': 'Belum ada driver'};
      }

      final statusPengiriman = pengiriman['status_pengiriman'] as String?;
      
      // ✅ FIX: Jika status bukan aktif, bisa cancel
      if (statusPengiriman == null || 
          !['menuju_pickup', 'pickup_selesai', 'customer_naik', 'perjalanan'].contains(statusPengiriman)) {
        return {'canCancel': true, 'reason': 'Status pengiriman tidak aktif'};
      }

      final lastMovementTime = pengiriman['last_movement_time'] != null
          ? DateTime.parse(pengiriman['last_movement_time'])
          : null;

      if (lastMovementTime == null) {
        return {'canCancel': true, 'reason': 'Driver belum bergerak'};
      }

      final minutesSinceLastMove = DateTime.now().difference(lastMovementTime).inMinutes;

      if (minutesSinceLastMove >= 5) {
        return {
          'canCancel': true,
          'reason': 'Driver tidak bergerak selama $minutesSinceLastMove menit',
        };
      }

      return {
        'canCancel': false,
        'reason': 'Driver sedang menuju lokasi',
        'waitTime': 5 - minutesSinceLastMove,
      };
    } catch (e) {
      print('❌ Error check can cancel: $e');
      return {'canCancel': false, 'reason': 'Error: $e'};
    }
  }

  // ==================== DRIVER CANCEL (POIN 8) ====================

  /// Driver cancel order with admin fee
  Future<Map<String, dynamic>> driverCancelOrder({
    required String idPesanan,
    required String driverId,
    required String cancelReason, // ✅ TAMBAH: Alasan pembatalan
  }) async {
    try {
      print('🚫 ========== DRIVER CANCEL ORDER ==========');

      // 1. Calculate admin fee (20% dari total harga)
      final pesanan = await _supabase
          .from('pesanan')
          .select('total_harga, id_user')
          .eq('id_pesanan', idPesanan)
          .single();

      final totalHarga = (pesanan['total_harga'] ?? 0).toDouble();
      final biayaAdmin = _roundToNearest500(totalHarga * 0.20);
      final customerId = pesanan['id_user'];

      // 2. Deduct driver balance menggunakan method baru
      final deductResult = await _walletService.deductDriverCancelFee(
        driverId: driverId,
        amount: biayaAdmin,
        orderId: idPesanan,
        reason: cancelReason,
      );

      if (deductResult['success'] != true) {
        return {
          'success': false,
          'message': deductResult['message'] ?? 
                    'Saldo tidak cukup untuk biaya cancel. Butuh Rp${biayaAdmin.toStringAsFixed(0)}',
          'requiredAmount': biayaAdmin,
        };
      }

      try {
        await _supabase.rpc('add_driver_cancel_fee_to_admin', params: {
          'p_fee_amount': biayaAdmin,
          'p_order_id': idPesanan,
        });
        print('✅ Driver cancel fee added to admin wallet');
      } catch (e) {
        print('⚠️ Warning: Failed to add fee to admin wallet: $e');
      }

      // 3. Update pesanan & pengiriman
      await _supabase.from('pesanan').update({
        'status_pesanan': 'dibatalkan',
        'alasan_cancel': 'Driver cancel: $cancelReason',
        'biaya_cancel_driver': biayaAdmin,
        'waktu_cancel': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);

      await _supabase.from('pengiriman').update({
        'status_pengiriman': 'dibatalkan',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);

      // 4. ✅ KIRIM NOTIFIKASI KE CUSTOMER dengan alasan
      await _supabase.from('notifikasi').insert({
        'id_user': customerId,
        'judul': 'Pesanan Dibatalkan Driver',
        'pesan': 'Driver membatalkan pesanan Anda.\nAlasan: $cancelReason\n\nSilakan cari driver lain.',
        'jenis': 'pesanan',
        'status': 'unread',
        'data_tambahan': {
          'id_pesanan': idPesanan,
          'alasan': cancelReason,
          'biaya_admin': biayaAdmin,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Driver cancel success, biaya admin: Rp${biayaAdmin.toStringAsFixed(0)}');
      print('✅ Notification sent to customer');

      return {
        'success': true,
        'biayaAdmin': biayaAdmin,
        'message': 'Pesanan dibatalkan. Biaya admin Rp${biayaAdmin.toStringAsFixed(0)} dipotong dari saldo',
      };
    } catch (e) {
      print('❌ Error driver cancel: $e');
      return {
        'success': false,
        'message': 'Gagal membatalkan: $e',
      };
    }
  }

  // ==================== AUTO CANCEL (POIN 9) ====================

  /// Auto cancel if driver GPS not moving for 10 minutes
  Future<void> autoCheckAndCancelStuckOrders() async {
    try {
      print('🔍 Checking stuck orders...');

      final tenMinutesAgo = DateTime.now().subtract(Duration(minutes: 10));

      final stuckOrders = await _supabase
          .from('pengiriman')
          .select('id_pesanan, id_driver, last_movement_time, status_pengiriman')
          .inFilter('status_pengiriman', ['menuju_pickup', 'pickup_selesai'])
          .lt('last_movement_time', tenMinutesAgo.toIso8601String());

      for (var order in stuckOrders) {
        final idPesanan = order['id_pesanan'];
        final idDriver = order['id_driver'];

        print('⚠️ Auto-canceling stuck order: $idPesanan');

        await driverCancelOrder(
          idPesanan: idPesanan, 
          driverId: idDriver,
          cancelReason: 'Auto-cancel: Driver tidak bergerak selama 10 menit',
        );
      }

      print('✅ Auto-cancel check complete');
    } catch (e) {
      print('❌ Error auto-cancel check: $e');
    }
  }

  // ==================== HELPER FUNCTIONS ====================

  Map<String, double>? _parsePointWKT(String wkt) {
    try {
      // Format: POINT(lng lat)
      final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
      final match = regex.firstMatch(wkt);

      if (match != null) {
        return {
          'lng': double.parse(match.group(1)!),
          'lat': double.parse(match.group(2)!),
        };
      }
    } catch (e) {
      print('❌ Error parsing WKT: $e');
    }
    return null;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _toRad(double degree) => degree * pi / 180;

  double _roundToNearest500(double value) => (value / 500).round() * 500.0;

  // ==================== TRANSFER PAYMENT REFUND REQUEST ====================
  
  /// Request refund untuk transfer payment (perlu approval admin)
  Future<Map<String, dynamic>> requestTransferRefund({
    required String idPesanan,
    required String customerId,
    required double amount,
    required String reason,
  }) async {
    try {
      print('💳 Requesting transfer refund...');
      
      // Insert ke tabel refund_requests (buat tabel baru atau gunakan existing)
      await _supabase.from('pesanan').update({
        'refund_status': 'requested',
        'refund_requested_at': DateTime.now().toIso8601String(),
        'refund_reason': reason,
        'refund_amount': amount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      // ✅ BROADCAST KE SEMUA ADMIN
      final allAdmins = await _supabase
          .from('admins')
          .select('id_user')
          .eq('is_active', true);
      
      // Kirim notifikasi ke semua admin
      for (var admin in allAdmins) {
        await _supabase.from('notifikasi').insert({
          'id_user': admin['id_user'],
          'judul': 'Request Refund Transfer',
          'pesan': 'Customer request refund order $idPesanan sejumlah Rp${amount.toStringAsFixed(0)}',
          'jenis': 'refund',
          'status': 'unread',
          'data_tambahan': {
            'id_pesanan': idPesanan,
            'id_customer': customerId,
            'amount': amount,
            'reason': reason,
          },
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      print('✅ Transfer refund requested to ${allAdmins.length} admins');
      
      return {
        'success': true,
        'message': 'Request refund telah dikirim. Tim kami akan memproses dalam 1-3 hari kerja.',
      };
      
    } catch (e) {
      print('❌ Error request transfer refund: $e');
      return {
        'success': false,
        'message': 'Gagal request refund: $e',
      };
    }
  }
}
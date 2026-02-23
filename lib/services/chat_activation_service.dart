// ============================================================================
// CHAT ACTIVATION SERVICE - FIXED (2KM)
// Chat aktif ketika driver sudah menempuh 2 KM
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' show cos, sqrt, asin, sin, pi;

class ChatActivationService {
  final _supabase = Supabase.instance.client;

  /// Check if chat should be enabled for this order
  /// Returns: {
  ///   'isEnabled': bool,
  ///   'reason': String,
  ///   'driverProgress': double, // jarak tempuh dalam KM
  ///   'requiredProgress': double, // 2.0 KM
  /// }
  Future<Map<String, dynamic>> checkChatEnabled({
    required String idPesanan,
  }) async {
    try {
      print('💬 ========== CHECK CHAT ENABLED ==========');
      print('💬 Order: $idPesanan');

      // 1. Get order and pengiriman data
      final data = await _supabase
          .from('pengiriman')
          .select('''
            last_driver_location,
            initial_driver_location,
            status_pengiriman,
            pesanan!inner(
              lokasi_asal,
              lokasi_tujuan,
              jarak_km,
              status_pesanan,
              jenis
            )
          ''')
          .eq('id_pesanan', idPesanan)
          .single();

      final pesanan = data['pesanan'];
      final statusPengiriman = data['status_pengiriman'] as String?;
      final statusPesanan = pesanan['status_pesanan'] as String?;
      final jenisPesanan = pesanan['jenis'] as String?;

      print('💬 Status pengiriman: $statusPengiriman');
      print('💬 Status pesanan: $statusPesanan');
      print('💬 Jenis pesanan: $jenisPesanan');

      // ✅ UMKM order: langsung aktif, tidak perlu lock 2km
      // Lock 2km hanya untuk pesanan ojek
      if (jenisPesanan == 'umkm') {
        print('💬 UMKM order - chat langsung aktif (no 2km lock)');
        return {
          'isEnabled': true,
          'reason': 'Chat aktif',
          'driverProgress': 0.0,
          'requiredProgress': 0.0,
        };
      }

      // 2. Check if order is active (ojek only from here)
      if (statusPesanan != 'diterima' && statusPesanan != 'proses') {
        return {
          'isEnabled': false,
          'reason': 'Pesanan belum aktif',
          'driverProgress': 0.0,
          'requiredProgress': 2.0,
        };
      }

      // 3. Get driver initial location (saat accept order)
      final initialLocationWKT = data['initial_driver_location'] as String?;
      
      if (initialLocationWKT == null) {
        print('💬 Initial driver location not available yet');
        return {
          'isEnabled': false,
          'reason': 'Menunggu driver memulai perjalanan...',
          'driverProgress': 0.0,
          'requiredProgress': 2.0,
        };
      }

      // 4. Get driver current location
      final currentLocationWKT = data['last_driver_location'] as String?;
      
      if (currentLocationWKT == null) {
        print('💬 Current driver location not available yet');
        return {
          'isEnabled': false,
          'reason': 'Menunggu driver memulai perjalanan...',
          'driverProgress': 0.0,
          'requiredProgress': 2.0,
        };
      }

      // 5. Parse locations
      final initialCoords = _parsePointWKT(initialLocationWKT);
      final currentCoords = _parsePointWKT(currentLocationWKT);
      final pickupCoords = _parsePointWKT(pesanan['lokasi_asal']);

      if (initialCoords == null || currentCoords == null || pickupCoords == null) {
        return {
          'isEnabled': false,
          'reason': 'Gagal mendapatkan lokasi',
          'driverProgress': 0.0,
          'requiredProgress': 2.0,
        };
      }

      // 6. Calculate distances
      // Initial distance: driver start -> pickup
      final initialDistance = _calculateDistance(
        initialCoords['lat']!,
        initialCoords['lng']!,
        pickupCoords['lat']!,
        pickupCoords['lng']!,
      );
      
      // Current distance: driver now -> pickup
      final currentDistance = _calculateDistance(
        currentCoords['lat']!,
        currentCoords['lng']!,
        pickupCoords['lat']!,
        pickupCoords['lng']!,
      );
      
      // Distance traveled: initial - current
      final jarakTempuh = (initialDistance - currentDistance).clamp(0.0, double.infinity);

      print('💬 Initial distance: ${initialDistance.toStringAsFixed(2)} km');
      print('💬 Current distance: ${currentDistance.toStringAsFixed(2)} km');
      print('💬 Jarak tempuh: ${jarakTempuh.toStringAsFixed(2)} km');

      // 7. Check if distance traveled >= 2 KM
      const requiredDistance = 2.0; // 2 KM
      final isEnabled = jarakTempuh >= requiredDistance;

      print('💬 Chat enabled: $isEnabled');

      return {
        'isEnabled': isEnabled,
        'reason': isEnabled 
            ? 'Chat aktif' 
            : 'Chat akan aktif setelah driver menempuh ${requiredDistance.toStringAsFixed(1)} km',
        'driverProgress': jarakTempuh,  // dalam KM
        'requiredProgress': requiredDistance,
        'progressPercent': ((jarakTempuh / requiredDistance) * 100).toInt().clamp(0, 100),
      };

    } catch (e, stackTrace) {
      print('❌ Error check chat enabled: $e');
      print('Stack: $stackTrace');
      
      return {
        'isEnabled': false,
        'reason': 'Error: $e',
        'driverProgress': 0.0,
        'requiredProgress': 2.0,
      };
    }
  }

  /// Save driver's initial location when accepting order
  Future<void> saveDriverInitialLocation({
    required String idPesanan,
    required String driverLocation,
  }) async {
    try {
      await _supabase
          .from('pengiriman')
          .update({
            'initial_driver_location': driverLocation,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_pesanan', idPesanan);

      print('✅ Driver initial location saved for chat activation');
    } catch (e) {
      print('❌ Error saving initial location: $e');
    }
  }

  // ==================== HELPER FUNCTIONS ====================

  Map<String, double>? _parsePointWKT(String? wkt) {
    if (wkt == null) return null;
    
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
}
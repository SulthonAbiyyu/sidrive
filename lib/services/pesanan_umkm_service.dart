// 📍 LOKASI: lib/services/pesanan_umkm_service.dart

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/pesanan_umkm_model.dart';

class PesananUmkmService {
  final _supabase = Supabase.instance.client;
  
  // ==================== GET PESANAN ====================
  
  Future<List<PesananUmkmModel>> getPesananByUmkm({required String umkmId}) async {
    try {
      final response = await _supabase
          .from('pesanan')
          .select('''
            *,
            users!inner(nama, no_telp),
            detail_pesanan(*)
          ''')
          .eq('id_umkm', umkmId)
          .order('tanggal_pesanan', ascending: false);
      
      return response.map((json) => PesananUmkmModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error get pesanan: $e');
      return [];
    }
  }
  
  /// ✅ CRITICAL: Get single pesanan by ID dengan detail lengkap
  /// Method ini WAJIB ada karena dipanggil di _cariDriver()
  Future<Map<String, dynamic>?> getPesananById(String idPesanan) async {
    try {
      print('🔍 Getting pesanan by ID: $idPesanan');
      
      final response = await _supabase
          .from('pesanan')
          .select('''
            *,
            users!inner(nama, no_telp),
            detail_pesanan(*)
          ''')
          .eq('id_pesanan', idPesanan)
          .single();
      
      print('✅ Pesanan found: ${response['id_pesanan']}');
      return response;
      
    } catch (e) {
      print('❌ Error get pesanan by id: $e');
      return null;
    }
  }
  
  // ==================== UMKM ACTIONS ====================
  
  /// ✅ STEP 1: UMKM Terima Pesanan
  /// Status: menunggu_konfirmasi → diproses
  Future<bool> acceptPesanan(String idPesanan) async {
    try {
      print('✅ UMKM menerima pesanan: $idPesanan');
      
      // Update status
      await _supabase.from('pesanan').update({
        'status_pesanan': 'diproses',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      // Kirim notif ke customer
      final pesanan = await _supabase
          .from('pesanan')
          .select('id_user')
          .eq('id_pesanan', idPesanan)
          .single();
      
      await _supabase.from('notifikasi').insert({
        'id_user': pesanan['id_user'],
        'judul': 'Pesanan Diterima Toko! 🎉',
        'pesan': 'Toko sedang memproses pesanan Anda.',
        'jenis': 'pesanan',
        'status': 'unread',
        'data_tambahan': {'id_pesanan': idPesanan},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Status → diproses');
      return true;
    } catch (e) {
      print('❌ Error accept: $e');
      return false;
    }
  }
  
  /// ❌ UMKM Tolak Pesanan
  /// Status: menunggu_konfirmasi → dibatalkan
  Future<bool> rejectPesanan(String idPesanan) async {
    try {
      print('❌ UMKM menolak pesanan: $idPesanan');
      
      await _supabase.from('pesanan').update({
        'status_pesanan': 'dibatalkan',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      // TODO: Restore stock produk
      
      // Kirim notif ke customer
      final pesanan = await _supabase
          .from('pesanan')
          .select('id_user')
          .eq('id_pesanan', idPesanan)
          .single();
      
      await _supabase.from('notifikasi').insert({
        'id_user': pesanan['id_user'],
        'judul': 'Pesanan Ditolak 😔',
        'pesan': 'Maaf, pesanan ditolak oleh toko.',
        'jenis': 'pesanan',
        'status': 'unread',
        'data_tambahan': {'id_pesanan': idPesanan},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('❌ Error reject: $e');
      return false;
    }
  }
  
  /// 📦 STEP 2: UMKM Tandai Siap
  /// Status: diproses → siap_kirim
  Future<bool> markAsReady(String idPesanan) async {
    try {
      print('📦 Menandai siap: $idPesanan');
      
      await _supabase.from('pesanan').update({
        'status_pesanan': 'siap_kirim',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      // Kirim notif ke customer
      final pesanan = await _supabase
          .from('pesanan')
          .select('id_user, metode_pengiriman')
          .eq('id_pesanan', idPesanan)
          .single();
      
      final isDriver = pesanan['metode_pengiriman'] == 'driver';
      
      await _supabase.from('notifikasi').insert({
        'id_user': pesanan['id_user'],
        'judul': 'Pesanan Siap! ✨',
        'pesan': isDriver 
            ? 'Pesanan Anda sudah siap dan akan segera dicari driver.'
            : 'Pesanan Anda sudah siap diambil di toko!',
        'jenis': 'pesanan',
        'status': 'unread',
        'data_tambahan': {'id_pesanan': idPesanan},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Status → siap_kirim');
      return true;
    } catch (e) {
      print('❌ Error mark ready: $e');
      return false;
    }
  }
  
  /// 🚗 STEP 3: Start Cari Driver
  /// Status: siap_kirim → mencari_driver
  Future<bool> startSearchingDriver(String idPesanan) async {
    try {
      print('🚗 Mulai cari driver: $idPesanan');
      
      // Get pesanan data
      final pesanan = await _supabase
          .from('pesanan')
          .select('''
            id_pesanan,
            id_user,
            id_umkm,
            alamat_asal,
            alamat_tujuan,
            lokasi_asal,
            lokasi_tujuan,
            ongkir,
            metode_pengiriman,
            jenis_kendaraan,
            users!inner(nama)
          ''')
          .eq('id_pesanan', idPesanan)
          .single();
      
      // Validasi
      if (pesanan['metode_pengiriman'] != 'driver') {
        throw Exception('Pesanan ini tidak pakai driver');
      }
      
      // ✅ Update status + SET search_start_time DI SINI!
      await _supabase.from('pesanan').update({
        'status_pesanan': 'mencari_driver',
        'search_start_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      // Get UMKM location
      final umkmData = await _supabase
          .from('umkm')
          .select('lokasi_toko, alamat_toko')
          .eq('id_umkm', pesanan['id_umkm'])
          .single();
      
      // ✅ Parse WKB (Well-Known Binary) hex string dari PostGIS
      /// Fungsi untuk decode WKB POINT hex string ke lat/lng
      /// Format WKB: 0101000020E6100000[longitude 8 bytes][latitude 8 bytes]
      Map<String, double> parseWKBPoint(String? wkbHex) {
        if (wkbHex == null || wkbHex.isEmpty) {
          throw Exception('WKB hex string is null or empty');
        }
        
        try {
          print('🔍 Parsing WKB: $wkbHex');
          
          // Convert hex string to bytes
          final bytes = <int>[];
          for (var i = 0; i < wkbHex.length; i += 2) {
            bytes.add(int.parse(wkbHex.substring(i, i + 2), radix: 16));
          }
          
          final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
          
          int offset = 0;
          
          // 1. Byte order (1 byte) - 01 = little endian, 00 = big endian
          final byteOrder = byteData.getUint8(offset);
          offset += 1;
          final endian = byteOrder == 0 ? Endian.big : Endian.little;
          
          // 2. Geometry type (4 bytes)
          final geoType = byteData.getUint32(offset, endian);
          offset += 4;
          
          // 3. Check if SRID is present (flag 0x20000000)
          if (geoType & 0x20000000 != 0) {
            // Skip SRID (4 bytes)
            offset += 4;
          }
          
          // 4. X coordinate (longitude) - 8 bytes IEEE 754 double
          final lng = byteData.getFloat64(offset, endian);
          offset += 8;
          
          // 5. Y coordinate (latitude) - 8 bytes IEEE 754 double
          final lat = byteData.getFloat64(offset, endian);
          
          print('✅ Decoded: lat=$lat, lng=$lng');
          
          return {'lat': lat, 'lng': lng};
        } catch (e) {
          print('❌ Error decoding WKB: $e');
          rethrow;
        }
      }
      
      print('📍 Raw lokasi toko: ${umkmData['lokasi_toko']}');
      print('📍 Raw lokasi tujuan: ${pesanan['lokasi_tujuan']}');
      
      // Parse WKB ke koordinat
      final tokoCoords = parseWKBPoint(umkmData['lokasi_toko']?.toString());
      final tujuanCoords = parseWKBPoint(pesanan['lokasi_tujuan']?.toString());
      
      final tokoLat = tokoCoords['lat']!;
      final tokoLng = tokoCoords['lng']!;
      final tujuanLat = tujuanCoords['lat']!;
      final tujuanLng = tujuanCoords['lng']!;
      
      print('✅ Toko parsed: ($tokoLat, $tokoLng)');
      print('✅ Tujuan parsed: ($tujuanLat, $tujuanLng)');
      
      // 🔔 Kirim notifikasi ke driver
      print('🔔 Kirim notif driver...');
      
      await _supabase.functions.invoke(
        'send-new-order-notification',
        body: {
          'orderId': idPesanan,
          'customerId': pesanan['id_user'],
          'customerName': pesanan['users']['nama'],
          'jenisPesanan': 'umkm',
          'jenisKendaraan': pesanan['jenis_kendaraan'],
          'lokasiJemput': umkmData['alamat_toko'],
          'lokasiTujuan': pesanan['alamat_tujuan'],
          'lokasiJemputLat': tokoLat,
          'lokasiJemputLng': tokoLng,
          'lokasiTujuanLat': tujuanLat,
          'lokasiTujuanLng': tujuanLng,
          'lokasiTokoLat': tokoLat,
          'lokasiTokoLng': tokoLng,
          'jarak': 0,
          'ongkir': pesanan['ongkir'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      print('✅ Status → mencari_driver');
      print('✅ Notif driver sent');
      
      return true;
    } catch (e) {
      print('❌ Error start searching: $e');
      return false;
    }
  }
  
  /// 🏪 STEP 4A: Complete Ambil Sendiri
  /// Status: siap_kirim → selesai (untuk ambil sendiri)
  Future<bool> completeAmbilSendiri(String idPesanan) async {
    try {
      print('🏪 Complete ambil sendiri: $idPesanan');
      
      // Validasi
      final pesanan = await _supabase
          .from('pesanan')
          .select('metode_pengiriman, payment_method, payment_status')
          .eq('id_pesanan', idPesanan)
          .single();
      
      if (pesanan['metode_pengiriman'] != 'ambil_sendiri') {
        throw Exception('Pesanan ini pakai driver');
      }
      
      if (pesanan['payment_method'] != 'cash' && pesanan['payment_status'] != 'paid') {
        throw Exception('Pesanan belum dibayar');
      }
      
      // Update status
      await _supabase.from('pesanan').update({
        'status_pesanan': 'selesai',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      print('✅ Status → selesai (ambil sendiri)');
      return true;
    } catch (e) {
      print('❌ Error complete ambil sendiri: $e');
      return false;
    }
  }
  
  /// Generic update status
  Future<bool> updateStatusPesanan(String idPesanan, String newStatus) async {
    try {
      await _supabase.from('pesanan').update({
        'status_pesanan': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_pesanan', idPesanan);
      
      return true;
    } catch (e) {
      print('❌ Error update status: $e');
      return false;
    }
  }
}
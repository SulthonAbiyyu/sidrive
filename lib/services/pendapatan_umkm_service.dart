// lib/services/pendapatan_umkm_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/pendapatan_umkm_model.dart';

class PendapatanUmkmService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get pendapatan by periode
  Future<PendapatanUmkmModel> getPendapatanByPeriode({
    required String umkmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('📊 Fetching pendapatan UMKM: $umkmId');
      print('📊 Periode: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}');

      // 1. Ambil pesanan selesai
      final pesananResponse = await _supabase
          .from('pesanan')
          .select('*, detail_pesanan(*)')
          .eq('id_umkm', umkmId)
          .eq('status_pesanan', 'selesai')
          .gte('updated_at', startDate.toIso8601String())
          .lt('updated_at', endDate.toIso8601String())
          .order('updated_at', ascending: false);

      print('📊 Found ${pesananResponse.length} pesanan');

      if (pesananResponse.isEmpty) {
        return PendapatanUmkmModel.empty();
      }

      double totalPenjualan = 0;     // Total subtotal produk
      double totalOngkir = 0;        // Total ongkir
      double totalFeeAdmin = 0;      // Total fee 10%
      int totalProdukTerjual = 0;

      for (var pesanan in pesananResponse) {
        final subtotal = (pesanan['subtotal'] ?? 0).toDouble();
        final ongkir = (pesanan['ongkir'] ?? 0).toDouble();
        
        totalPenjualan += subtotal;
        totalOngkir += ongkir;
        totalFeeAdmin += subtotal * 0.10; // 10% dari subtotal
        
        // Hitung total produk terjual
        if (pesanan['detail_pesanan'] != null) {
          for (var detail in pesanan['detail_pesanan']) {
            totalProdukTerjual += (detail['jumlah'] ?? 0) as int;
          }
        }
      }

      // Pendapatan bersih = 90% dari penjualan
      final totalPendapatan = totalPenjualan * 0.90;

      print('✅ Total Penjualan: Rp ${totalPenjualan.toStringAsFixed(0)}');
      print('✅ Total Pendapatan (90%): Rp ${totalPendapatan.toStringAsFixed(0)}');
      print('✅ Total Pesanan: ${pesananResponse.length}');
      print('✅ Total Produk Terjual: $totalProdukTerjual');

      return PendapatanUmkmModel(
        totalPenjualan: totalPenjualan,
        totalPendapatan: totalPendapatan,
        totalPesanan: pesananResponse.length,
        totalProdukTerjual: totalProdukTerjual,
        totalOngkir: totalOngkir,
        totalFeeAdmin: totalFeeAdmin,
        listPesanan: List<Map<String, dynamic>>.from(pesananResponse),
      );
    } catch (e, stackTrace) {
      print('❌ Error get pendapatan UMKM: $e');
      print('Stack: $stackTrace');
      throw Exception('Gagal mengambil data pendapatan: $e');
    }
  }

  /// Get pendapatan hari ini
  Future<PendapatanUmkmModel> getPendapatanHariIni(String umkmId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getPendapatanByPeriode(
      umkmId: umkmId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get pendapatan minggu ini
  Future<PendapatanUmkmModel> getPendapatanMingguIni(String umkmId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getPendapatanByPeriode(
      umkmId: umkmId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get pendapatan bulan ini
  Future<PendapatanUmkmModel> getPendapatanBulanIni(String umkmId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getPendapatanByPeriode(
      umkmId: umkmId,
      startDate: startOfMonth,
      endDate: endDate,
    );
  }

  /// Get top produk terlaris
  Future<List<Map<String, dynamic>>> getTopProduk({
    required String umkmId,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('produk')
          .select('nama_produk, total_terjual, harga_produk, foto_produk')
          .eq('id_umkm', umkmId)
          .order('total_terjual', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error get top produk: $e');
      return [];
    }
  }

  /// Get riwayat pesanan selesai
  Future<List<Map<String, dynamic>>> getRiwayatPesanan({
    required String umkmId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('pesanan')
          .select('*, detail_pesanan(*)')
          .eq('id_umkm', umkmId)
          .eq('status_pesanan', 'selesai')
          .order('updated_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error get riwayat: $e');
      return [];
    }
  }

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
}
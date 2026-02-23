// ============================================================================
// UMKM_SERVICE.DART
// Service untuk manage UMKM (toko & produk)
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/models/umkm_model.dart';
import 'package:sidrive/models/produk_model.dart';

class UmkmService {
  final SupabaseClient _supabase = Supabase.instance.client;


  Future<Map<String, int>> getDashboardCounts(String idUmkm) async {
    try {
      // Query pesanan aktif
      final pesananResult = await _supabase
          .from('pesanan')
          .select('id_pesanan')
          .eq('id_umkm', idUmkm)
          .not('status_pesanan', 'in', '(selesai,dibatalkan,gagal)');
      
      final activePesanan = (pesananResult as List).length;
      
      // Query jumlah produk
      final produkResult = await _supabase
          .from('produk')
          .select('id_produk')
          .eq('id_umkm', idUmkm);
      
      final totalProduk = (produkResult as List).length;
      
      return {
        'active_pesanan': activePesanan,
        'total_produk': totalProduk,
      };
    } catch (e) {
      print('❌ Error get dashboard counts: $e');
      return {
        'active_pesanan': 0,
        'total_produk': 0,
      };
    }
  }


  // =========================================================================
  // UMKM / TOKO MANAGEMENT
  // =========================================================================

  Future<UmkmModel?> getUmkmByUserId(String userId) async {
    try {
      print('📡 [UMKM_SERVICE] Fetching UMKM for user: $userId');
      
      // 🔥 FIX: Gunakan ST_AsText() untuk convert geometry ke readable text
      final response = await _supabase
          .rpc('get_umkm_by_user', params: {
            'user_id': userId,
          });

      print('📡 [UMKM_SERVICE] Response: ${response != null ? "FOUND" : "NULL"}');

      if (response == null || (response is List && response.isEmpty)) {
        print('📡 [UMKM_SERVICE] ❌ No UMKM found for user');
        return null;
      }
      
      // Jika response adalah List, ambil item pertama
      final data = response is List ? response.first : response;
      
      final umkm = UmkmModel.fromJson(data);
      print('📡 [UMKM_SERVICE] ✅ UMKM loaded: ${umkm.namaToko}');
      print('📡 [UMKM_SERVICE] 🗺️ Lokasi parsed: ${umkm.lokasiTokoLatLng}');
      return umkm;
      
    } catch (e, stackTrace) {
      print('📡 [UMKM_SERVICE] ❌ Error: $e');
      print('📡 [UMKM_SERVICE] Stack: $stackTrace');
      return null;
    }
  }

  Future<UmkmModel?> getUmkmById(String idUmkm) async {
    try {
      print('📡 [UMKM_SERVICE] Fetching UMKM by ID: $idUmkm');
      
      // 🔥 FIX: Gunakan RPC function
      final response = await _supabase
          .rpc('get_umkm_by_id', params: {
            'umkm_id': idUmkm,
          });

      print('📡 [UMKM_SERVICE] Response: ${response != null ? "FOUND" : "NULL"}');

      if (response == null || (response is List && response.isEmpty)) {
        print('📡 [UMKM_SERVICE] ❌ No UMKM found');
        return null;
      }
      
      final data = response is List ? response.first : response;
      
      final umkm = UmkmModel.fromJson(data);
      print('📡 [UMKM_SERVICE] ✅ UMKM loaded: ${umkm.namaToko}');
      print('📡 [UMKM_SERVICE] 🗺️ Lokasi parsed: ${umkm.lokasiTokoLatLng}');
      return umkm;
      
    } catch (e, stackTrace) {
      print('📡 [UMKM_SERVICE] ❌ Error: $e');
      print('📡 [UMKM_SERVICE] Stack: $stackTrace');
      return null;
    }
  }

  /// Check if user already has a toko
  Future<bool> hasExistingToko(String userId) async {
    try {
      final result = await _supabase
          .from('umkm')
          .select('id_umkm')
          .eq('id_user', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ Error check existing toko: $e');
      return false;
    }
  }

  Future<bool> setupToko({
    required String idUser,
    required String namaToko,
    required String alamatToko,
    required String kategoriToko,
    required String deskripsiToko,
    String? fotoToko,
    required String jamBuka,
    required String jamTutup,
    String? lokasiToko,
    required String namaBank,
    required String namaRekening,
    required String nomorRekening,
  }) async {
    try {
      print('🏪 Setting up new toko...');

      final data = {
        'id_user': idUser,
        'nama_toko': namaToko,
        'alamat_toko': alamatToko,
        'kategori_toko': kategoriToko,
        'deskripsi_toko': deskripsiToko,
        'foto_toko': fotoToko,
        'jam_buka': jamBuka,
        'jam_tutup': jamTutup,
        'lokasi_toko': lokasiToko,
        'nama_bank': namaBank,
        'nama_rekening': namaRekening,
        'nomor_rekening': nomorRekening,
        'status_toko': 'tutup',
        'rating_toko': 0.0,
        'total_rating': 0,
        // ✅ HAPUS: saldo_tersedia (sudah di users.saldo_wallet)
        'total_penjualan': 0.0,
        'jumlah_produk_terjual': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('umkm').insert(data);

      print('✅ Toko setup successful');
      return true;
    } catch (e) {
      print('❌ Error setup toko: $e');
      return false;
    }
  }

  /// Update status toko (buka/tutup)
  Future<bool> updateStatusToko(String idUmkm, String newStatus) async {
    try {
      await _supabase
          .from('umkm')
          .update({
            'status_toko': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_umkm', idUmkm);

      print('✅ Status toko updated: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error update status: $e');
      return false;
    }
  }

  /// Update info toko
  Future<bool> updateInfoToko({
    required String idUmkm,
    String? namaToko,
    String? alamatToko,
    String? deskripsiToko,
    String? fotoToko,
    String? jamBuka,
    String? jamTutup,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (namaToko != null) updates['nama_toko'] = namaToko;
      if (alamatToko != null) updates['alamat_toko'] = alamatToko;
      if (deskripsiToko != null) updates['deskripsi_toko'] = deskripsiToko;
      if (fotoToko != null) updates['foto_toko'] = fotoToko;
      if (jamBuka != null) updates['jam_buka'] = jamBuka;
      if (jamTutup != null) updates['jam_tutup'] = jamTutup;

      await _supabase.from('umkm').update(updates).eq('id_umkm', idUmkm);

      print('✅ Info toko updated');
      return true;
    } catch (e) {
      print('❌ Error update info: $e');
      return false;
    }
  }

  // =========================================================================
  // PRODUK MANAGEMENT
  // =========================================================================

  /// Get all products by UMKM ID
  Future<List<ProdukModel>> getProdukByUmkmId(String idUmkm) async {
    try {
      final response = await _supabase
          .from('produk')
          .select()
          .eq('id_umkm', idUmkm)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProdukModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error get produk: $e');
      return [];
    }
  }

  /// Get product detail
  Future<ProdukModel?> getProdukDetail(String idProduk) async {
    try {
      final response = await _supabase
          .from('produk')
          .select()
          .eq('id_produk', idProduk)
          .single();

      return ProdukModel.fromJson(response);
    } catch (e) {
      print('❌ Error get produk detail: $e');
      return null;
    }
  }

  /// Add new product
  Future<ProdukModel?> addProduk({
    required String idUmkm,
    required String namaProduk,
    String? deskripsiProduk,
    required double hargaProduk,
    required int stokProduk,
    required String kategoriProduk,
    List<String>? fotoProduk,
    int? beratGram,                 
    int? waktuPersiapanMenit,
    String? allowedDriverType,
  }) async {
    try {
      final data = {
        'id_umkm': idUmkm,
        'nama_produk': namaProduk,
        'deskripsi_produk': deskripsiProduk,
        'harga_produk': hargaProduk,
        'stok': stokProduk, 
        'kategori_produk': kategoriProduk,
        'foto_produk': fotoProduk,
        'is_available': true, 
        'total_terjual': 0,
        'rating_produk': 0.0,            
        'total_rating': 0,               
        'berat_gram': beratGram,         
        'waktu_persiapan_menit': waktuPersiapanMenit ?? 15, 
        'allowed_driver_type': allowedDriverType ?? 'MOTOR_AND_CAR',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('produk')
          .insert(data)
          .select()
          .single();

      print('✅ Produk added: ${response['id_produk']}');
      return ProdukModel.fromJson(response);
    } catch (e) {
      print('❌ Error add produk: $e');
      return null;
    }
  }

  /// Update product
  Future<bool> updateProduk({
    required String idProduk,
    String? namaProduk,
    String? deskripsiProduk,
    double? hargaProduk,
    int? stokProduk,
    String? kategoriProduk,
    List<String>? fotoProduk,
    bool? isAvailable,
    int? beratGram,                  
    int? waktuPersiapanMenit,
    String? allowedDriverType,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (namaProduk != null) updates['nama_produk'] = namaProduk;
      if (deskripsiProduk != null) updates['deskripsi_produk'] = deskripsiProduk;
      if (hargaProduk != null) updates['harga_produk'] = hargaProduk;
      if (stokProduk != null) updates['stok'] = stokProduk; 
      if (kategoriProduk != null) updates['kategori_produk'] = kategoriProduk;
      if (fotoProduk != null) updates['foto_produk'] = fotoProduk;
      if (isAvailable != null) updates['is_available'] = isAvailable;
      if (beratGram != null) updates['berat_gram'] = beratGram;                    
      if (waktuPersiapanMenit != null) updates['waktu_persiapan_menit'] = waktuPersiapanMenit;  
      if (allowedDriverType != null) updates['allowed_driver_type'] = allowedDriverType; 

      await _supabase.from('produk').update(updates).eq('id_produk', idProduk);

      print('✅ Produk updated');
      return true;
    } catch (e) {
      print('❌ Error update produk: $e');
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduk(String idProduk) async {
    try {
      await _supabase.from('produk').delete().eq('id_produk', idProduk);

      print('✅ Produk deleted');
      return true;
    } catch (e) {
      print('❌ Error delete produk: $e');
      return false;
    }
  }

  /// Toggle product active status
  Future<bool> toggleProdukAktif(String idProduk, bool newStatus) async {
    try {
      await _supabase
          .from('produk')
          .update({
            'is_available': newStatus, // ✅ BENAR
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_produk', idProduk);

      print('✅ Produk status toggled: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error toggle produk: $e');
      return false;
    }
  }

  Future<bool> updateStokProduk(String idProduk, int jumlahTerjual) async {
    try {
      // Ambil stok saat ini
      final produk = await getProdukDetail(idProduk);
      if (produk == null) {
        print('❌ Produk tidak ditemukan: $idProduk');
        return false;
      }

      final stokBaru = produk.stok - jumlahTerjual;

      // ✅ CATATAN: total_terjual akan di-update otomatis oleh trigger database
      // saat status_pesanan berubah jadi 'selesai', tapi kita tetap update manual
      // sebagai backup jika trigger gagal
      await _supabase.from('produk').update({
        'stok': stokBaru < 0 ? 0 : stokBaru,
        'total_terjual': produk.totalTerjual + jumlahTerjual,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_produk', idProduk);

      // Auto disable jika stok habis
      if (stokBaru <= 0) {
        await toggleProdukAktif(idProduk, false);
        print('⚠️ Produk disabled karena stok habis: $idProduk');
      }

      print('✅ Stok updated: $idProduk | Stok baru: $stokBaru | Total terjual: ${produk.totalTerjual + jumlahTerjual}');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error update stok: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // =========================================================================
  // SEARCH & FILTER
  // =========================================================================

  /// Search produk (untuk customer)
  Future<List<ProdukModel>> searchProduk({
    String? keyword,
    String? kategori,
    String? idUmkm,
    double? minHarga,
    double? maxHarga,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('produk')
          .select()
          .eq('is_available', true);

      // Filter
      if (keyword != null && keyword.isNotEmpty) {
        query = query.ilike('nama_produk', '%$keyword%');
      }
      if (kategori != null) {
        query = query.eq('kategori_produk', kategori);
      }
      if (idUmkm != null) {
        query = query.eq('id_umkm', idUmkm);
      }
      if (minHarga != null) {
        query = query.gte('harga_produk', minHarga);
      }
      if (maxHarga != null) {
        query = query.lte('harga_produk', maxHarga);
      }

      // Sort dan execute langsung
      final response = await query.order(sortBy, ascending: ascending);

      return (response as List) 
          .map((json) => ProdukModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error search produk: $e');
      return [];
    }
  }

  /// Get kategori produk (untuk dropdown)
  Future<List<String>> getKategoriProduk() async {
    try {
      // Ambil dari enum di database
      final result = await _supabase.rpc('get_enum_values', params: {
        'enum_name': 'kategori_produk'
      });

      if (result is List) {
        return result.map((e) => e.toString()).toList();
      }

      // Fallback jika function tidak ada
      return [
        'makanan',
        'minuman',
        'snack',
        'kue',
        'lauk',
        'lainnya',
      ];
    } catch (e) {
      print('❌ Error get kategori: $e');
      // Fallback
      return [
        'makanan',
        'minuman',
        'snack',
        'kue',
        'lauk',
        'lainnya',
      ];
    }
  }

  // =========================================================================
  // STATISTICS
  // =========================================================================

  Future<Map<String, dynamic>> getUmkmStats(String idUmkm) async {
    try {
      // Get produk count
      final produkResponse = await _supabase
          .from('produk')
          .select('id_produk')
          .eq('id_umkm', idUmkm)
          .eq('is_available', true);

      final produkAktifCount = (produkResponse as List).length;

      // Get UMKM data
      final umkmResponse = await _supabase
          .from('umkm')
          .select('id_user, total_penjualan, jumlah_produk_terjual, rating_toko')
          .eq('id_umkm', idUmkm)
          .maybeSingle();
      
      if (umkmResponse == null) {
        return {
          'produk_aktif': 0,
          'total_penjualan': 0.0,
          'produk_terjual': 0,
          'rating': 0.0,
          'saldo': 0.0,
        };
      }

      // ✅ FIX: Ambil saldo dari users
      final user = await _supabase
          .from('users')
          .select('saldo_wallet')
          .eq('id_user', umkmResponse['id_user'])
          .maybeSingle();

      final saldo = user != null ? (user['saldo_wallet'] ?? 0).toDouble() : 0.0;

      return {
        'produk_aktif': produkAktifCount,
        'total_penjualan': (umkmResponse['total_penjualan'] ?? 0).toDouble(),
        'produk_terjual': umkmResponse['jumlah_produk_terjual'] ?? 0,
        'rating': (umkmResponse['rating_toko'] ?? 0).toDouble(),
        'saldo': saldo, // ✅ Dari users.saldo_wallet
      };
    } catch (e) {
      print('❌ Error get stats: $e');
      return {
        'produk_aktif': 0,
        'total_penjualan': 0.0,
        'produk_terjual': 0,
        'rating': 0.0,
        'saldo': 0.0,
      };
    }
  }
}
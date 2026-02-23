// ============================================================================
// RATING_ULASAN_SERVICE.DART
// Service universal untuk rating & review (Driver, UMKM, Produk)
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class RatingUlasanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // CONSTANTS
  // ============================================================================
  static const int MIN_REVIEWS_FOR_MATURE_RATING = 20;
  static const double DEFAULT_RATING = 5.0;

  // ============================================================================
  // 1️⃣ SUBMIT RATING - UNIVERSAL (Driver & Produk)
  // ============================================================================
  Future<bool> submitRating({
    required String idPesanan,
    required String idUser,
    required String targetType, // 'driver' | 'produk'
    required String targetId,
    required int rating,
    String? reviewText,
    List<String>? fotoUlasan,
  }) async {
    try {
      print('📊 [RatingUlasanService] Submitting rating...');
      print('   - Pesanan: $idPesanan');
      print('   - Target Type: $targetType');
      print('   - Target ID: $targetId');
      print('   - Rating: $rating ⭐');

      // ✅ CEK APAKAH SUDAH ADA RATING
      final existingRating = await _supabase
          .from('rating_reviews')
          .select('id_review')
          .eq('id_pesanan', idPesanan)
          .eq('id_user', idUser)
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .maybeSingle();

      final data = {
        'id_pesanan': idPesanan,
        'id_user': idUser,
        'target_type': targetType,
        'target_id': targetId,
        'rating': rating,
        'review_text': reviewText?.isEmpty ?? true ? null : reviewText,
        'foto_ulasan': fotoUlasan,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (existingRating != null) {
        // ✅ SUDAH ADA → UPDATE
        print('🔄 [RatingUlasanService] Rating exists, updating...');
        await _supabase
            .from('rating_reviews')
            .update({
              'rating': rating,
              'review_text': reviewText?.isEmpty ?? true ? null : reviewText,
              'foto_ulasan': fotoUlasan,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id_review', existingRating['id_review']);
        
        print('✅ [RatingUlasanService] Rating updated');
      } else {
        // ✅ BELUM ADA → INSERT
        print('➕ [RatingUlasanService] No existing rating, inserting new...');
        await _supabase.from('rating_reviews').insert(data);
        print('✅ [RatingUlasanService] Rating inserted');
      }

      // 🔥 TRIGGER DATABASE AKAN AUTO UPDATE RATING!
      // - update_driver_rating() untuk driver
      // - update_produk_rating() untuk produk
      // - update_umkm_rating() untuk umkm (dari produk)
      print('✅ [RatingUlasanService] Database trigger will auto-update ratings');

      return true;
    } catch (e) {
      print('❌ [RatingUlasanService] Error submit rating: $e');
      return false;
    }
  }

  // ============================================================================
  // 2️⃣ SUBMIT DRIVER RATING - BACKWARD COMPATIBLE (untuk customer/driver existing)
  // ============================================================================
  Future<bool> submitDriverRating({
    required String idPesanan,
    required String idCustomer,
    required String idDriver,
    required int rating,
    String? reviewText,
  }) async {
    return submitRating(
      idPesanan: idPesanan,
      idUser: idCustomer,
      targetType: 'driver',
      targetId: idDriver,
      rating: rating,
      reviewText: reviewText,
    );
  }

  // ============================================================================
  // 3️⃣ SUBMIT PRODUK RATING (untuk UMKM nanti)
  // ============================================================================
  Future<bool> submitProdukRating({
    required String idPesanan,
    required String idUser,
    required String idProduk,
    required int rating,
    String? reviewText,
    List<String>? fotoUlasan,
  }) async {
    return submitRating(
      idPesanan: idPesanan,
      idUser: idUser,
      targetType: 'produk',
      targetId: idProduk,
      rating: rating,
      reviewText: reviewText,
      fotoUlasan: fotoUlasan,
    );
  }

  // ============================================================================
  // 4️⃣ SUBMIT BULK PRODUK RATING (rate banyak produk sekaligus)
  // ============================================================================
  Future<bool> submitBulkProdukRating({
    required String idPesanan,
    required String idUser,
    required List<Map<String, dynamic>> products, // [{ idProduk, rating, reviewText, fotoUlasan }]
  }) async {
    try {
      print('📦 [RatingUlasanService] Submitting bulk product ratings...');
      print('   - Total products: ${products.length}');

      for (var product in products) {
        final success = await submitProdukRating(
          idPesanan: idPesanan,
          idUser: idUser,
          idProduk: product['idProduk'],
          rating: product['rating'],
          reviewText: product['reviewText'],
          fotoUlasan: product['fotoUlasan'],
        );

        if (!success) {
          print('⚠️ Failed to submit rating for product: ${product['idProduk']}');
        }
      }

      print('✅ [RatingUlasanService] Bulk rating submitted');
      return true;
    } catch (e) {
      print('❌ [RatingUlasanService] Error bulk submit: $e');
      return false;
    }
  }

  // ============================================================================
  // 5️⃣ GET RATING BREAKDOWN - UNIVERSAL
  // ============================================================================
  Future<Map<String, dynamic>> getRatingBreakdown({
    required String targetType, // 'driver' | 'umkm' | 'produk'
    required String targetId,
  }) async {
    try {
      print('📊 [RatingUlasanService] Getting rating breakdown...');
      print('   - Target Type: $targetType');
      print('   - Target ID: $targetId');

      // ✅ Ambil semua rating
      final ratings = await _supabase
          .from('rating_reviews')
          .select('rating')
          .eq('target_id', targetId)
          .eq('target_type', targetType);

      if (ratings.isEmpty) {
        print('⚠️ No ratings found');
        return {
          'total_reviews': 0,
          'average_rating': DEFAULT_RATING,
          'star_5': 0,
          'star_4': 0,
          'star_3': 0,
          'star_2': 0,
          'star_1': 0,
          'percentage_5': 0.0,
          'percentage_4': 0.0,
          'percentage_3': 0.0,
          'percentage_2': 0.0,
          'percentage_1': 0.0,
          'is_new_driver': true,
        };
      }

      // Hitung breakdown
      final totalReviews = ratings.length;
      final star5 = ratings.where((r) => r['rating'] == 5).length;
      final star4 = ratings.where((r) => r['rating'] == 4).length;
      final star3 = ratings.where((r) => r['rating'] == 3).length;
      final star2 = ratings.where((r) => r['rating'] == 2).length;
      final star1 = ratings.where((r) => r['rating'] == 1).length;

      final sumRatings = ratings.fold<int>(
        0,
        (sum, item) => sum + (item['rating'] as int),
      );
      final averageRating = sumRatings / totalReviews;

      print('✅ Breakdown calculated: ${averageRating.toStringAsFixed(2)} ⭐ ($totalReviews reviews)');

      return {
        'total_reviews': totalReviews,
        'average_rating': averageRating,
        'star_5': star5,
        'star_4': star4,
        'star_3': star3,
        'star_2': star2,
        'star_1': star1,
        'percentage_5': (star5 / totalReviews * 100),
        'percentage_4': (star4 / totalReviews * 100),
        'percentage_3': (star3 / totalReviews * 100),
        'percentage_2': (star2 / totalReviews * 100),
        'percentage_1': (star1 / totalReviews * 100),
        'is_new_driver': totalReviews < MIN_REVIEWS_FOR_MATURE_RATING,
      };
    } catch (e) {
      print('❌ [RatingUlasanService] Error getting breakdown: $e');
      return {
        'total_reviews': 0,
        'average_rating': DEFAULT_RATING,
        'star_5': 0,
        'star_4': 0,
        'star_3': 0,
        'star_2': 0,
        'star_1': 0,
        'percentage_5': 0.0,
        'percentage_4': 0.0,
        'percentage_3': 0.0,
        'percentage_2': 0.0,
        'percentage_1': 0.0,
        'is_new_driver': true,
      };
    }
  }

  // ============================================================================
  // 6️⃣ GET REVIEWS - UNIVERSAL
  // ============================================================================
  Future<List<Map<String, dynamic>>> getReviews({
    required String targetType, // 'driver' | 'umkm' | 'produk'
    required String targetId,
    int limit = 50,
  }) async {
    try {
      print('📋 [RatingUlasanService] Getting reviews...');
      print('   - Target Type: $targetType');
      print('   - Target ID: $targetId');

      // Join dengan pesanan dan users untuk dapat nama customer
      final reviews = await _supabase
          .from('rating_reviews')
          .select('''
            *,
            pesanan!inner(
              id_pesanan,
              alamat_asal,
              alamat_tujuan,
              id_user
            )
          ''')
          .eq('target_id', targetId)
          .eq('target_type', targetType)
          .order('created_at', ascending: false)
          .limit(limit);

      print('✅ Found ${reviews.length} reviews');

      // Ambil data user untuk setiap review
      final enrichedReviews = <Map<String, dynamic>>[];
      
      for (var review in reviews) {
        try {
          final userId = review['pesanan']['id_user'];
          
          final userData = await _supabase
              .from('users')
              .select('nama, foto_profil')
              .eq('id_user', userId)
              .maybeSingle();

          enrichedReviews.add({
            ...review,
            'customer_name': userData?['nama'] ?? 'Customer',
            'customer_photo': userData?['foto_profil'],
          });
        } catch (e) {
          print('⚠️ Error enriching review: $e');
          enrichedReviews.add({
            ...review,
            'customer_name': 'Customer',
            'customer_photo': null,
          });
        }
      }

      return enrichedReviews;
    } catch (e) {
      print('❌ [RatingUlasanService] Error getting reviews: $e');
      return [];
    }
  }

  // ============================================================================
  // 7️⃣ GET DRIVER REVIEWS - BACKWARD COMPATIBLE
  // ============================================================================
  Future<List<Map<String, dynamic>>> getDriverReviews({
    required String idDriver,
    int limit = 50,
  }) async {
    return getReviews(
      targetType: 'driver',
      targetId: idDriver,
      limit: limit,
    );
  }

  // ============================================================================
  // 8️⃣ GET PRODUK REVIEWS (untuk UMKM)
  // ============================================================================
  Future<List<Map<String, dynamic>>> getProdukReviews({
    required String idProduk,
    int limit = 50,
  }) async {
    return getReviews(
      targetType: 'produk',
      targetId: idProduk,
      limit: limit,
    );
  }

  // ============================================================================
  // 9️⃣ GET UMKM REVIEWS (semua review dari produk-produk toko)
  // ============================================================================
  Future<List<Map<String, dynamic>>> getUmkmReviews({
    required String idUmkm,
    int limit = 50,
  }) async {
    try {
      print('📋 [RatingUlasanService] Getting UMKM reviews...');
      
      // STEP 1: Ambil semua produk dari toko ini
      final produkList = await _supabase
          .from('produk')
          .select('id_produk')
          .eq('id_umkm', idUmkm);

      if (produkList.isEmpty) {
        print('⚠️ No products found for this UMKM');
        return [];
      }

      final produkIds = produkList.map((p) => p['id_produk']).toList();
      print('   - Found ${produkIds.length} products');

      // STEP 2: Ambil semua review dari produk-produk tersebut
      final reviews = await _supabase
          .from('rating_reviews')
          .select('''
            *,
            pesanan!inner(
              id_pesanan,
              id_user
            )
          ''')
          .eq('target_type', 'produk')
          .inFilter('target_id', produkIds)
          .order('created_at', ascending: false)
          .limit(limit);

      print('✅ Found ${reviews.length} total reviews');

      // STEP 3: Enrich dengan nama produk & customer
      final enrichedReviews = <Map<String, dynamic>>[];
      
      for (var review in reviews) {
        try {
          // Ambil nama produk
          final produkData = await _supabase
              .from('produk')
              .select('nama_produk')
              .eq('id_produk', review['target_id'])
              .maybeSingle();

          // Ambil nama customer
          final userId = review['pesanan']['id_user'];
          final userData = await _supabase
              .from('users')
              .select('nama, foto_profil')
              .eq('id_user', userId)
              .maybeSingle();

          enrichedReviews.add({
            ...review,
            'produk_name': produkData?['nama_produk'] ?? 'Produk',
            'customer_name': userData?['nama'] ?? 'Customer',
            'customer_photo': userData?['foto_profil'],
          });
        } catch (e) {
          print('⚠️ Error enriching review: $e');
          enrichedReviews.add({
            ...review,
            'produk_name': 'Produk',
            'customer_name': 'Customer',
            'customer_photo': null,
          });
        }
      }

      return enrichedReviews;
    } catch (e) {
      print('❌ [RatingUlasanService] Error getting UMKM reviews: $e');
      return [];
    }
  }

  // ============================================================================
  // 🔟 GET RATING FOR SPECIFIC ORDER - BACKWARD COMPATIBLE
  // ============================================================================
  Future<Map<String, dynamic>?> getRatingForOrder({
    required String idPesanan,
    required String idDriver,
  }) async {
    try {
      final rating = await _supabase
          .from('rating_reviews')
          .select('*, pesanan!inner(id_user)')
          .eq('id_pesanan', idPesanan)
          .eq('target_id', idDriver)
          .eq('target_type', 'driver')
          .maybeSingle();

      if (rating == null) return null;

      // Ambil nama customer
      final userId = rating['pesanan']['id_user'];
      final userData = await _supabase
          .from('users')
          .select('nama, foto_profil')
          .eq('id_user', userId)
          .maybeSingle();

      return {
        ...rating,
        'customer_name': userData?['nama'] ?? 'Customer',
        'customer_photo': userData?['foto_profil'],
      };
    } catch (e) {
      print('❌ [RatingUlasanService] Error getting order rating: $e');
      return null;
    }
  }

  // ============================================================================
  // 1️⃣1️⃣ CHECK IF ORDER HAS RATING - BACKWARD COMPATIBLE
  // ============================================================================
  Future<bool> hasRating(String idPesanan) async {
    try {
      final result = await _supabase
          .from('rating_reviews')
          .select('id_review')
          .eq('id_pesanan', idPesanan)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('❌ [RatingUlasanService] Error checking rating: $e');
      return false;
    }
  }

  // ============================================================================
  // 1️⃣2️⃣ UPDATE DRIVER RATING MANUAL (jika trigger gagal)
  // ============================================================================
  Future<void> updateDriverRating(String idDriver) async {
    try {
      print('🔄 [RatingUlasanService] Manual update driver rating...');

      final ratings = await _supabase
          .from('rating_reviews')
          .select('rating')
          .eq('target_id', idDriver)
          .eq('target_type', 'driver');

      if (ratings.isEmpty) {
        print('⚠️ No ratings found, keeping default rating');
        
        await _supabase.from('drivers').update({
          'rating_driver': DEFAULT_RATING,
          'total_rating': 0,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_driver', idDriver);
        
        return;
      }

      final totalRatings = ratings.length;
      final sumRatings = ratings.fold<int>(
        0,
        (sum, item) => sum + (item['rating'] as int),
      );
      final averageRating = sumRatings / totalRatings;

      print('📊 Calculation: $totalRatings reviews, avg: ${averageRating.toStringAsFixed(2)}');

      await _supabase.from('drivers').update({
        'rating_driver': averageRating,
        'total_rating': totalRatings,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_driver', idDriver);

      print('✅ Driver rating updated successfully');
    } catch (e) {
      print('❌ [RatingUlasanService] Error updating driver rating: $e');
    }
  }

  // ============================================================================
  // 1️⃣3️⃣ BATCH UPDATE ALL DRIVERS (untuk migration)
  // ============================================================================
  Future<void> batchUpdateAllDriverRatings() async {
    try {
      print('🔄 [RatingUlasanService] Starting batch update for all drivers...');

      final drivers = await _supabase
          .from('drivers')
          .select('id_driver');

      print('📊 Found ${drivers.length} drivers to update');

      int updated = 0;
      for (var driver in drivers) {
        try {
          await updateDriverRating(driver['id_driver']);
          updated++;
          
          if (updated % 10 == 0) {
            print('   Progress: $updated/${drivers.length}');
          }
        } catch (e) {
          print('   ⚠️ Failed to update driver ${driver['id_driver']}: $e');
        }
      }

      print('✅ Batch update complete! Updated $updated drivers');
    } catch (e) {
      print('❌ [RatingUlasanService] Error batch update: $e');
    }
  }
}